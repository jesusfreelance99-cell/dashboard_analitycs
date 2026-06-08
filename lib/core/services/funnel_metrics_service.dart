import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_analitycs/core/models/funnel_metrics_model.dart';

class FunnelMetricsService {
  static final _doc = FirebaseFirestore.instance
      .collection('dashboard_metrics')
      .doc('funnel');

  static Stream<FunnelMetrics?> stream() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return FunnelMetrics.fromMap(snap.data()!);
    });
  }
}
