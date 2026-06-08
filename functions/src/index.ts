import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import { setGlobalOptions } from 'firebase-functions/v2';

admin.initializeApp();

setGlobalOptions({ region: 'us-central1' });

const applePrivateKey = defineSecret('APPLE_PRIVATE_KEY');

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
    document: 'appstore_refresh_triggers/{docId}',
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
