import * as admin from 'firebase-admin';
import * as zlib from 'zlib';
import { promisify } from 'util';
import { generateAppleJWT, appleGet } from './appleJwt';

const APP_ID = '6766937646';
const VENDOR_NUMBER = '94298138';
const gunzip = promisify(zlib.gunzip);

// Referencia única al documento de App Store en dashboard_metrics
const appstoreDocPath = () =>
  admin.firestore().collection('dashboard_metrics').doc('appstore');

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

// ── Descargas totales — suma últimos 12 meses de Sales Reports ────────────────

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
  // Suma los 12 meses: mes actual (i=0) + 11 meses anteriores
  const months = Array.from({ length: 12 }, (_, i) => monthStr(-i));
  const results = await Promise.allSettled(months.map(m => fetchMonthlyDownloads(token, m)));
  const total = results.reduce((sum, r) => sum + (r.status === 'fulfilled' ? r.value : 0), 0);
  console.log(`📦 Descargas (Sales Reports, 12 meses): ${total}`);
  return total;
}

// ── Parser de TSV con detección de columnas por nombre ───────────────────────

async function parseTsv(
  buf: Buffer
): Promise<{ impressions: number; pageViews: number; redownloads: number; appUnits: number }> {
  let text: string;
  try { text = (await gunzip(buf)).toString('utf-8'); }
  catch { text = buf.toString('utf-8'); }

  const lines = text.split('\n').filter(l => l.trim());
  if (lines.length < 2) return { impressions: 0, pageViews: 0, redownloads: 0, appUnits: 0 };

  const headerLine = lines[0];

  // Valida que sea realmente un TSV (tiene tabs)
  if (!headerLine.includes('\t')) {
    console.warn('parseTsv: respuesta no es TSV. Primeros 200 chars:', headerLine.substring(0, 200));
    return { impressions: 0, pageViews: 0, redownloads: 0, appUnits: 0 };
  }

  const headers = headerLine.split('\t').map(h => h.trim().toLowerCase());
  console.log('TSV headers:', headers.join(' | '));

  const col = (kw: string) => headers.findIndex(h => h.includes(kw));

  const impIdx = col('impression');
  const pvIdx = col('page view') >= 0 ? col('page view') : col('pageview');
  const rdIdx = col('redownload');
  const auIdx = col('app unit') >= 0 ? col('app unit') : col('appunit');

  console.log(`Column indices → imp:${impIdx} pv:${pvIdx} rd:${rdIdx} au:${auIdx}`);

  let impressions = 0, pageViews = 0, redownloads = 0, appUnits = 0;

  for (const line of lines.slice(1)) {
    const c = line.split('\t');
    const n = (idx: number) => (idx >= 0 ? parseFloat(c[idx] ?? '0') || 0 : 0);
    impressions += n(impIdx);
    pageViews += n(pvIdx);
    redownloads += n(rdIdx);
    appUnits += n(auIdx);
  }

  return { impressions, pageViews, redownloads, appUnits };
}

// ── Tipos ─────────────────────────────────────────────────────────────────────

type DailyPoint = {
  date: string;       // "YYYY-MM-DD"
  downloads: number;
  impressions: number;
  redownloads: number;
};

// ── Analytics desde Analytics Reports API (ONGOING — reutiliza requestId) ────
// analyticsRequestId se guarda en el mismo documento dashboard_metrics/appstore

async function getOrCreateOngoingRequest(token: string): Promise<string | null> {
  // 1. Listar requests existentes a través del endpoint del app (forma correcta en Apple API)
  const listRes = await appleGet(
    `https://api.appstoreconnect.apple.com/v1/apps/${APP_ID}/analyticsReportRequests` +
    `?limit=10`,
    token
  );

  if (listRes.ok) {
    const { data } = await listRes.json() as {
      data: Array<{ id: string; attributes: { accessType: string } }>;
    };
    const existing = data.find(r => r.attributes.accessType === 'ONGOING');
    if (existing) {
      console.log(`Recuperado ONGOING request existente de Apple: ${existing.id}`);
      await appstoreDocPath().set(
        { analyticsRequestId: existing.id, analytics_error: admin.firestore.FieldValue.delete() },
        { merge: true }
      );
      return existing.id;
    }
  } else {
    console.warn(`List requests ${listRes.status}: ${await listRes.text()}`);
  }

  // 2. No existe ninguno → crear uno nuevo
  console.log('Creando nuevo ONGOING analytics request...');
  const createRes = await fetch(
    'https://api.appstoreconnect.apple.com/v1/analyticsReportRequests',
    {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        data: {
          type: 'analyticsReportRequests',
          attributes: { accessType: 'ONGOING' },
          relationships: { app: { data: { type: 'apps', id: APP_ID } } },
        },
      }),
    }
  );

  if (!createRes.ok) {
    const errBody = await createRes.text();
    console.warn(`Analytics create ${createRes.status}: ${errBody}`);
    await appstoreDocPath().set(
      { analytics_error: `HTTP ${createRes.status}: ${errBody}`, analytics_error_at: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
    return null;
  }

  const { data: { id } } = await createRes.json() as { data: { id: string } };
  console.log(`Nuevo requestId creado: ${id}`);
  await appstoreDocPath().set(
    { analyticsRequestId: id, analytics_error: admin.firestore.FieldValue.delete() },
    { merge: true }
  );
  return id;
}

async function getReportInstanceCount(reportId: string, token: string): Promise<number> {
  const res = await appleGet(
    `https://api.appstoreconnect.apple.com/v1/analyticsReports/${reportId}/instances` +
    `?filter[granularity]=DAILY&limit=1`,
    token
  );
  if (!res.ok) return 0;
  const body = await res.json() as { data: unknown[] };
  return body.data?.length ?? 0;
}

async function findAcquisitionReportId(requestId: string, token: string): Promise<string | null> {
  const rRes = await appleGet(
    `https://api.appstoreconnect.apple.com/v1/analyticsReportRequests/${requestId}/reports?limit=50`,
    token
  );

  if (!rRes.ok) {
    console.warn(`Reports list → ${rRes.status}: ${await rRes.text()}`);
    return null;
  }

  const body = await rRes.json() as {
    data: Array<{ id: string; attributes: Record<string, unknown> }>;
  };

  if (!body.data || body.data.length === 0) {
    console.log(`Sin reportes para request ${requestId}`);
    return null;
  }

  // Loguear cada reporte en línea propia para no truncar
  for (const r of body.data) {
    const name = String(r.attributes['name'] ?? r.attributes['reportType'] ?? '?');
    const cat  = String(r.attributes['category'] ?? '?');
    console.log(`REPORT id=${r.id} name="${name}" category="${cat}"`);
  }

  // 1. Buscar por nombre o categoría que contenga "acquisition"
  const byName = body.data.find(r => {
    const name = String(r.attributes['name'] ?? r.attributes['reportType'] ?? '').toLowerCase();
    const cat  = String(r.attributes['category'] ?? '').toLowerCase();
    return name.includes('acquisition') || cat.includes('acquisition');
  });

  if (byName) {
    console.log(`✅ Adquisición por nombre/categoría: ${byName.id}`);
    return byName.id;
  }

  // 2. Fallback: primer reporte que tenga instancias DAILY disponibles
  console.log('Sin match por nombre — buscando reporte con instancias DAILY...');
  for (const r of body.data) {
    const count = await getReportInstanceCount(r.id, token);
    const name  = String(r.attributes['name'] ?? r.id);
    console.log(`  "${name}" → ${count} instancias`);
    if (count > 0) {
      console.log(`✅ Usando reporte con instancias: "${name}" (${r.id})`);
      return r.id;
    }
  }

  console.warn('Ningún reporte tiene instancias DAILY disponibles.');
  return null;
}

async function fetchAnalytics(
  token: string
): Promise<{ impressions: number; redownloads: number; conversion: number; timeSeries: DailyPoint[] }> {
  const empty = { impressions: 0, redownloads: 0, conversion: 0, timeSeries: [] };
  const docRef = appstoreDocPath();
  const snap = await docRef.get();
  const savedId = snap.data()?.analyticsRequestId as string | undefined;

  let reportId: string | null = null;

  if (savedId) {
    // ── Caso A: tenemos un ID guardado — consultar sin esperar demasiado ──
    console.log(`Reusando analyticsRequestId: ${savedId}`);
    reportId = await findAcquisitionReportId(savedId, token);

    if (!reportId) {
      console.warn(`ID ${savedId} sin reportes. Verificando en Apple...`);
      await docRef.update({ analyticsRequestId: admin.firestore.FieldValue.delete() });

      const newId = await getOrCreateOngoingRequest(token);
      if (!newId) return empty;

      reportId = await findAcquisitionReportId(newId, token);
      if (!reportId) {
        console.warn('Reportes aún no disponibles. Se reintentan en el próximo ciclo.');
        return empty;
      }
    }
  } else {
    // ── Caso B: sin ID guardado — recuperar de Apple o crear nuevo ─────────
    const newId = await getOrCreateOngoingRequest(token);
    if (!newId) return empty;

    reportId = await findAcquisitionReportId(newId, token);
    if (!reportId) {
      console.warn('Request listo. Reportes disponibles en ~24h.');
      return empty;
    }
  }

  // Obtener instancias DAILY (paginadas, máx 200)
  const instRes = await appleGet(
    `https://api.appstoreconnect.apple.com/v1/analyticsReports/${reportId}/instances` +
    `?filter[granularity]=DAILY&limit=200`,
    token
  );

  if (!instRes.ok) {
    console.warn(`Instances ${instRes.status}: ${await instRes.text()}`);
    return { impressions: 0, redownloads: 0, conversion: 0, timeSeries: [] };
  }

  const { data: instances } = await instRes.json() as {
    data: Array<{ id: string; attributes: { downloadUrl: string; processingDate: string } }>;
  };
  console.log(`${instances.length} instancias encontradas`);

  if (instances.length === 0) {
    console.warn('Sin instancias disponibles para este reporte');
    return { impressions: 0, redownloads: 0, conversion: 0, timeSeries: [] };
  }

  // Descarga en paralelo (máx 10 concurrentes) — preserva datos por día
  const CONCURRENCY = 10;
  let impressions = 0, pageViews = 0, redownloads = 0, appUnits = 0;
  const timeSeries: DailyPoint[] = [];

  for (let i = 0; i < instances.length; i += CONCURRENCY) {
    const batch = instances.slice(i, i + CONCURRENCY);
    const results = await Promise.allSettled(
      batch.map(async inst => {
        const date = inst.attributes.processingDate; // "YYYY-MM-DD"
        const dlRes = await fetch(inst.attributes.downloadUrl, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (!dlRes.ok) {
          console.warn(`Download falló ${dlRes.status} para instancia ${date}`);
          return null;
        }
        const parsed = await parseTsv(Buffer.from(await dlRes.arrayBuffer()));
        return { date, ...parsed };
      })
    );

    for (const r of results) {
      if (r.status === 'fulfilled' && r.value) {
        const { date, impressions: imp, pageViews: pv, redownloads: rd, appUnits: au } = r.value;
        impressions += imp;
        pageViews += pv;
        redownloads += rd;
        appUnits += au;
        if (date) {
          timeSeries.push({ date, downloads: au, impressions: imp, redownloads: rd });
        }
      }
    }
  }

  // Ordenar cronológicamente (ascendente)
  timeSeries.sort((a, b) => a.date.localeCompare(b.date));

  const conversion = impressions > 0
    ? Math.round((pageViews / impressions) * 1000) / 10
    : 0;

  console.log(`✅ Analytics totales: imp=${impressions} pv=${pageViews} rd=${redownloads} units=${appUnits} conv=${conversion}% timeSeries=${timeSeries.length} días`);
  return { impressions, redownloads, conversion, timeSeries };
}

// ── Orquestador principal ─────────────────────────────────────────────────────

export async function fetchAndStoreAppStoreMetrics(privateKey: string): Promise<void> {
  const docRef = appstoreDocPath();
  const token = generateAppleJWT(privateKey);

  const [ratingData, totalDownloads] = await Promise.all([
    fetchRating(token),
    fetchTotalDownloads(token),
  ]);

  // merge: true para preservar analyticsRequestId que está en el mismo documento
  await docRef.set({
    rating: ratingData.rating,
    total_reviews: ratingData.totalReviews,
    downloads_last_month: totalDownloads,
    redownloads: 0,
    downloads_period_label: 'últimos 12 meses',
    impressions: null,
    conversion: null,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
    status: 'partial',
  }, { merge: true });

  console.log(`✅ Parcial guardado: rating=${ratingData.rating} descargas=${totalDownloads}`);

  try {
    const analytics = await fetchAnalytics(token);
    await docRef.update({
      impressions: analytics.impressions,
      redownloads: analytics.redownloads,
      conversion: analytics.conversion,
      time_series: analytics.timeSeries,
      status: 'complete',
    });
    console.log('✅ Métricas completas guardadas en dashboard_metrics/appstore');
  } catch (err) {
    console.error('Analytics error:', err);
    await docRef.update({ status: 'complete' });
  }
}
