import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret, defineString } from 'firebase-functions/params';
import { setGlobalOptions } from 'firebase-functions/v2';

admin.initializeApp();

setGlobalOptions({ region: 'us-central1' });

const applePrivateKey = defineSecret('APPLE_PRIVATE_KEY');
const revenueCatApiKey = defineSecret('REVENUECAT_SECRET_API_KEY');
const revenueCatProjectId = defineString('REVENUECAT_PROJECT_ID');

export { processNotificationQueue } from './notifications/sendPushNotification';

// ── Actualización diaria de métricas App Store (7 AM UTC = 2 AM Colombia) ────
export const updateAppStoreMetrics = onSchedule(
  {
    schedule: '0 7 * * *',
    timeoutSeconds: 300,
    memory: '512MiB',
    secrets: [applePrivateKey],
  },
  async () => {
    const { fetchAndStoreAppStoreMetrics } = await import('./appstore/fetchAppStoreMetrics');
    await fetchAndStoreAppStoreMetrics(applePrivateKey.value());
  }
);

// ── Refresco manual desde el dashboard (trigger vía Firestore) ───────────────
export const refreshAppStoreMetrics = onDocumentCreated(
  {
    document: 'dashboard_metrics/appstore/refresh_triggers/{docId}',
    timeoutSeconds: 300,
    memory: '512MiB',
    secrets: [applePrivateKey],
  },
  async (event) => {
    const ref = event.data?.ref;
    try {
      const { fetchAndStoreAppStoreMetrics } = await import('./appstore/fetchAppStoreMetrics');
      await fetchAndStoreAppStoreMetrics(applePrivateKey.value());
    } finally {
      if (ref) await ref.delete();
    }
  }
);

// ── Actualización diaria de métricas RevenueCat (7:15 AM UTC) ───────────────
export const updateRevenueCatMetrics = onSchedule(
  {
    schedule: '15 7 * * *',
    timeoutSeconds: 300,
    memory: '512MiB',
    secrets: [revenueCatApiKey],
  },
  async () => {
    const { fetchAndStoreRevenueCatMetrics } = await import('./revenuecat/fetchRevenueCatMetrics');
    await fetchAndStoreRevenueCatMetrics(
      revenueCatApiKey.value(),
      revenueCatProjectId.value(),
    );
  }
);

// ── Refresco manual / inicial desde el dashboard vía Firestore ───────────────
export const refreshRevenueCatMetricsRequest = onDocumentCreated(
  {
    document: 'dashboard_metrics/revenuecat/refresh_requests/{docId}',
    timeoutSeconds: 300,
    memory: '512MiB',
    secrets: [revenueCatApiKey],
  },
  async (event) => {
    const ref = event.data?.ref;
    try {
      const { fetchAndStoreRevenueCatMetrics } = await import('./revenuecat/fetchRevenueCatMetrics');
      await fetchAndStoreRevenueCatMetrics(
        revenueCatApiKey.value(),
        revenueCatProjectId.value(),
      );
    } finally {
      if (ref) await ref.delete();
    }
  }
);
