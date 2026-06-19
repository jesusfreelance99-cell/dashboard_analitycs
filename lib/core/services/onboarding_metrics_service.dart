import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_analitycs/core/models/onboarding_metrics_model.dart';

class OnboardingMetricsService {
  static Stream<OnboardingMetrics?> stream() =>
      FirebaseFirestore.instance
          .collection('dashboard_metrics')
          .doc('onboarding')
          .snapshots()
          .map((snap) {
        final data = snap.data();
        if (data == null) return null;
        return OnboardingMetrics.fromMap(data);
      });
}
