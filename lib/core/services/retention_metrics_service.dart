import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_analitycs/core/models/retention_metrics_model.dart';

class RetentionMetricsService {
  static final _doc = FirebaseFirestore.instance
      .collection('dashboard_metrics')
      .doc('retention');

  static Stream<RetentionMetrics?> stream() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return RetentionMetrics.fromMap(snap.data()!);
    });
  }

  static Future<void> requestRefresh({String source = 'manual'}) async {
    await _doc.collection('refresh_requests').add({
      'created_at': FieldValue.serverTimestamp(),
      'source': source,
    });
  }

  static Future<bool> needsRefresh() async {
    final snap = await _doc.get();
    if (!snap.exists) return true;
    final ts = snap.data()?['updated_at'] as Timestamp?;
    if (ts == null) return true;
    return DateTime.now().difference(ts.toDate()).inHours >= 4;
  }
}
