import * as admin from 'firebase-admin';
import * as jwt from 'jsonwebtoken';

const GA4_SCOPE = 'https://www.googleapis.com/auth/analytics.readonly';
const GA4_API   = 'https://analyticsdata.googleapis.com/v1beta';

async function getToken(clientEmail: string, privateKey: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const signed = (jwt as any).sign(
    {
      iss: clientEmail, sub: clientEmail,
      aud: 'https://oauth2.googleapis.com/token',
      iat: now, exp: now + 3600,
      scope: GA4_SCOPE,
    },
    privateKey,
    { algorithm: 'RS256' },
  );
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: signed,
    }),
  });
  const data = await res.json() as any;
  if (!data.access_token) throw new Error(`GA4 token error: ${JSON.stringify(data)}`);
  return data.access_token;
}

async function ga4Post<T>(propertyId: string, token: string, path: string, body: unknown): Promise<T> {
  const res = await fetch(`${GA4_API}/properties/${propertyId}${path}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`GA4 ${path} ${res.status}: ${err}`);
  }
  return res.json() as Promise<T>;
}

// ─── NEW VS RETURNING ────────────────────────────────────────────────────────

async function fetchNewVsReturning(
  propertyId: string,
  token: string,
): Promise<{ date: string; new_users: number; returning_users: number }[]> {
  const body = await ga4Post<any>(propertyId, token, ':runReport', {
    dateRanges: [{ startDate: '90daysAgo', endDate: 'yesterday' }],
    dimensions: [{ name: 'date' }, { name: 'newVsReturning' }],
    metrics:    [{ name: 'totalUsers' }],
    orderBys:   [{ dimension: { dimensionName: 'date' } }],
    limit: 500,
  });

  const map: Record<string, { new_users: number; returning_users: number }> = {};
  for (const row of (body.rows ?? []) as any[]) {
    const date   = (row.dimensionValues?.[0]?.value ?? '') as string;
    const kind   = (row.dimensionValues?.[1]?.value ?? '') as string;
    const count  = parseInt((row.metricValues?.[0]?.value ?? '0') as string, 10);
    if (!map[date]) map[date] = { new_users: 0, returning_users: 0 };
    if (kind === 'new') {
      map[date].new_users += count;
    } else {
      map[date].returning_users += count;
    }
  }

  return Object.entries(map)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, v]) => ({ date, ...v }));
}

// ─── COHORT RETENTION CURVE ──────────────────────────────────────────────────
// Uses GA4 cohort API to get D0–D30 average retention across all cohorts
// from the last 90 days.

async function fetchRetentionCurve(
  propertyId: string,
  token: string,
): Promise<{ day: number; rate: number }[]> {
  const body = await ga4Post<any>(propertyId, token, ':runReport', {
    cohortSpec: {
      cohorts: [{
        name: 'allCohorts',
        dimension: 'firstSessionDate',
        dateRange: { startDate: '90daysAgo', endDate: '31daysAgo' },
      }],
      cohortsRange: {
        granularity: 'DAILY',
        startOffset: 0,
        endOffset: 30,
      },
    },
    dimensions: [{ name: 'cohortNthDay' }],
    metrics: [
      { name: 'cohortActiveUsers' },
      { name: 'cohortTotalUsers' },
    ],
    limit: 100,
  });

  const rows: any[] = body.rows ?? [];
  // cohortTotalUsers at day 0 = baseline cohort size
  const d0Row = rows.find((r: any) => r.dimensionValues?.[0]?.value === '0000');
  const baseline = d0Row ? parseInt(d0Row.metricValues?.[1]?.value ?? '0', 10) : 0;
  if (baseline <= 0) return [];

  return rows
    .map((row: any) => {
      const nthDay = parseInt((row.dimensionValues?.[0]?.value ?? '0') as string, 10);
      const active = parseInt((row.metricValues?.[0]?.value ?? '0') as string, 10);
      return { day: nthDay, rate: parseFloat((active / baseline).toFixed(4)) };
    })
    .sort((a, b) => a.day - b.day);
}

// ─── ENGAGEMENT / SESSION DURATION ──────────────────────────────────────────

async function fetchEngagement(
  propertyId: string,
  token: string,
): Promise<{ date: string; avg_session_sec: number }[]> {
  const body = await ga4Post<any>(propertyId, token, ':runReport', {
    dateRanges: [{ startDate: '42daysAgo', endDate: 'yesterday' }],
    dimensions: [{ name: 'date' }],
    metrics:    [{ name: 'averageSessionDuration' }],
    orderBys:   [{ dimension: { dimensionName: 'date' } }],
    limit: 100,
  });

  return ((body.rows ?? []) as any[]).map((row: any) => ({
    date:            (row.dimensionValues?.[0]?.value ?? '') as string,
    avg_session_sec: parseFloat(parseFloat((row.metricValues?.[0]?.value ?? '0') as string).toFixed(1)),
  }));
}

// ─── MAIN EXPORT ─────────────────────────────────────────────────────────────

export async function fetchAndStoreRetentionMetrics(
  serviceAccountJson: string,
  analyticsPropertyId: string,
): Promise<void> {
  const db  = admin.firestore();
  const doc = db.collection('dashboard_metrics').doc('retention');
  const sa  = JSON.parse(serviceAccountJson);
  const token = await getToken(sa.client_email, sa.private_key);

  await doc.set({ status: 'loading', updated_at: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });

  const [newVsRet, curve, engagement] = await Promise.all([
    fetchNewVsReturning(analyticsPropertyId, token).catch(() => []),
    fetchRetentionCurve(analyticsPropertyId, token).catch(() => []),
    fetchEngagement(analyticsPropertyId, token).catch(() => []),
  ]);

  await doc.set({
    status:            'ok',
    updated_at:        admin.firestore.FieldValue.serverTimestamp(),
    updated_at_label:  new Date().toLocaleString('es-CO', { timeZone: 'America/Bogota' }),
    new_vs_returning:  newVsRet,
    retention_curve:   curve,
    engagement_series: engagement,
    ltv_curve:         [],
  });

  console.log(
    `Retention updated — newVsRet=${newVsRet.length} pts, curve=${curve.length} pts, engagement=${engagement.length} pts`,
  );
}
