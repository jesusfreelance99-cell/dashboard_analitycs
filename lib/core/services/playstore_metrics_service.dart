import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_analitycs/core/models/playstore_metrics_model.dart';

class PlayStoreMetricsService {
  static Stream<PlayStoreMetrics?> stream() {
    return FirebaseFirestore.instance
        .collection('dashboard_metrics')
        .doc('playstore')
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return PlayStoreMetrics.fromMap(data);
    });
  }

  static Future<void> requestRefresh() async {
    await FirebaseFirestore.instance
        .collection('dashboard_metrics')
        .doc('playstore')
        .collection('refresh_triggers')
        .add({'created_at': FieldValue.serverTimestamp()});
  }
}
