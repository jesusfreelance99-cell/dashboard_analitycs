import * as admin from 'firebase-admin';
import * as jwt from 'jsonwebtoken';

// ─────────────────────────────────────────────────────────────────────────────
// FIRESTORE REF
// ─────────────────────────────────────────────────────────────────────────────

const playstoreDoc = () =>
  admin.firestore().collection('dashboard_metrics').doc('playstore');

// ─────────────────────────────────────────────────────────────────────────────
// GOOGLE OAUTH2 — Service Account JWT
// ─────────────────────────────────────────────────────────────────────────────

interface ServiceAccountKey {
  client_email: string;
  private_key: string;
}

async function getGoogleToken(
  clientEmail: string,
  privateKey: string,
  scopes: string[]
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const assertion = jwt.sign(
    {
      iss: clientEmail,
      scope: scopes.join(' '),
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    },
    privateKey,
    { algorithm: 'RS256' }
  );

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${assertion}`,
  });

  if (!res.ok) {
    throw new Error(`Google OAuth2 error ${res.status}: ${await res.text()}`);
  }

  const data = (await res.json()) as { access_token: string };
  return data.access_token;
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEWS — rating promedio (Android Publisher API)
// ─────────────────────────────────────────────────────────────────────────────

async function fetchRating(
  packageName: string,
  token: string
): Promise<{ rating: number; totalReviews: number }> {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications` +
    `/${packageName}/reviews?maxResults=100`;

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    console.warn(`Play reviews ${res.status}: ${await res.text()}`);
    return { rating: 0, totalReviews: 0 };
  }

  const body = (await res.json()) as {
    reviews?: Array<{ comments?: Array<{ userComment?: { starRating?: number } }> }>;
    pageInfo?: { totalResults?: number };
  };

  const reviews = body.reviews ?? [];
  const total = body.pageInfo?.totalResults ?? reviews.length;

  const stars = reviews
    .map((r) => r.comments?.[0]?.userComment?.starRating ?? 0)
    .filter((s) => s > 0);

  if (stars.length === 0) return { rating: 0, totalReviews: total };
  const avg = stars.reduce((s, r) => s + r, 0) / stars.length;
  return { rating: Math.round(avg * 10) / 10, totalReviews: total };
}

// ─────────────────────────────────────────────────────────────────────────────
// STORE PERFORMANCE — impresiones + instalaciones estimadas
// ─────────────────────────────────────────────────────────────────────────────

type MetricValue = {
  integerValue?: string;
  integer?: string;
  decimalValue?: { value?: string };
  decimal?: string;
  doubleValue?: number;
};

function parseInteger(m?: MetricValue): number {
  if (!m) return 0;
  return parseInt(m.integerValue ?? m.integer ?? '0', 10) || 0;
}

function parseDecimal(m?: MetricValue): number {
  if (!m) return 0;
  return (
    parseFloat(m.decimalValue?.value ?? m.decimal ?? String(m.doubleValue ?? 0)) || 0
  );
}

async function fetchStorePerformance(
  packageName: string,
  token: string
): Promise<{ visitors: number; conversionRate: number; estimatedInstalls: number }> {
  const url =
    `https://playdeveloperreporting.googleapis.com/v1beta1` +
    `/apps/${encodeURIComponent(packageName)}/storePerformanceMetricSet:query`;

  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      timeline: { aggregationPeriod: 'MONTHLY' },
      metrics: ['storeListingConversionRate', 'storeListingVisitors'],
      pageSize: 12,
    }),
  });

  if (!res.ok) {
    console.warn(`Store performance ${res.status}: ${await res.text()}`);
    return { visitors: 0, conversionRate: 0, estimatedInstalls: 0 };
  }

  const data = (await res.json()) as {
    rows?: Array<{ metrics?: Record<string, MetricValue> }>;
  };

  let totalVisitors = 0;
  let convSum = 0;
  let count = 0;

  for (const row of data.rows ?? []) {
    const m = row.metrics ?? {};
    totalVisitors += parseInteger(m['storeListingVisitors']);
    convSum += parseDecimal(m['storeListingConversionRate']);
    count++;
  }

  const avgConv = count > 0 ? convSum / count : 0;
  return {
    visitors: totalVisitors,
    conversionRate: avgConv,
    estimatedInstalls: Math.round(totalVisitors * avgConv),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// CRASH RATE — Play Developer Reporting API
// ─────────────────────────────────────────────────────────────────────────────

async function fetchCrashRate(
  packageName: string,
  token: string
): Promise<{ crashRate: number; affectedUsers: number }> {
  const url =
    `https://playdeveloperreporting.googleapis.com/v1beta1` +
    `/apps/${encodeURIComponent(packageName)}/crashRateMetricSet:query`;

  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      timeline: { aggregationPeriod: 'MONTHLY' },
      metrics: ['crashRate', 'distinctUsers'],
      pageSize: 5,
    }),
  });

  if (!res.ok) {
    console.warn(`Crash rate ${res.status}: ${await res.text()}`);
    return { crashRate: 0, affectedUsers: 0 };
  }

  const data = (await res.json()) as {
    rows?: Array<{ metrics?: Record<string, MetricValue> }>;
  };

  const rows = data.rows ?? [];
  if (rows.length === 0) return { crashRate: 0, affectedUsers: 0 };

  // Último mes disponible
  const latest = rows[rows.length - 1]?.metrics ?? {};
  const rawRate = parseDecimal(latest['crashRate']);
  const users = parseInteger(latest['distinctUsers']);

  return {
    crashRate: Math.round(rawRate * 10000) / 100, // 0.0012 → 0.12%
    affectedUsers: users,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// ANR RATE — Play Developer Reporting API
// ─────────────────────────────────────────────────────────────────────────────

async function fetchAnrRate(
  packageName: string,
  token: string
): Promise<number> {
  const url =
    `https://playdeveloperreporting.googleapis.com/v1beta1` +
    `/apps/${encodeURIComponent(packageName)}/anrRateMetricSet:query`;

  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      timeline: { aggregationPeriod: 'MONTHLY' },
      metrics: ['anrRate'],
      pageSize: 5,
    }),
  });

  if (!res.ok) {
    console.warn(`ANR rate ${res.status}: ${await res.text()}`);
    return 0;
  }

  const data = (await res.json()) as {
    rows?: Array<{ metrics?: Record<string, MetricValue> }>;
  };

  const rows = data.rows ?? [];
  if (rows.length === 0) return 0;

  const latest = rows[rows.length - 1]?.metrics ?? {};
  const raw = parseDecimal(latest['anrRate']);
  return Math.round(raw * 10000) / 100;
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPORTS
// ─────────────────────────────────────────────────────────────────────────────

export async function fetchAndStorePlayStoreMetrics(
  serviceAccountJson: string,
  packageName: string
): Promise<void> {
  const key = JSON.parse(serviceAccountJson) as ServiceAccountKey;

  const token = await getGoogleToken(key.client_email, key.private_key, [
    'https://www.googleapis.com/auth/androidpublisher',
    'https://www.googleapis.com/auth/playdeveloperreporting',
  ]);

  const [reviewResult, storeResult, crashResult, anrResult] =
    await Promise.allSettled([
      fetchRating(packageName, token),
      fetchStorePerformance(packageName, token),
      fetchCrashRate(packageName, token),
      fetchAnrRate(packageName, token),
    ]);

  const reviews =
    reviewResult.status === 'fulfilled'
      ? reviewResult.value
      : { rating: 0, totalReviews: 0 };

  const store =
    storeResult.status === 'fulfilled'
      ? storeResult.value
      : { visitors: 0, conversionRate: 0, estimatedInstalls: 0 };

  const crash =
    crashResult.status === 'fulfilled'
      ? crashResult.value
      : { crashRate: 0, affectedUsers: 0 };

  const anrRate =
    anrResult.status === 'fulfilled' ? anrResult.value : 0;

  const updatedAtLabel = new Date().toLocaleDateString('es-CO', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
    timeZone: 'America/Bogota',
  });

  await playstoreDoc().set(
    {
      status: 'ok',
      package_name: packageName,
      updated_at: admin.firestore.Timestamp.now(),
      updated_at_label: updatedAtLabel,
      rating: reviews.rating,
      total_reviews: reviews.totalReviews,
      store_visitors: store.visitors,
      conversion_rate: store.conversionRate,
      estimated_installs: store.estimatedInstalls,
      crash_rate: crash.crashRate,
      crash_affected_users: crash.affectedUsers,
      anr_rate: anrRate,
    },
    { merge: true }
  );

  console.log(
    `Play Store metrics saved: pkg=${packageName} rating=${reviews.rating} ` +
    `visitors=${store.visitors} crashes=${crash.crashRate}% ANR=${anrRate}%`
  );
}
