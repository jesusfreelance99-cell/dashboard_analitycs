import * as admin from 'firebase-admin';
import * as jwt from 'jsonwebtoken';

const GA4_SCOPE = 'https://www.googleapis.com/auth/analytics.readonly';
const GA4_API   = 'https://analyticsdata.googleapis.com/v1beta';

// ── Definición canónica de los 15 pasos ──────────────────────────────────────

interface StepDef {
  stepNumber:  number;
  eventName:   string;
  questionKey: string;
  questionEs:  string;
  isInfo:      boolean;
  isMulti:     boolean;
}

const STEPS: StepDef[] = [
  { stepNumber: 1,  eventName: 'onboarding_step_1',  questionKey: 'spending_concern',      questionEs: '¿Con qué frecuencia sientes que tu dinero desaparece?',      isInfo: false, isMulti: false },
  { stepNumber: 2,  eventName: 'onboarding_step_2',  questionKey: 'money_relationship',    questionEs: '¿Cómo describes tu relación con el dinero?',                  isInfo: false, isMulti: false },
  { stepNumber: 3,  eventName: 'onboarding_step_3',  questionKey: 'main_difficulty',       questionEs: '¿Cómo llegas normalmente a fin de mes?',                      isInfo: false, isMulti: false },
  { stepNumber: 4,  eventName: 'onboarding_step_4',  questionKey: 'trevo_impact',          questionEs: 'Pantalla de impacto Trevo (informativa)',                     isInfo: true,  isMulti: false },
  { stepNumber: 5,  eventName: 'onboarding_step_5',  questionKey: 'currency_selection',    questionEs: '¿Alguna vez has intentado controlar tus gastos?',             isInfo: false, isMulti: false },
  { stepNumber: 6,  eventName: 'onboarding_step_6',  questionKey: 'banking_status',        questionEs: '¿Qué pasó con ese intento?',                                  isInfo: false, isMulti: false },
  { stepNumber: 7,  eventName: 'onboarding_step_7',  questionKey: 'voice_intro',           questionEs: 'Demo de registro por voz (informativa)',                      isInfo: true,  isMulti: false },
  { stepNumber: 8,  eventName: 'onboarding_step_8',  questionKey: 'budget_interest',       questionEs: 'Pantalla "Así de simple registra Trevo" (informativa)',       isInfo: true,  isMulti: false },
  { stepNumber: 9,  eventName: 'onboarding_step_9',  questionKey: 'debt_status',           questionEs: '¿En qué se va normalmente tu plata?',                         isInfo: false, isMulti: true  },
  { stepNumber: 10, eventName: 'onboarding_step_10', questionKey: 'investment_interest',   questionEs: '¿Tienes suscripciones que no usas mucho?',                    isInfo: false, isMulti: false },
  { stepNumber: 11, eventName: 'onboarding_step_11', questionKey: 'subscriptions_tracker', questionEs: 'Pantalla de suscripciones invisibles (informativa)',           isInfo: true,  isMulti: false },
  { stepNumber: 12, eventName: 'onboarding_step_12', questionKey: 'plan_selection',        questionEs: '¿Qué te gustaría lograr con Trevo?',                          isInfo: false, isMulti: true  },
  { stepNumber: 13, eventName: 'onboarding_step_13', questionKey: 'account_setup',         questionEs: '¿Qué tan listo estás para tomar el control?',                 isInfo: false, isMulti: false },
  { stepNumber: 14, eventName: 'onboarding_step_14', questionKey: 'user_reviews',          questionEs: 'Pantalla de reseñas de usuarios (informativa)',               isInfo: true,  isMulti: false },
  { stepNumber: 15, eventName: 'onboarding_step_15', questionKey: 'personalization',       questionEs: 'Pantalla de personalización · animación final (informativa)', isInfo: true,  isMulti: false },
];

const STEP_BY_QUESTION_KEY = new Map(STEPS.map(s => [s.questionKey, s]));
const STEP_BY_NUMBER       = new Map(STEPS.map(s => [s.stepNumber, s]));
const ALL_STEP_EVENTS      = STEPS.map(s => s.eventName);

// ── Autenticación GA4 ────────────────────────────────────────────────────────

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

// ── Query: llegadas por paso ─────────────────────────────────────────────────

interface StepRow { eventName: string; totalUsers: number; eventCount: number; }

async function querySteps(
  propertyId: string, token: string, startDate: string, endDate: string,
): Promise<StepRow[]> {
  try {
    const res = await fetch(`${GA4_API}/properties/${propertyId}:runReport`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        dateRanges: [{ startDate, endDate }],
        dimensions: [{ name: 'eventName' }],
        metrics: [{ name: 'eventCount' }, { name: 'totalUsers' }],
        dimensionFilter: {
          filter: { fieldName: 'eventName', inListFilter: { values: ALL_STEP_EVENTS } },
        },
        limit: 50,
      }),
    });
    if (!res.ok) { console.error(`GA4 steps ${res.status}: ${await res.text()}`); return []; }
    const body = await res.json() as any;
    return ((body.rows ?? []) as any[]).map(row => ({
      eventName:  row.dimensionValues?.[0]?.value ?? '',
      eventCount: parseInt(row.metricValues?.[0]?.value ?? '0', 10),
      totalUsers: parseInt(row.metricValues?.[1]?.value ?? '0', 10),
    }));
  } catch (e) { console.error('querySteps error:', e); return []; }
}

// ── Query: distribución de respuestas ────────────────────────────────────────

interface AnswerRow { questionKey: string; answerSelected: string; totalUsers: number; }

async function queryAnswers(
  propertyId: string, token: string, startDate: string, endDate: string,
): Promise<AnswerRow[]> {
  try {
    const res = await fetch(`${GA4_API}/properties/${propertyId}:runReport`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        dateRanges: [{ startDate, endDate }],
        dimensions: [
          { name: 'customEvent:question_key' },
          { name: 'customEvent:answer_selected' },
        ],
        metrics: [{ name: 'totalUsers' }],
        dimensionFilter: {
          filter: {
            fieldName: 'eventName',
            stringFilter: { matchType: 'EXACT', value: 'onboarding_answer' },
          },
        },
        limit: 500,
      }),
    });
    if (!res.ok) { console.warn(`GA4 answers ${res.status} (non-fatal)`); return []; }
    const body = await res.json() as any;
    const rows = ((body.rows ?? []) as any[]).map(row => ({
      questionKey:    row.dimensionValues?.[0]?.value ?? '',
      answerSelected: row.dimensionValues?.[1]?.value ?? '',
      totalUsers:     parseInt(row.metricValues?.[0]?.value ?? '0', 10),
    }));
    // Filter out GA4 placeholder values and info-step answers
    return rows.filter(r =>
      r.questionKey !== '(not set)' && r.questionKey !== '' &&
      !['info_continued', 'voice_demo_completed', 'completed', '(not set)', ''].includes(r.answerSelected),
    );
  } catch (e) { console.warn('queryAnswers non-fatal error:', e); return []; }
}

// ── Construye el documento de rango ─────────────────────────────────────────

function buildRangeDoc(stepRows: StepRow[], answerRows: AnswerRow[]) {
  const stepMap = new Map(stepRows.map(r => [r.eventName, r]));

  const baseline       = stepMap.get('onboarding_step_1')?.totalUsers ?? 0;
  const totalCompleted = stepMap.get('onboarding_step_15')?.totalUsers ?? 0;

  if (baseline === 0) {
    return {
      total_started: 0, total_completed: 0, completion_rate: 0,
      max_dropoff_step: 0, steps: [], answers: [],
    };
  }

  let prevUsers      = baseline;
  let maxDropoffStep = 1;
  let maxDropoffPct  = 0;

  const stepsOut = STEPS.map((def, i) => {
    const row         = stepMap.get(def.eventName);
    const totalUsers  = row?.totalUsers  ?? 0;
    const eventCount  = row?.eventCount  ?? 0;
    const dropPct     = i > 0 && prevUsers > 0
      ? Math.max(0, (prevUsers - totalUsers) / prevUsers)
      : 0;

    if (dropPct > maxDropoffPct && i > 0) {
      maxDropoffPct  = dropPct;
      maxDropoffStep = def.stepNumber;
    }

    const out = {
      step_number:  def.stepNumber,
      event_name:   def.eventName,
      step_name:    def.questionKey,
      question_es:  def.questionEs,
      unique_users: totalUsers,
      event_count:  eventCount,
      pct_of_start: baseline > 0 ? totalUsers / baseline : 0,
      drop_pct:     dropPct,
      is_info:      def.isInfo,
    };

    if (totalUsers > 0) prevUsers = totalUsers;
    return out;
  });

  // Expand multi-select pipe-separated answers
  const expandedAnswers: AnswerRow[] = [];
  for (const a of answerRows) {
    const stepDef = STEP_BY_QUESTION_KEY.get(a.questionKey);
    if (!stepDef || stepDef.isInfo) continue;
    if (stepDef.isMulti && a.answerSelected.includes('|')) {
      for (const part of a.answerSelected.split('|').map(s => s.trim()).filter(Boolean)) {
        expandedAnswers.push({ ...a, answerSelected: part });
      }
    } else {
      expandedAnswers.push(a);
    }
  }

  // Merge duplicate answers
  const answerMerge = new Map<string, number>();
  for (const a of expandedAnswers) {
    const key = `${a.questionKey}__${a.answerSelected}`;
    answerMerge.set(key, (answerMerge.get(key) ?? 0) + a.totalUsers);
  }

  // Group by step
  const answersByStep = new Map<number, { questionKey: string; options: {answer: string; uniqueUsers: number; pct: number}[] }>();
  for (const [key, count] of answerMerge.entries()) {
    const [questionKey, answer] = key.split('__');
    const stepDef = STEP_BY_QUESTION_KEY.get(questionKey);
    if (!stepDef) continue;
    const stepTotal = stepMap.get(stepDef.eventName)?.totalUsers ?? 1;
    if (!answersByStep.has(stepDef.stepNumber)) {
      answersByStep.set(stepDef.stepNumber, { questionKey, options: [] });
    }
    answersByStep.get(stepDef.stepNumber)!.options.push({
      answer, uniqueUsers: count, pct: stepTotal > 0 ? count / stepTotal : 0,
    });
  }

  const answersOut: object[] = [];
  for (const [stepNumber, group] of answersByStep.entries()) {
    const def = STEP_BY_NUMBER.get(stepNumber)!;
    group.options.sort((a, b) => b.uniqueUsers - a.uniqueUsers);
    answersOut.push({
      step_number:  stepNumber,
      question_key: group.questionKey,
      question_es:  def.questionEs,
      options:      group.options,
    });
  }
  answersOut.sort((a: any, b: any) => a.step_number - b.step_number);

  return {
    total_started:    baseline,
    total_completed:  totalCompleted,
    completion_rate:  baseline > 0 ? totalCompleted / baseline : 0,
    max_dropoff_step: maxDropoffStep,
    steps:            stepsOut,
    answers:          answersOut,
  };
}

// ── Entry point ──────────────────────────────────────────────────────────────

export async function fetchAndStoreOnboardingMetrics(
  serviceAccountJson: string,
  analyticsPropertyId: string,
): Promise<void> {
  if (!analyticsPropertyId) {
    console.warn('ANALYTICS_PROPERTY_ID not set — skipping onboarding metrics');
    return;
  }

  const sa    = JSON.parse(serviceAccountJson);
  const token = await getToken(sa.client_email, sa.private_key);

  const [s7, s30, s90, sAll, a7, a30, a90, aAll] = await Promise.all([
    querySteps(analyticsPropertyId,   token, '7daysAgo',  'today'),
    querySteps(analyticsPropertyId,   token, '30daysAgo', 'today'),
    querySteps(analyticsPropertyId,   token, '90daysAgo', 'today'),
    querySteps(analyticsPropertyId,   token, '2020-01-01', 'today'),
    queryAnswers(analyticsPropertyId, token, '7daysAgo',  'today'),
    queryAnswers(analyticsPropertyId, token, '30daysAgo', 'today'),
    queryAnswers(analyticsPropertyId, token, '90daysAgo', 'today'),
    queryAnswers(analyticsPropertyId, token, '2020-01-01', 'today'),
  ]);

  const doc = {
    status: 'ok',
    updated_at_label: new Date().toLocaleString('es-CO', { timeZone: 'America/Bogota' }),
    ranges: {
      d7:  buildRangeDoc(s7,   a7),
      d30: buildRangeDoc(s30,  a30),
      d90: buildRangeDoc(s90,  a90),
      all: buildRangeDoc(sAll, aAll),
    },
  };

  await admin.firestore().collection('dashboard_metrics').doc('onboarding').set(doc);
  console.log(`Onboarding updated · step_1=${s7.find(r=>r.eventName==='onboarding_step_1')?.totalUsers ?? 0} users (7d)`);
}
