import * as admin from 'firebase-admin';

type QueryValue = string | number | boolean | undefined;

type DateRangeKey = 'd7' | 'd30' | 'd90' | 'all';

type DateRangeConfig = {
  key: DateRangeKey;
  startDate?: string;
  endDate: string;
  periodLabel: string;
};

type RevenueCatListResponse = {
  items?: unknown[];
};

function formatDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function daysAgo(days: number): string {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() - days);
  return formatDate(date);
}

function buildQuery(params: Record<string, QueryValue>): string {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined) continue;
    query.set(key, String(value));
  }
  const suffix = query.toString();
  return suffix ? `?${suffix}` : '';
}

async function revenueCatGet<T>(
  apiKey: string,
  path: string,
  params: Record<string, QueryValue> = {},
): Promise<T> {
  const response = await fetch(
    `https://api.revenuecat.com/v2${path}${buildQuery(params)}`,
    {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        Accept: 'application/json',
      },
    },
  );

  if (!response.ok) {
    throw new Error(`RevenueCat ${response.status}: ${await response.text()}`);
  }

  return response.json() as Promise<T>;
}

function pickNumber(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

function pickString(value: unknown): string | null {
  return typeof value === 'string' && value.trim().length > 0 ? value : null;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === 'object' ? (value as Record<string, unknown>) : null;
}

function pickMetricValue(metrics: Array<Record<string, unknown>>, id: string): number {
  const metric = metrics.find((item) => item.id === id);
  return pickNumber(metric?.value);
}

function resolveArray(payload: Record<string, unknown>): unknown[] {
  // RevenueCat can nest the array under 'values', 'data', or 'items'
  if (Array.isArray(payload.values)) return payload.values;
  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.items)) return payload.items;
  return [];
}

function extractChartValues(payload: Record<string, unknown>): number[] {
  return resolveArray(payload)
    .map((entry) => {
      if (typeof entry === 'number') return entry;
      const record = asRecord(entry);
      if (!record) return 0;
      if (typeof record.value === 'number') return record.value;
      if (typeof record.y === 'number') return record.y;
      if (typeof record.revenue === 'number') return record.revenue;
      return 0;
    })
    .filter((value) => Number.isFinite(value));
}

type RevenuePoint = { date: string; revenue: number };

function extractRevenueTimeSeries(payload: Record<string, unknown>): RevenuePoint[] {
  const entries = resolveArray(payload);
  const result: RevenuePoint[] = [];

  console.log(`extractRevenueTimeSeries: found ${entries.length} entries in payload`);

  for (const entry of entries) {
    const record = asRecord(entry);
    if (!record) continue;

    const revenue =
      typeof record.value === 'number' ? record.value
      : typeof record.y === 'number' ? record.y
      : typeof record.revenue === 'number' ? record.revenue
      : 0;

    // RevenueCat v2 charts pueden usar 'period', 'date', 'x', o 't' para la fecha
    const date =
      typeof record.period === 'string' ? record.period.slice(0, 10)
      : typeof record.date === 'string' ? record.date.slice(0, 10)
      : typeof record.x === 'string' ? record.x.slice(0, 10)
      : typeof record.t === 'string' ? record.t.slice(0, 10)
      : '';

    if (date && Number.isFinite(revenue)) {
      result.push({ date, revenue });
    }
  }

  // Fallback: si la API no devolvió puntos pero hay un total en summary, devolvemos un punto sintético
  if (result.length === 0) {
    const summary = asRecord(payload.summary);
    if (summary) {
      const total = pickNumber(summary.total) || pickNumber(summary.revenue);
      if (total > 0) {
        result.push({ date: formatDate(new Date()), revenue: total });
      }
    }
  }

  return result;
}

function latestChartValue(payload: Record<string, unknown>): number {
  const values = extractChartValues(payload);
  if (values.length > 0) return values[values.length - 1] ?? 0;

  const summary = asRecord(payload.summary);
  if (!summary) return 0;
  return pickNumber(summary.total) || pickNumber(summary.average);
}

function normalizeBars(values: number[], targetLength = 5): number[] {
  if (values.length === 0) return [42, 68, 88, 124, 98];

  const chunkSize = Math.ceil(values.length / targetLength);
  const buckets: number[] = [];

  for (let i = 0; i < values.length; i += chunkSize) {
    const slice = values.slice(i, i + chunkSize);
    const avg = slice.reduce((sum, value) => sum + value, 0) / slice.length;
    buckets.push(avg);
  }

  while (buckets.length < targetLength) {
    buckets.push(buckets.length === 0 ? 0 : buckets[buckets.length - 1] ?? 0);
  }

  const limited = buckets.slice(0, targetLength);
  const maxValue = limited.reduce((max, value) => (value > max ? value : max), 0);
  if (maxValue <= 0) return [42, 68, 88, 124, 98];

  return limited.map((value) => Number((28 + (value / maxValue) * 150).toFixed(1)));
}

function mapCatalogProducts(items: unknown[], path: 'product' | 'package.product') {
  return items
    .map((entry) => {
      const entryRecord = asRecord(entry);
      if (!entryRecord) return null;

      const productRecord =
        path === 'product'
          ? asRecord(entryRecord.product)
          : asRecord(asRecord(entryRecord.package)?.product);

      if (!productRecord) return null;

      return {
        id: productRecord.id ?? null,
        store_identifier: productRecord.store_identifier ?? null,
        display_name: productRecord.display_name ?? null,
      };
    })
    .filter(Boolean);
}

async function fetchCatalogSnapshot(
  apiKey: string,
  projectId: string,
): Promise<{
  entitlements: Array<Record<string, unknown>>;
  offerings: Array<Record<string, unknown>>;
  allStartDate: string | null;
}> {
  const [entitlementsResponse, offeringsResponse] = await Promise.all([
    revenueCatGet<RevenueCatListResponse>(
      apiKey,
      `/projects/${projectId}/entitlements`,
      { limit: 100, expand: 'items.product' },
    ),
    revenueCatGet<RevenueCatListResponse>(
      apiKey,
      `/projects/${projectId}/offerings`,
      { limit: 100, expand: 'items.package.product' },
    ),
  ]);

  const createdDates: string[] = [];

  const entitlements = (entitlementsResponse.items ?? [])
    .map((item) => {
      const record = asRecord(item);
      if (!record) return null;

      const createdAt =
        pickString(record.created_at) ?? pickString(record.created_at_iso8601);
      if (createdAt) createdDates.push(createdAt);

      const products = mapCatalogProducts(
        Array.isArray(record.items) ? record.items : [],
        'product',
      );

      return {
        id: record.id ?? null,
        lookup_key: record.lookup_key ?? null,
        display_name: record.display_name ?? null,
        products,
      };
    })
    .filter(Boolean) as Array<Record<string, unknown>>;

  const offerings = (offeringsResponse.items ?? [])
    .map((item) => {
      const record = asRecord(item);
      if (!record) return null;

      const createdAt =
        pickString(record.created_at) ?? pickString(record.created_at_iso8601);
      if (createdAt) createdDates.push(createdAt);

      const packages = (Array.isArray(record.items) ? record.items : [])
        .map((entry) => {
          const entryRecord = asRecord(entry);
          const packageRecord = asRecord(entryRecord?.package);
          if (!packageRecord) return null;

          const productRecord = asRecord(packageRecord.product);

          return {
            id: packageRecord.id ?? null,
            lookup_key: packageRecord.lookup_key ?? null,
            display_name: packageRecord.display_name ?? null,
            product: productRecord
              ? {
                  id: productRecord.id ?? null,
                  store_identifier: productRecord.store_identifier ?? null,
                  display_name: productRecord.display_name ?? null,
                }
              : null,
          };
        })
        .filter(Boolean);

      return {
        id: record.id ?? null,
        lookup_key: record.lookup_key ?? null,
        display_name: record.display_name ?? null,
        packages,
      };
    })
    .filter(Boolean) as Array<Record<string, unknown>>;

  createdDates.sort();
  const allStartDate =
    createdDates.length > 0 ? formatDate(new Date(createdDates[0])) : null;

  return {
    entitlements,
    offerings,
    allStartDate,
  };
}

async function fetchOverviewMetrics(
  apiKey: string,
  projectId: string,
): Promise<Record<string, unknown>> {
  const payload = await revenueCatGet<Record<string, unknown>>(
    apiKey,
    `/projects/${projectId}/metrics/overview`,
    { currency: 'USD', environment: 'production' },
  );

  const metrics = Array.isArray(payload.metrics)
    ? (payload.metrics as Array<Record<string, unknown>>)
    : [];

  const lastUpdatedMetric = metrics.find(
    (metric) => metric.last_updated_at_iso8601 != null,
  );

  return {
    active_trials: pickMetricValue(metrics, 'active_trials'),
    active_subscriptions:
      pickMetricValue(metrics, 'active_subscriptions') ||
      pickMetricValue(metrics, 'active_subscribers'),
    mrr: pickMetricValue(metrics, 'mrr'),
    revenue_28d: pickMetricValue(metrics, 'revenue'),
    new_customers_28d: pickMetricValue(metrics, 'new_customers'),
    active_customers_28d: pickMetricValue(metrics, 'active_users'),
    last_updated_at: lastUpdatedMetric?.last_updated_at_iso8601 ?? null,
  };
}

async function fetchRangeMetrics(
  apiKey: string,
  projectId: string,
  range: DateRangeConfig,
): Promise<Record<string, unknown>> {
  const [mrr, actives, trials, churn, revenueMetric, revenueChart] =
    await Promise.all([
      revenueCatGet<Record<string, unknown>>(
        apiKey,
        `/projects/${projectId}/charts/mrr`,
        {
          currency: 'USD',
          environment: 'production',
          start_date: range.startDate,
          end_date: range.endDate,
        },
      ),
      revenueCatGet<Record<string, unknown>>(
        apiKey,
        `/projects/${projectId}/charts/actives`,
        {
          environment: 'production',
          start_date: range.startDate,
          end_date: range.endDate,
        },
      ),
      revenueCatGet<Record<string, unknown>>(
        apiKey,
        `/projects/${projectId}/charts/trials`,
        {
          environment: 'production',
          start_date: range.startDate,
          end_date: range.endDate,
        },
      ),
      revenueCatGet<Record<string, unknown>>(
        apiKey,
        `/projects/${projectId}/charts/churn`,
        {
          environment: 'production',
          start_date: range.startDate,
          end_date: range.endDate,
        },
      ),
      revenueCatGet<Record<string, unknown>>(
        apiKey,
        `/projects/${projectId}/metrics/revenue`,
        {
          currency: 'USD',
          environment: 'production',
          start_date: range.startDate,
          end_date: range.endDate,
        },
      ),
      revenueCatGet<Record<string, unknown>>(
        apiKey,
        `/projects/${projectId}/charts/revenue`,
        {
          currency: 'USD',
          environment: 'production',
          start_date: range.startDate,
          end_date: range.endDate,
        },
      ),
    ]);

  const revenueTimeSeries = extractRevenueTimeSeries(revenueChart);

  return {
    mrr: latestChartValue(mrr),
    revenue: pickNumber(revenueMetric.value),
    active_subscriptions: Math.round(latestChartValue(actives)),
    active_trials: Math.round(latestChartValue(trials)),
    churn: latestChartValue(churn),
    new_customers: 0,
    active_customers: 0,
    revenue_bars: normalizeBars(extractChartValues(revenueChart)),
    revenue_time_series: revenueTimeSeries,
    period_label: range.periodLabel,
    start_date: range.startDate ?? null,
    end_date: range.endDate,
  };
}

export async function fetchAndStoreRevenueCatMetrics(
  apiKey: string,
  projectId: string,
): Promise<void> {
  const db = admin.firestore();
  const docRef = db.collection('dashboard_metrics').doc('revenuecat');
  const endDate = daysAgo(1);

  await docRef.set(
    {
      source: 'RevenueCat',
      currency: 'USD',
      status: 'partial',
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  let overview: Record<string, unknown>;
  try {
    overview = await fetchOverviewMetrics(apiKey, projectId);
  } catch (err) {
    console.error('RevenueCat overview error:', err);
    await docRef.set(
      { status: 'error', error: String(err), updated_at: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    return;
  }

  // Overview completo: limpiamos cualquier error previo y marcamos 'complete'
  await docRef.set(
    {
      source: 'RevenueCat',
      project_id: projectId,
      currency: 'USD',
      status: 'complete',
      error: admin.firestore.FieldValue.delete(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at_label: endDate,
      overview,
    },
    { merge: true },
  );
  console.log('✅ Overview guardado');

  // Ranges y catálogo son best-effort — se buscan de forma secuencial
  // para no superar el rate limit de RevenueCat (429)
  try {
    const catalog = await fetchCatalogSnapshot(apiKey, projectId);

    const ranges: DateRangeConfig[] = [
      { key: 'd7',  startDate: daysAgo(7),  endDate, periodLabel: 'últimos 7 días' },
      { key: 'd30', startDate: daysAgo(30), endDate, periodLabel: 'últimos 30 días' },
      { key: 'd90', startDate: daysAgo(90), endDate, periodLabel: 'últimos 90 días' },
      { key: 'all', startDate: catalog.allStartDate ?? undefined, endDate, periodLabel: 'todo el tiempo' },
    ];

    // Secuencial con 1.5 s de pausa entre rangos para evitar 429
    const rangeEntries: [string, Record<string, unknown>][] = [];
    for (const range of ranges) {
      if (rangeEntries.length > 0) await new Promise(r => setTimeout(r, 1500));
      const metrics = await fetchRangeMetrics(apiKey, projectId, range);
      rangeEntries.push([range.key, metrics]);
      console.log(`Range ${range.key} OK`);
    }

    await docRef.set(
      {
        ranges_error: admin.firestore.FieldValue.delete(),
        ranges: Object.fromEntries(rangeEntries),
        catalog: {
          entitlements: catalog.entitlements,
          offerings: catalog.offerings,
        },
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    console.log('✅ Ranges y catálogo guardados');
  } catch (error) {
    // Guardamos el error pero mantenemos status 'complete' — el overview ya está
    console.error('RevenueCat ranges/catalog error (non-fatal):', error);
    await docRef.set(
      { ranges_error: String(error), updated_at: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
  }
}
