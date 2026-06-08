import * as admin from 'firebase-admin';
import * as zlib from 'zlib';
import { promisify } from 'util';
import { generateAppleJWT, appleGet } from './appleJwt';

const APP_ID = '6766937646';
const VENDOR_NUMBER = '94298138';
const gunzip = promisify(zlib.gunzip);

// ── Rating desde Customer Reviews ────────────────────────────────────────────

async function fetchRating(token: string): Promise<{ rating: number; totalReviews: number }> {
  const url =
    `https://api.appstoreconnect.apple.com/v1/apps/${APP_ID}/customerReviews` +
    `?limit=200&sort=-createdDate&fields[customerReviews]=rating`;

  const res = await appleGet(url, token);
  if (!res.ok) {
    console.warn(`Customer Reviews API ${res.status}`);
    return { rating: 0, totalReviews: 0 };
  }

  const body = await res.json() as {
    data: Array<{ attributes: { rating: number } }>;
    meta?: { paging?: { total?: number } };
  };

  const reviews = body.data ?? [];
  const total = body.meta?.paging?.total ?? reviews.length;
  if (reviews.length === 0) return { rating: 0, totalReviews: total };
  const avg = reviews.reduce((sum, r) => sum + r.attributes.rating, 0) / reviews.length;
  return { rating: Math.round(avg * 10) / 10, totalReviews: total };
}

// ── Descargas (primeras) — suma últimos 12 meses de Sales Reports ─────────────

function monthStr(offset: number): string {
  const d = new Date();
  d.setDate(1);
  d.setMonth(d.getMonth() + offset);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
}

async function fetchMonthlyDownloads(token: string, reportDate: string): Promise<number> {
  const url =
    `https://api.appstoreconnect.apple.com/v1/salesReports` +
    `?filter[frequency]=MONTHLY&filter[reportDate]=${reportDate}` +
    `&filter[reportType]=SALES&filter[reportSubType]=SUMMARY` +
    `&filter[vendorNumber]=${VENDOR_NUMBER}`;

  const res = await appleGet(url, token);
  if (!res.ok) return 0;

  const buffer = Buffer.from(await res.arrayBuffer());
  let text: string;
  try { text = (await gunzip(buffer)).toString('utf-8'); }
  catch { text = buffer.toString('utf-8'); }

  let downloads = 0;
  for (const line of text.split('\n').slice(1)) {
    if (!line.trim()) continue;
    const cols = line.split('\t');
    const appleId = cols[14]?.trim();
    const productType = cols[6]?.trim();
    const units = parseInt(cols[7] ?? '0', 10);
    if (appleId === APP_ID && (productType === '1' || productType === '1F') && !isNaN(units)) {
      downloads += units;
    }
  }
  return downloads;
}

async function fetchTotalDownloads(token: string): Promise<number> {
  const months = Array.from({ length: 12 }, (_, i) => monthStr(-(i + 1)));
  const results = await Promise.allSettled(months.map(m => fetchMonthlyDownloads(token, m)));
  return results.reduce((sum, r) => sum + (r.status === 'fulfilled' ? r.value : 0), 0);
}

// ── Parser de TSV con detección de columnas por nombre ───────────────────────

async function parseTsv(buf: Buffer): Promise<{ impressions: number; pageViews: number; redownloads: number; appUnits: number }> {
  let text: string;
  try { text = (await gunzip(buf)).toString('utf-8'); }
  catch { text = buf.toString('utf-8'); }

  const lines = text.split('\n');
  if (lines.length < 2) return { impressions: 0, pageViews: 0, redownloads: 0, appUnits: 0 };

  const headers = lines[0].split('\t').map(h => h.trim().toLowerCase());
  console.log('TSV headers:', headers.join(' | '));

  const col = (kw: string) => headers.findIndex(h => h.includes(kw));

  const impIdx  = col('impression');
  const pvIdx   = col('page view') >= 0 ? col('page view') : col('pageview');
  const rdIdx   = col('redownload');
  const auIdx   = col('app unit') >= 0 ? col('app unit') : col('appunit');

  let impressions = 0, pageViews = 0, redownloads = 0, appUnits = 0;

  for (const line of lines.slice(1)) {
    if (!line.trim()) continue;
    const c = line.split('\t');
    const n = (idx: number) => (idx >= 0 ? parseInt(c[idx] ?? '0', 10) || 0 : 0);
    impressions += n(impIdx);
    pageViews   += n(pvIdx);
    redownloads += n(rdIdx);
    appUnits    += n(auIdx);
  }

  return { impressions, pageViews, redownloads, appUnits };
}

// ── Analytics desde Analytics Reports API (ONGOING — reutiliza requestId) ────

async function getOrCreateOngoingRequestId(db: admin.firestore.Firestore, token: string): Promise<string | null> {
  const configRef = db.collection('appstore_metrics').doc('config');
  const config = await configRef.get();
  const saved = config.data()?.analyticsRequestId as string | undefined;

  if (saved) {
    console.log(`Reusando analyticsRequestId: ${saved}`);
    return saved;
  }

  console.log('Creando nuevo ONGOING analytics request...');
  const createRes = await fetch(
    'https://api.appstoreconnect.apple.com/v1/analyticsReportRequests',
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        data: {
          type: 'analyticsReportRequests',
          attributes: { accessType: 'ONGOING', stoppedDueToPrivacy: false },
          relationships: { app: { data: { type: 'apps', id: APP_ID } } },
        },
      }),
    }
  );

  if (!createRes.ok) {
    console.warn(`Analytics create ${createRes.status}: ${await createRes.text()}`);
    return null;
  }

  const { data: { id } } = await createRes.json() as { data: { id: string } };
  console.log(`Nuevo requestId creado: ${id}`);
  await configRef.set({ analyticsRequestId: id }, { merge: true });
  return id;
}

async function fetchAnalytics(
  db: admin.firestore.Firestore,
  token: string
): Promise<{ impressions: number; redownloads: number; conversion: number }> {
  const requestId = await getOrCreateOngoingRequestId(db, token);
  if (!requestId) return { impressions: 0, redownloads: 0, conversion: 0 };

  // Tipos de reporte a buscar (en orden de prioridad)
  const reportTypes = ['APP_STORE_ENGAGEMENT', 'APP_STORE_ACQUISITION'];
  let reportId: string | null = null;

  // Espera hasta 180 s (18 × 10 s)
  for (let attempt = 0; attempt < 18 && !reportId; attempt++) {
    if (attempt > 0) await new Promise(r => setTimeout(r, 10000));

    for (const reportType of reportTypes) {
      const rRes = await appleGet(
        `https://api.appstoreconnect.apple.com/v1/analyticsReportRequests/${requestId}/reports` +
        `?filter[reportType]=${reportType}`,
        token
      );
      if (!rRes.ok) {
        console.warn(`Reports list ${reportType} → ${rRes.status}`);
        continue;
      }
      const { data } = await rRes.json() as {
        data: Array<{ id: string; attributes: { processingState: string; reportType: string } }>;
      };
      console.log(`Attempt ${attempt + 1} [${reportType}]: ${data.length} reports, states: ${data.map(r => r.attributes.processingState).join(', ')}`);
      const ready = data.find(r => r.attributes.processingState === 'COMPLETE');
      if (ready) {
        reportId = ready.id;
        console.log(`Report listo: ${reportId} (${reportType})`);
        break;
      }
    }
  }

  if (!reportId) {
    console.warn('Analytics report no disponible en 180 s — primer run puede tardar más');
    return { impressions: 0, redownloads: 0, conversion: 0 };
  }

  // Obtener instancias DAILY
  const instRes = await appleGet(
    `https://api.appstoreconnect.apple.com/v1/analyticsReports/${reportId}/instances?filter[granularity]=DAILY`,
    token
  );

  if (!instRes.ok) {
    console.warn(`Instances ${instRes.status}`);
    return { impressions: 0, redownloads: 0, conversion: 0 };
  }

  const { data: instances } = await instRes.json() as {
    data: Array<{ attributes: { downloadUrl: string; processingDate: string } }>;
  };
  console.log(`${instances.length} instancias encontradas`);

  let impressions = 0, pageViews = 0, redownloads = 0, appUnits = 0;

  for (const inst of instances) {
    const dlRes = await fetch(inst.attributes.downloadUrl, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!dlRes.ok) continue;
    const parsed = await parseTsv(Buffer.from(await dlRes.arrayBuffer()));
    impressions  += parsed.impressions;
    pageViews    += parsed.pageViews;
    redownloads  += parsed.redownloads;
    appUnits     += parsed.appUnits;
  }

  const conversion = impressions > 0 ? Math.round((pageViews / impressions) * 1000) / 10 : 0;
  console.log(`✅ Analytics: imp=${impressions} pv=${pageViews} rd=${redownloads} units=${appUnits} conv=${conversion}%`);
  return { impressions, redownloads, conversion };
}

// ── Orquestador principal ─────────────────────────────────────────────────────

export async function fetchAndStoreAppStoreMetrics(privateKey: string): Promise<void> {
  const db = admin.firestore();
  const token = generateAppleJWT(privateKey);

  const [ratingData, totalDownloads] = await Promise.all([
    fetchRating(token),
    fetchTotalDownloads(token),
  ]);

  await db.collection('appstore_metrics').doc('latest').set({
    rating: ratingData.rating,
    total_reviews: ratingData.totalReviews,
    downloads_last_month: totalDownloads,
    redownloads: 0,
    downloads_period_label: 'últimos 12 meses',
    impressions: null,
    conversion: null,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
    status: 'partial',
  }, { merge: false });

  console.log(`✅ Parcial: rating=${ratingData.rating} descargas=${totalDownloads}`);

  try {
    const analytics = await fetchAnalytics(db, token);
    await db.collection('appstore_metrics').doc('latest').update({
      impressions: analytics.impressions,
      redownloads: analytics.redownloads,
      conversion: analytics.conversion,
      status: 'complete',
    });
  } catch (err) {
    console.error('Analytics error:', err);
    await db.collection('appstore_metrics').doc('latest').update({ status: 'complete' });
  }
}
