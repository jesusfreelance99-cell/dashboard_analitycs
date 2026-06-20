import * as admin from 'firebase-admin';

// Productos Trevo — identificadores exactos de App Store / Play Store
const ANNUAL_PRODUCT_IDS = new Set([
  'trevo_ia_pro_yearly',
  'trevo_ia_pro_yearly_android:annual-yearly',
]);
const MONTHLY_PRODUCT_IDS = new Set([
  'trevo_ia_monthly_pro',
  'trevo_ia_monthly_pro_android:defaultmonthly',
]);

export type SubStatus = 'active' | 'trial' | 'cancelled' | 'expired' | 'trial_cancelled';

function resolveStatus(eventType: string, periodType: string): SubStatus | null {
  switch (eventType) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'UNCANCELLATION':
      return periodType === 'TRIAL' ? 'trial' : 'active';
    case 'TRIAL_STARTED':
      return 'trial';
    case 'TRIAL_CONVERTED':
      return 'active';
    case 'TRIAL_CANCELLED':
      return 'trial_cancelled';
    case 'CANCELLATION':
      return 'cancelled';
    case 'EXPIRATION':
      return 'expired';
    default:
      return null;
  }
}

export async function handleRevenueCatWebhookEvent(body: Record<string, unknown>): Promise<void> {
  const event = body.event as Record<string, unknown> | undefined;
  if (!event) {
    console.warn('RC webhook: body sin campo "event"');
    return;
  }

  const eventType  = event.type as string | undefined;
  const environment = event.environment as string | undefined;
  const productId  = event.product_id as string | undefined;
  const appUserId  = event.app_user_id as string | undefined;
  const periodType = (event.period_type as string | undefined) ?? '';

  if (!eventType || !productId || !appUserId) {
    console.warn('RC webhook: faltan campos obligatorios', { eventType, productId, appUserId });
    return;
  }

  // Solo eventos de producción — ignorar sandbox
  if (environment !== 'PRODUCTION') {
    console.log(`RC webhook: ignorado (env=${environment})`);
    return;
  }

  const status = resolveStatus(eventType, periodType);
  if (!status) {
    console.log(`RC webhook: tipo ignorado event=${eventType}`);
    return;
  }

  const isAnnual  = ANNUAL_PRODUCT_IDS.has(productId);
  const isMonthly = MONTHLY_PRODUCT_IDS.has(productId);

  const db = admin.firestore();
  const docRef = db
    .collection('dashboard_metrics')
    .doc('revenuecat_webhook')
    .collection('subscriptions')
    .doc(appUserId);

  await docRef.set({
    product_id:  productId,
    is_annual:   isAnnual,
    is_monthly:  isMonthly,
    status,
    environment,
    event_type:  eventType,
    updated_at:  admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`RC webhook ✓ user=${appUserId} product=${productId} status=${status} event=${eventType}`);
}

// Cuenta el estado actual de suscripciones desde los documentos del webhook
export async function countSubscriptionsFromWebhook(): Promise<{
  annual: number;
  annualTrial: number;
  annualCancelled: number;
  monthly: number;
  monthlyCancelled: number;
  cancelled: number;
  totalWithPlan: number;
}> {
  const db = admin.firestore();
  const snap = await db
    .collection('dashboard_metrics')
    .doc('revenuecat_webhook')
    .collection('subscriptions')
    .get();

  let annual = 0, annualTrial = 0, annualCancelled = 0;
  let monthly = 0, monthlyCancelled = 0, cancelled = 0, totalWithPlan = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const status    = d['status'] as SubStatus;
    const isAnnual  = d['is_annual']  as boolean;
    const isMonthly = d['is_monthly'] as boolean;

    if (!isAnnual && !isMonthly) continue;
    totalWithPlan++;

    if (status === 'trial') {
      if (isAnnual) annualTrial++;
    } else if (status === 'active') {
      if (isAnnual)       annual++;
      else if (isMonthly) monthly++;
    } else {
      // cancelled, expired, trial_cancelled
      if (isAnnual)       annualCancelled++;
      else if (isMonthly) monthlyCancelled++;
      cancelled++;
    }
  }

  console.log(
    `📊 Webhook state (${snap.size} docs): anual=${annual} trial=${annualTrial}` +
    ` mensual=${monthly} | cancel anual=${annualCancelled} mensual=${monthlyCancelled}`,
  );
  return { annual, annualTrial, annualCancelled, monthly, monthlyCancelled, cancelled, totalWithPlan };
}
