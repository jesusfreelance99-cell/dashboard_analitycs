import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

setGlobalOptions({ region: 'us-central1', timeoutSeconds: 540, memory: '512MiB' });

const db = admin.firestore();
const messaging = admin.messaging();

const FCM_BATCH_SIZE = 500;
const USERS_PAGE_SIZE = 500;

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function sendBatch(
  tokens: string[],
  title: string,
  body: string
): Promise<{ success: number; failed: number }> {
  if (tokens.length === 0) return { success: 0, failed: 0 };

  const msg: admin.messaging.MulticastMessage = {
    notification: { title, body },
    tokens,
    android: { priority: 'high', notification: { sound: 'default' } },
    apns: { payload: { aps: { sound: 'default', badge: 1 } } },
  };

  const res = await messaging.sendEachForMulticast(msg);
  return { success: res.successCount, failed: res.failureCount };
}

// ── Función principal ─────────────────────────────────────────────────────────

export const processNotificationQueue = onDocumentCreated(
  'notifications_queue/{docId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    if (!data || data.status !== 'pending') return;

    const docRef = snap.ref;
    const title = data.title as string;
    const message = data.message as string;
    const recipientType = data.recipient_type as string | undefined;

    await docRef.update({
      status: 'processing',
      started_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    let sentTotal = 0;
    let failedTotal = 0;

    try {
      if (!recipientType || recipientType === 'all') {
        // ── Envío a todos los usuarios activos ────────────────────────────────
        // Procesa página a página sin acumular todos los tokens en RAM
        let lastDoc: admin.firestore.DocumentSnapshot | null = null;
        let pagesProcessed = 0;

        while (true) {
          let query = db
            .collection('users')
            .where('user_info.status', '==', true)
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(USERS_PAGE_SIZE);

          if (lastDoc) query = query.startAfter(lastDoc);

          const page = await query.get();
          if (page.empty) break;

          const tokens: string[] = [];
          for (const doc of page.docs) {
            const token = doc.data()?.user_info?.fcm_token as string | undefined;
            if (token && token.trim().length > 0) tokens.push(token.trim());
          }

          if (tokens.length > 0) {
            for (const batch of chunk(tokens, FCM_BATCH_SIZE)) {
              const { success, failed } = await sendBatch(batch, title, message);
              sentTotal += success;
              failedTotal += failed;
            }
          }

          pagesProcessed++;
          // Actualiza progreso cada página para que el dashboard lo muestre
          await docRef.update({
            sent_count: sentTotal,
            failed_count: failedTotal,
          });

          if (page.size < USERS_PAGE_SIZE) break;
          lastDoc = page.docs[page.docs.length - 1];
        }
      } else if (recipientType === 'specific') {
        // ── Envío a usuarios específicos ─────────────────────────────────────
        const recipientIds = (data.recipient_ids as string[]) ?? [];
        if (recipientIds.length === 0) {
          await docRef.update({
            status: 'completed',
            sent_count: 0,
            failed_count: 0,
            note: 'Sin destinatarios específicos',
            completed_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          return;
        }

        // Firestore 'in' acepta máximo 30 valores a la vez
        for (const idChunk of chunk(recipientIds, 30)) {
          const snap = await db
            .collection('users')
            .where(admin.firestore.FieldPath.documentId(), 'in', idChunk)
            .get();

          const tokens: string[] = [];
          for (const doc of snap.docs) {
            const token = doc.data()?.user_info?.fcm_token as string | undefined;
            if (token && token.trim().length > 0) tokens.push(token.trim());
          }

          for (const batch of chunk(tokens, FCM_BATCH_SIZE)) {
            const { success, failed } = await sendBatch(batch, title, message);
            sentTotal += success;
            failedTotal += failed;
          }
        }
      }

      await docRef.update({
        status: 'completed',
        sent_count: sentTotal,
        failed_count: failedTotal,
        completed_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Notificación "${title}" enviada — éxitos: ${sentTotal}, fallos: ${failedTotal}`);
    } catch (err) {
      console.error('❌ Error procesando notificación:', err);
      await docRef.update({
        status: 'failed',
        error: String(err),
        sent_count: sentTotal,
        failed_count: failedTotal,
        completed_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);
