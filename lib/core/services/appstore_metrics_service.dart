import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appstore_metrics_model.dart';

class AppStoreMetricsService {
  static final _doc = FirebaseFirestore.instance
      .collection('appstore_metrics')
      .doc('latest');

  static Stream<AppStoreMetrics?> stream() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppStoreMetrics.fromMap(snap.data()!);
    });
  }

  static Future<AppStoreMetrics?> get() async {
    final snap = await _doc.get();
    if (!snap.exists) return null;
    return AppStoreMetrics.fromMap(snap.data()!);
  }
}
