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

type ParsedTsv = {
  // Totales acumulados del TSV completo
  impressions: number;
  pageViews: number;
  redownloads: number;
  appUnits: number;
  // Desglose diario: Map<date, {imp, pv, rd, au}>
  byDate: Map<string, { impressions: number; pageViews: number; redownloads: number; appUnits: number }>;
  debugHeaders: string;
  debugPreview: string;
};

async function parseTsv(buf: Buffer): Promise<ParsedTsv> {
  const EMPTY: ParsedTsv = {
    impressions: 0, pageViews: 0, redownloads: 0, appUnits: 0,
    byDate: new Map(), debugHeaders: '', debugPreview: '',
  };

  let text: string;
  try { text = (await gunzip(buf)).toString('utf-8'); }
  catch { text = buf.toString('utf-8'); }

  const rawPreview = text.substring(0, 400).replace(/\n/g, '↵');
  const lines = text.split('\n').filter(l => l.trim());

  if (lines.length < 2 || !lines[0].includes('\t')) {
    console.warn('parseTsv: no es TSV válido. Preview:', rawPreview.substring(0, 200));
    return { ...EMPTY, debugPreview: `INVALID|${rawPreview}` };
  }

  const headers = lines[0].split('\t').map(h => h.trim());
  const hl = headers.map(h => h.toLowerCase());
  const headersStr = headers.join(' | ');
  console.log(`TSV headers: ${headersStr} (${lines.length - 1} filas)`);

  const ci  = (name: string) => hl.indexOf(name);
  const cip = (...kws: string[]) => hl.findIndex(h => kws.some(k => h.includes(k)));

  const dateIdx         = ci('date');
  const eventIdx        = ci('event');
  const downloadTypeIdx = hl.findIndex(h => h === 'download type');
  const countsIdx       = cip('counts');

  const getDay   = (c: string[]) => (dateIdx >= 0 ? (c[dateIdx]?.trim() ?? '') : '');
  const getCount = (c: string[]) => (countsIdx >= 0 ? parseFloat(c[countsIdx]?.trim() ?? '0') || 0 : 0);

  let impressions = 0, pageViews = 0, redownloads = 0, appUnits = 0;
  const byDate = new Map<string, { impressions: number; pageViews: number; redownloads: number; appUnits: number }>();
  const distinctEvents = new Set<string>();

  if (eventIdx >= 0 && countsIdx >= 0) {
    // ── Formato event-row: columna "Event" + "Counts" ──────────────────────────
    for (const line of lines.slice(1)) {
      const c = line.split('\t');
      const event = c[eventIdx]?.trim().toLowerCase() ?? '';
      const count = getCount(c);
      const date  = getDay(c);
      if (!date) continue;
      distinctEvents.add(c[eventIdx]?.trim() ?? '');

      const day = byDate.get(date) ?? { impressions: 0, pageViews: 0, redownloads: 0, appUnits: 0 };

      if (event === 'impression' || event === 'impressions') {
        impressions += count; day.impressions += count;
      } else if (event.startsWith('product page view') || event === 'page view' || event === 'page views') {
        pageViews += count; day.pageViews += count;
      } else if (event === 'app units' || event === 'app unit') {
        appUnits += count; day.appUnits += count;
      } else if (event.includes('re-download') || event.includes('redownload')) {
        redownloads += count; day.redownloads += count;
      }

      byDate.set(date, day);
    }
    console.log(`Event-row: imp=${impressions} pv=${pageViews} au=${appUnits} rd=${redownloads} events=[${[...distinctEvents].join(',')}]`);

  } else if (downloadTypeIdx >= 0 && countsIdx >= 0) {
    // ── Formato download-type-row: columna "Download Type" + "Counts" ──────────
    for (const line of lines.slice(1)) {
      const c = line.split('\t');
      const dlType = c[downloadTypeIdx]?.trim().toLowerCase() ?? '';
      const count  = getCount(c);
      const date   = getDay(c);
      if (!date || !dlType) continue;
      distinctEvents.add(c[downloadTypeIdx]?.trim() ?? '');

      const day = byDate.get(date) ?? { impressions: 0, pageViews: 0, redownloads: 0, appUnits: 0 };

      if (dlType.includes('first')) {
        // "First Time Download", "First-Time Download"
        appUnits += count; day.appUnits += count;
      } else if (dlType.includes('re')) {
        // "Re-Download", "Redownload"
        redownloads += count; day.redownloads += count;
      }

      byDate.set(date, day);
    }
    console.log(`DL-type-row: au=${appUnits} rd=${redownloads} types=[${[...distinctEvents].join(',')}]`);

  } else {
    // ── Formato columnar clásico (fallback) ────────────────────────────────────
    const impIdx = cip('impression');
    const pvIdx  = cip('page view', 'pageview', 'product page');
    const rdIdx  = cip('redownload');
    const auIdx  = cip('app units', 'app unit', 'appunit');
    console.log(`Columnar: imp:${impIdx} pv:${pvIdx} rd:${rdIdx} au:${auIdx}`);

    for (const line of lines.slice(1)) {
      const c = line.split('\t');
      const n = (idx: number) => idx >= 0 ? parseFloat(c[idx] ?? '0') || 0 : 0;
      const date = getDay(c);
      const imp = n(impIdx), pv = n(pvIdx), rd = n(rdIdx), au = n(auIdx);
      impressions += imp; pageViews += pv; redownloads += rd; appUnits += au;
      if (date) {
        const day = byDate.get(date) ?? { impressions: 0, pageViews: 0, redownloads: 0, appUnits: 0 };
        day.impressions += imp; day.pageViews += pv; day.redownloads += rd; day.appUnits += au;
        byDate.set(date, day);
      }
    }
  }

  const debugEvents = [...distinctEvents].slice(0, 20).join(' | ');
  return { impressions, pageViews, redownloads, appUnits, byDate, debugHeaders: headersStr, debugPreview: debugEvents };
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

type ReportInstance = {
  id: string;
  attributes: {
    processingDate: string;
    granularity?: string;
  };
};

async function getReportInstances(reportId: string, token: string, limit = 1): Promise<ReportInstance[]> {
  const res = await appleGet(
    `https://api.appstoreconnect.apple.com/v1/analyticsReports/${reportId}/instances` +
    `?filter[granularity]=DAILY&limit=${limit}`,
    token
  );
  if (!res.ok) return [];
  const body = await res.json() as { data: ReportInstance[] };
  return body.data ?? [];
}

// Apple Analytics Reports API: las URLs de descarga están en los SEGMENTOS de cada instancia,
// no en la instancia misma. Cada instancia puede tener 1+ segmentos.
async function getInstanceSegmentUrls(instanceId: string, token: string): Promise<string[]> {
  const res = await appleGet(
    `https://api.appstoreconnect.apple.com/v1/analyticsReportInstances/${instanceId}/segments`,
    token
  );
  if (!res.ok) {
    console.warn(`Segments ${instanceId} → ${res.status}`);
    return [];
  }
  const body = await res.json() as { data: Array<{ attributes: { url?: string } }> };
  return (body.data ?? []).map(s => s.attributes.url ?? '').filter(Boolean);
}

// Retorna los IDs de TODOS los reportes que ya tienen instancias DAILY generadas.
// Apple crea múltiples reportes por ONGOING request (uno por tipo de métrica).
async function getAllReportIdsWithInstances(requestId: string, token: string): Promise<string[]> {
  const rRes = await appleGet(
    `https://api.appstoreconnect.apple.com/v1/analyticsReportRequests/${requestId}/reports?limit=50`,
    token
  );
  if (!rRes.ok) {
    console.warn(`Reports list → ${rRes.status}`);
    return [];
  }

  const body = await rRes.json() as {
    data: Array<{ id: string; attributes: Record<string, unknown> }>;
  };

  if (!body.data || body.data.length === 0) {
    console.log(`Sin reportes todavía para request ${requestId} — Apple tarda 24-48h`);
    return [];
  }

  const reportIds: string[] = [];
  for (const r of body.data) {
    const name = String(r.attributes['name'] ?? r.attributes['reportType'] ?? r.id);
    const instances = await getReportInstances(r.id, token, 1);
    console.log(`REPORT "${name}" (${r.id}) → ${instances.length} instancias`);
    if (instances.length > 0) reportIds.push(r.id);
  }

  console.log(`✅ ${reportIds.length} de ${body.data.length} reportes tienen instancias`);
  return reportIds;
}

// Retorna datos vacíos si no hay datos disponibles todavía (no-fatal).
async function fetchAnalytics(
  token: string
): Promise<{
  impressions: number;
  pageViews: number;
  downloads: number;
  redownloads: number;
  conversion: number;
  timeSeries: DailyPoint[];
} | null> {
  const docRef = appstoreDocPath();
  const snap = await docRef.get();
  const savedId = snap.data()?.analyticsRequestId as string | undefined;

  // Asegurar que existe un ONGOING request en Apple
  const requestId = savedId ?? await getOrCreateOngoingRequest(token);
  if (!requestId) {
    console.warn('No se pudo obtener/crear ONGOING request');
    return null;
  }

  // Obtener TODOS los reportes con instancias (cada reporte cubre un tipo de métrica distinto)
  const reportIds = await getAllReportIdsWithInstances(requestId, token);
  if (reportIds.length === 0) {
    console.log('Sin datos disponibles aún — se reintentará mañana');
    return null;
  }

  // Acumulador global por fecha real (columna Date del TSV)
  const globalByDate = new Map<string, { impressions: number; pageViews: number; redownloads: number; appUnits: number }>();
  const debugHeaders: Record<string, string> = {};

  const mergeIntoGlobal = (byDate: Map<string, { impressions: number; pageViews: number; redownloads: number; appUnits: number }>) => {
    for (const [date, d] of byDate) {
      const ex = globalByDate.get(date) ?? { impressions: 0, pageViews: 0, redownloads: 0, appUnits: 0 };
      // Sumar por tipo de métrica (distintos reportes no se solapan por tipo de evento)
      ex.impressions += d.impressions;
      ex.pageViews   += d.pageViews;
      ex.redownloads += d.redownloads;
      ex.appUnits    += d.appUnits;
      globalByDate.set(date, ex);
    }
  };

  const CONCURRENCY = 5;
  for (const reportId of reportIds) {
    const instances = await getReportInstances(reportId, token, 200);
    console.log(`Reporte ${reportId}: ${instances.length} instancias`);

    for (let i = 0; i < instances.length; i += CONCURRENCY) {
      const batch = instances.slice(i, i + CONCURRENCY);
      const results = await Promise.allSettled(
        batch.map(async inst => {
          const processingDate = inst.attributes.processingDate;
          const segmentUrls = await getInstanceSegmentUrls(inst.id, token);
          if (segmentUrls.length === 0) return null;

          const instByDate = new Map<string, { impressions: number; pageViews: number; redownloads: number; appUnits: number }>();
          let hdrs = '';

          for (const url of segmentUrls) {
            const dlRes = await fetch(url); // pre-signed URL sin Authorization
            if (!dlRes.ok) {
              console.warn(`Download falló ${dlRes.status} instancia ${processingDate}`);
              continue;
            }
            const parsed = await parseTsv(Buffer.from(await dlRes.arrayBuffer()));
            if (!hdrs) hdrs = parsed.debugHeaders;
            for (const [date, d] of parsed.byDate) {
              const ex = instByDate.get(date) ?? { impressions: 0, pageViews: 0, redownloads: 0, appUnits: 0 };
              ex.impressions += d.impressions; ex.pageViews += d.pageViews;
              ex.redownloads += d.redownloads; ex.appUnits  += d.appUnits;
              instByDate.set(date, ex);
            }
          }
          return { instByDate, hdrs };
        })
      );

      for (const r of results) {
        if (r.status === 'fulfilled' && r.value) {
          const { instByDate, hdrs } = r.value;
          if (hdrs && !debugHeaders[reportId]) debugHeaders[reportId] = hdrs;
          mergeIntoGlobal(instByDate);
        }
      }
    }
  }

  // Guardar debug headers para inspección futura
  const allHeaders = Object.values(debugHeaders).join(' || ');
  await appstoreDocPath().update({
    tsv_debug_headers: allHeaders || '(vacío)',
  }).catch(() => undefined);

  // Construir totales y timeSeries desde el mapa global
  let impressions = 0, pageViews = 0, redownloads = 0, appUnits = 0;
  const timeSeries: DailyPoint[] = [];
  for (const [date, d] of globalByDate) {
    impressions += d.impressions;
    pageViews   += d.pageViews;
    redownloads += d.redownloads;
    appUnits    += d.appUnits;
    timeSeries.push({ date, downloads: d.appUnits, impressions: d.impressions, redownloads: d.redownloads });
  }

  timeSeries.sort((a, b) => a.date.localeCompare(b.date));

  const conversion = impressions > 0
    ? Math.round((pageViews / impressions) * 1000) / 10
    : 0;

  console.log(`✅ Analytics: imp=${impressions} pv=${pageViews} dl=${appUnits} rd=${redownloads} conv=${conversion}% ts=${timeSeries.length}d`);
  return { impressions, pageViews, downloads: appUnits, redownloads, conversion, timeSeries };
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
    page_views: null,
    conversion: null,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
    status: 'partial',
  }, { merge: true });

  console.log(`✅ Parcial guardado: rating=${ratingData.rating} descargas=${totalDownloads}`);

  try {
    const analytics = await fetchAnalytics(token);
    if (analytics === null) {
      // Apple aún no generó instancias (tarda 24-48h tras crear el ONGOING request)
      await docRef.update({
        status: 'partial',
        analytics_pending: 'Apple está procesando los reportes de Analytics. Los datos estarán disponibles en ~24h.',
        analytics_error: admin.firestore.FieldValue.delete(),
        analytics_error_at: admin.firestore.FieldValue.delete(),
      });
      console.log('⏳ Analytics pendientes — Apple aún no generó instancias');
    } else {
      await docRef.update({
        impressions: analytics.impressions,
        page_views: analytics.pageViews,
        first_downloads: analytics.downloads,
        redownloads: analytics.redownloads,
        conversion: analytics.conversion,
        time_series: analytics.timeSeries,
        analytics_pending: admin.firestore.FieldValue.delete(),
        analytics_error: admin.firestore.FieldValue.delete(),
        analytics_error_at: admin.firestore.FieldValue.delete(),
        status: 'complete',
      });
      console.log('✅ Métricas completas guardadas en dashboard_metrics/appstore');
    }
  } catch (err) {
    console.error('Analytics error:', err);
    await docRef.update({
      status: 'partial',
      analytics_error: String(err),
      analytics_error_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}
