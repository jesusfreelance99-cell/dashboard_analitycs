import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret, defineString } from 'firebase-functions/params';
import { setGlobalOptions } from 'firebase-functions/v2';

admin.initializeApp();

setGlobalOptions({ region: 'us-central1' });

const applePrivateKey        = defineSecret('APPLE_PRIVATE_KEY');
const revenueCatApiKey       = defineSecret('REVENUECAT_SECRET_API_KEY');
const revenueCatProjectId    = defineString('REVENUECAT_PROJECT_ID');
const playstoreServiceAccount = defineSecret('PLAYSTORE_SERVICE_ACCOUNT');
const androidPackageName      = defineString('ANDROID_PACKAGE_NAME', { default: 'com.trevo.expenses' });
const analyticsPropertyId     = defineString('ANALYTICS_PROPERTY_ID', { default: '' });

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

// ── Actualización diaria de métricas Play Store (7:30 AM UTC) ───────────────
export const updatePlayStoreMetrics = onSchedule(
  {
    schedule: '30 7 * * *',
    timeoutSeconds: 300,
    memory: '512MiB',
    secrets: [playstoreServiceAccount],
  },
  async () => {
    const { fetchAndStorePlayStoreMetrics } = await import('./playstore/fetchPlayStoreMetrics');
    await fetchAndStorePlayStoreMetrics(
      playstoreServiceAccount.value(),
      androidPackageName.value(),
    );
  }
);

// ── Actualización diaria de métricas de embudo Firebase Analytics (7:45 AM UTC) ─
export const updateFunnelMetrics = onSchedule(
  {
    schedule: '45 7 * * *',
    timeoutSeconds: 300,
    memory: '512MiB',
    secrets: [playstoreServiceAccount],
  },
  async () => {
    if (!analyticsPropertyId.value()) {
      console.warn('ANALYTICS_PROPERTY_ID not set — skipping funnel metrics');
      return;
    }
    const { fetchAndStoreFunnelMetrics } = await import('./funnel/fetchFunnelMetrics');
    await fetchAndStoreFunnelMetrics(
      playstoreServiceAccount.value(),
      analyticsPropertyId.value(),
    );
  }
);

// ── Refresco manual del embudo desde el dashboard ────────────────────────────
export const refreshFunnelMetrics = onDocumentCreated(
  {
    document: 'dashboard_metrics/funnel/refresh_requests/{docId}',
    timeoutSeconds: 300,
    memory: '512MiB',
    secrets: [playstoreServiceAccount],
  },
  async (event) => {
    const ref = event.data?.ref;
    try {
      if (!analyticsPropertyId.value()) {
        console.warn('ANALYTICS_PROPERTY_ID not set');
        return;
      }
      const { fetchAndStoreFunnelMetrics } = await import('./funnel/fetchFunnelMetrics');
      await fetchAndStoreFunnelMetrics(
        playstoreServiceAccount.value(),
        analyticsPropertyId.value(),
      );
    } finally {
      if (ref) await ref.delete();
    }
  }
);

// ── Refresco manual Play Store desde el dashboard ────────────────────────────
export const refreshPlayStoreMetrics = onDocumentCreated(
  {
    document: 'dashboard_metrics/playstore/refresh_triggers/{docId}',
    timeoutSeconds: 300,
    memory: '512MiB',
    secrets: [playstoreServiceAccount],
  },
  async (event) => {
    const ref = event.data?.ref;
    try {
      const { fetchAndStorePlayStoreMetrics } = await import('./playstore/fetchPlayStoreMetrics');
      await fetchAndStorePlayStoreMetrics(
        playstoreServiceAccount.value(),
        androidPackageName.value(),
      );
    } finally {
      if (ref) await ref.delete();
    }
  }
);

// ── Actualización diaria de métricas de retención GA4 (8:00 AM UTC) ─────────
export const updateRetentionMetrics = onSchedule(
  {
    schedule: '0 8 * * *',
    timeoutSeconds: 300,
    memory: '512MiB',
    secrets: [playstoreServiceAccount],
  },
  async () => {
    if (!analyticsPropertyId.value()) {
      console.warn('ANALYTICS_PROPERTY_ID not set — skipping retention metrics');
      return;
    }
    const { fetchAndStoreRetentionMetrics } = await import('./retention/fetchRetentionMetrics');
    await fetchAndStoreRetentionMetrics(
      playstoreServiceAccount.value(),
      analyticsPropertyId.value(),
    );
  }
);

// ── Refresco manual de retención desde el dashboard ──────────────────────────
export const refreshRetentionMetrics = onDocumentCreated(
  {
    document: 'dashboard_metrics/retention/refresh_requests/{docId}',
    timeoutSeconds: 300,
    memory: '512MiB',
    secrets: [playstoreServiceAccount],
  },
  async (event) => {
    const ref = event.data?.ref;
    try {
      if (!analyticsPropertyId.value()) {
        console.warn('ANALYTICS_PROPERTY_ID not set');
        return;
      }
      const { fetchAndStoreRetentionMetrics } = await import('./retention/fetchRetentionMetrics');
      await fetchAndStoreRetentionMetrics(
        playstoreServiceAccount.value(),
        analyticsPropertyId.value(),
      );
    } finally {
      if (ref) await ref.delete();
    }
  }
);

// ── Actualización diaria de funnel de onboarding GA4 (8:15 AM UTC) ───────────
export const updateOnboardingMetrics = onSchedule(
  {
    schedule: '15 8 * * *',
    timeoutSeconds: 540,
    memory: '512MiB',
    secrets: [playstoreServiceAccount],
  },
  async () => {
    if (!analyticsPropertyId.value()) {
      console.warn('ANALYTICS_PROPERTY_ID not set — skipping onboarding metrics');
      return;
    }
    const { fetchAndStoreOnboardingMetrics } = await import('./onboarding/fetchOnboardingMetrics');
    await fetchAndStoreOnboardingMetrics(
      playstoreServiceAccount.value(),
      analyticsPropertyId.value(),
    );
  }
);

// ── Refresco manual de onboarding desde el dashboard ─────────────────────────
export const refreshOnboardingMetrics = onDocumentCreated(
  {
    document: 'dashboard_metrics/onboarding/refresh_requests/{docId}',
    timeoutSeconds: 540,
    memory: '512MiB',
    secrets: [playstoreServiceAccount],
  },
  async (event) => {
    const ref = event.data?.ref;
    try {
      if (!analyticsPropertyId.value()) {
        console.warn('ANALYTICS_PROPERTY_ID not set');
        return;
      }
      const { fetchAndStoreOnboardingMetrics } = await import('./onboarding/fetchOnboardingMetrics');
      await fetchAndStoreOnboardingMetrics(
        playstoreServiceAccount.value(),
        analyticsPropertyId.value(),
      );
    } finally {
      if (ref) await ref.delete();
    }
  }
);
