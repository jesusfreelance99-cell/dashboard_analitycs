import 'package:cloud_firestore/cloud_firestore.dart';

class FcmSendService {
  static final FcmSendService _instance = FcmSendService._internal();
  final _firestore = FirebaseFirestore.instance;

  factory FcmSendService() {
    return _instance;
  }

  FcmSendService._internal();

  /// Enviar notificación a múltiples usuarios
  /// Guarda la notificación en Firestore para que Cloud Function la procese
  Future<bool> sendNotification({
    required String title,
    required String message,
    required List<String> fcmTokens,
    Map<String, String>? data,
  }) async {
    try {
      if (fcmTokens.isEmpty) {
        print('⚠️ No hay tokens FCM para enviar');
        return false;
      }

      print('🔵 Enviando notificación a ${fcmTokens.length} usuarios...');

      // Crear documento en Firestore para que Cloud Function lo procese
      final notificationDoc = {
        'title': title,
        'message': message,
        'fcm_tokens': fcmTokens,
        'data': data ?? {},
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'sent_count': 0,
        'failed_count': 0,
      };

      final docRef = await _firestore
          .collection('notifications_queue')
          .add(notificationDoc);

      print('✅ Notificación enviada a procesar: ${docRef.id}');
      print('📊 Destinatarios: ${fcmTokens.length}');

      return true;
    } catch (e) {
      print('❌ Error enviando notificación: $e');
      return false;
    }
  }

  /// Enviar notificación a todos los usuarios activos
  Future<bool> sendToAllUsers({
    required String title,
    required String message,
    Map<String, String>? data,
    required List<String> fcmTokens,
  }) async {
    return sendNotification(
      title: title,
      message: message,
      fcmTokens: fcmTokens,
      data: data,
    );
  }

  /// Obtener estado de una notificación enviada
  Future<Map<String, dynamic>?> getNotificationStatus(String notificationId) async {
    try {
      final doc = await _firestore
          .collection('notifications_queue')
          .doc(notificationId)
          .get();

      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      print('❌ Error obteniendo estado: $e');
      return null;
    }
  }

  /// Obtener historial de notificaciones enviadas
  Future<List<Map<String, dynamic>>> getNotificationHistory({
    int limit = 50,
  }) async {
    try {
      final query = await _firestore
          .collection('notifications_queue')
          .where('status', isEqualTo: 'completed')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error obteniendo historial: $e');
      return [];
    }
  }
}
