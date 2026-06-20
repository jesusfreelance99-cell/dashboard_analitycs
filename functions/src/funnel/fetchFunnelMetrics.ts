import * as admin from 'firebase-admin';
import * as jwt from 'jsonwebtoken';

const GA4_SCOPE = 'https://www.googleapis.com/auth/analytics.readonly';
const GA4_API   = 'https://analyticsdata.googleapis.com/v1beta';

// All events we care about for the funnel + extras
const FUNNEL_EVENTS = [
  'first_open',
  'app_open',
  'session_start',
  'onboarding_step',
  'tutorial_begin',
  'tutorial_complete',
  'sign_up',
  'login',
  'paywall_viewed',
  'trial_started',
  'ecommerce_purchase',
  'purchase',
  'app_store_subscription_convert',
  'app_store_subscription_renew',
  'purchase_cancelled',
  'in_app_purchase',
  'user_engagement',
  'screen_view',
];

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

interface EventRow { name: string; count: number; uniqueUsers: number; }
interface StepRow  { stepName: string; count: number; uniqueUsers: number; }

async function runReport(
  propertyId: string,
  token: string,
  startDate: string,
  endDate: string,
): Promise<EventRow[]> {
  const res = await fetch(`${GA4_API}/properties/${propertyId}:runReport`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      dateRanges: [{ startDate, endDate }],
      dimensions: [{ name: 'eventName' }],
      metrics: [{ name: 'eventCount' }, { name: 'totalUsers' }],
      dimensionFilter: {
        filter: {
          fieldName: 'eventName',
          inListFilter: { values: FUNNEL_EVENTS },
        },
      },
      limit: 100,
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    console.error(`GA4 runReport error ${res.status}: ${err}`);
    return [];
  }

  const body = await res.json() as any;
  return (body.rows ?? []).map((row: any) => ({
    name:        row.dimensionValues?.[0]?.value ?? '',
    count:       parseInt(row.metricValues?.[0]?.value ?? '0', 10),
    uniqueUsers: parseInt(row.metricValues?.[1]?.value ?? '0', 10),
  }));
}

async function runOnboardingBreakdown(
  propertyId: string,
  token: string,
  startDate: string,
  endDate: string,
): Promise<StepRow[]> {
  try {
    const res = await fetch(`${GA4_API}/properties/${propertyId}:runReport`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        dateRanges: [{ startDate, endDate }],
        dimensions: [{ name: 'customEvent:step_name' }],
        metrics: [{ name: 'eventCount' }, { name: 'totalUsers' }],
        dimensionFilter: {
          filter: {
            fieldName: 'eventName',
            stringFilter: { matchType: 'EXACT', value: 'onboarding_step' },
          },
        },
        orderBys: [{ dimension: { dimensionName: 'customEvent:step_name' } }],
        limit: 50,
      }),
    });

    if (!res.ok) {
      console.warn(`GA4 onboarding breakdown ${res.status}: ${await res.text()}`);
      return [];
    }

    const body = await res.json() as any;
    return ((body.rows ?? []) as any[])
      .map((row: any) => ({
        stepName:    (row.dimensionValues?.[0]?.value ?? '') as string,
        count:       parseInt((row.metricValues?.[0]?.value ?? '0') as string, 10),
        uniqueUsers: parseInt((row.metricValues?.[1]?.value ?? '0') as string, 10),
      }))
      .filter((r: StepRow) => r.stepName !== '(not set)' && r.stepName !== '');
  } catch (err) {
    console.warn('Onboarding breakdown error (non-fatal):', err);
    return [];
  }
}

function toMap(rows: EventRow[]) {
  const m: Record<string, EventRow> = {};
  for (const r of rows) m[r.name] = r;
  return m;
}

function rangeDoc(rows: EventRow[], onboardingSteps: StepRow[] = []) {
  const m = toMap(rows);
  return {
    paywall_viewed:        m['paywall_viewed']?.count       ?? 0,
    trial_started:         m['trial_started']?.count        ?? 0,
    unique_paywall:        m['paywall_viewed']?.uniqueUsers ?? 0,
    unique_trial:          m['trial_started']?.uniqueUsers  ?? 0,
    app_open_count:        m['app_open']?.count             ?? 0,
    app_open_unique:       m['app_open']?.uniqueUsers       ?? 0,
    tutorial_begin_count:  m['tutorial_begin']?.count       ?? 0,
    tutorial_begin_unique: m['tutorial_begin']?.uniqueUsers ?? 0,
    events: rows.map(r => ({
      name:         r.name,
      count:        r.count,
      unique_users: r.uniqueUsers,
    })),
    onboarding_steps: onboardingSteps.map(s => ({
      step_name:    s.stepName,
      count:        s.count,
      unique_users: s.uniqueUsers,
    })),
  };
}

export async function fetchAndStoreFunnelMetrics(
  serviceAccountJson: string,
  analyticsPropertyId: string,
) {
  const sa    = JSON.parse(serviceAccountJson);
  const token = await getToken(sa.client_email, sa.private_key);

  const [r7, r30, r90, rAll] = await Promise.all([
    runReport(analyticsPropertyId, token, '7daysAgo',  'today'),
    runReport(analyticsPropertyId, token, '30daysAgo', 'today'),
    runReport(analyticsPropertyId, token, '90daysAgo', 'today'),
    runReport(analyticsPropertyId, token, '2020-01-01', 'today'),
  ]);

  // Onboarding step breakdown — best-effort, non-fatal if GA4 dimension not registered
  const [ob7, ob30, ob90, obAll] = await Promise.all([
    runOnboardingBreakdown(analyticsPropertyId, token, '7daysAgo',  'today'),
    runOnboardingBreakdown(analyticsPropertyId, token, '30daysAgo', 'today'),
    runOnboardingBreakdown(analyticsPropertyId, token, '90daysAgo', 'today'),
    runOnboardingBreakdown(analyticsPropertyId, token, '2020-01-01', 'today'),
  ]);

  const doc = {
    status: 'ok',
    updated_at_label: new Date().toLocaleString('es-CO', { timeZone: 'America/Bogota' }),
    all_events: rAll.map(r => ({ name: r.name, count: r.count, unique_users: r.uniqueUsers })),
    ranges: {
      d7:  rangeDoc(r7,  ob7),
      d30: rangeDoc(r30, ob30),
      d90: rangeDoc(r90, ob90),
      all: rangeDoc(rAll, obAll),
    },
  };

  await admin.firestore().collection('dashboard_metrics').doc('funnel').set(doc);
  console.log(`Funnel metrics updated. d7=${r7.length} events, d30=${r30.length} events, all=${rAll.length} events`);
}
