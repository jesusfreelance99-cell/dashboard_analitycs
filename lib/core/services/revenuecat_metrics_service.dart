import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/revenuecat_metrics_model.dart';

class RevenueCatMetricsService {
  static final _doc = FirebaseFirestore.instance
      .collection('dashboard_metrics')
      .doc('revenuecat');

  static bool _autoRefreshRequested = false;

  static Stream<RevenueCatMetrics?> stream() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return RevenueCatMetrics.fromMap(snap.data()!);
    });
  }

  static Future<void> requestRefresh({String source = 'manual'}) async {
    await _doc.collection('refresh_requests').add({
      'source': source,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> autoRefreshOnDashboardEntry() async {
    if (_autoRefreshRequested) return;
    _autoRefreshRequested = true;

    try {
      final snap = await _doc.get();
      final data = snap.data();
      final updatedAt = data?['updated_at'] as Timestamp?;
      final status = data?['status'] as String?;

      final isMissing = !snap.exists || data == null;
      final isStale = updatedAt == null
          ? true
          : DateTime.now().difference(updatedAt.toDate()) >
                const Duration(minutes: 30);

      if (isMissing || isStale || status == 'error') {
        await requestRefresh(source: 'dashboard_entry');
      }
    } catch (_) {
      // Si falla, reseteamos la bandera para que lo reintente en la próxima sesión
      _autoRefreshRequested = false;
    }
  }
}
