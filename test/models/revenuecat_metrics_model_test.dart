import 'package:dashboard_analitycs/core/models/revenuecat_metrics_model.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RevenueCatDailyPoint', () {
    test('fromMap parsea correctamente', () {
      final p = RevenueCatDailyPoint.fromMap({
        'date': '2026-06-01',
        'revenue': 3.99,
      });
      expect(p.date, '2026-06-01');
      expect(p.revenue, 3.99);
    });

    test('fromMap tolera campos nulos', () {
      final p = RevenueCatDailyPoint.fromMap({});
      expect(p.date, '');
      expect(p.revenue, 0.0);
    });
  });

  group('RevenueCatRangeMetrics', () {
    test('fromMap con datos vacíos retorna defaults', () {
      final r = RevenueCatRangeMetrics.fromMap({});
      expect(r.mrr, 0.0);
      expect(r.revenue, 0.0);
      expect(r.activeSubscriptions, 0);
      expect(r.timeSeries, isEmpty);
    });

    test('fromMap parsea revenue_time_series', () {
      final r = RevenueCatRangeMetrics.fromMap({
        'revenue': 99.9,
        'revenue_time_series': [
          {'date': '2026-06-01', 'revenue': 9.99},
          {'date': '2026-06-02', 'revenue': 0.0},
        ],
      });
      expect(r.revenue, 99.9);
      expect(r.timeSeries.length, 2);
      expect(r.timeSeries[0].revenue, 9.99);
      expect(r.timeSeries[1].revenue, 0.0);
    });

    test('formatCurrency retorna — para valores <= 0', () {
      expect(RevenueCatRangeMetrics.formatCurrency(0), '—');
      expect(RevenueCatRangeMetrics.formatCurrency(-1), '—');
    });

    test('formatCurrency formatea correctamente', () {
      expect(RevenueCatRangeMetrics.formatCurrency(9.99), '\$10');
      expect(RevenueCatRangeMetrics.formatCurrency(1000), '\$1000');
    });

    test('churnLabel maneja churn 0', () {
      const r = RevenueCatRangeMetrics(churn: 0);
      expect(r.churnLabel, '—');
    });

    test('churnLabel convierte rate a porcentaje', () {
      const r = RevenueCatRangeMetrics(churn: 0.05);
      expect(r.churnLabel, '5.0%');
    });
  });

  group('RevenueCatOverviewMetrics', () {
    test('fromMap parsea todos los campos', () {
      final o = RevenueCatOverviewMetrics.fromMap({
        'mrr': 150.0,
        'active_trials': 12,
        'active_subscriptions': 45,
        'revenue_28d': 300.0,
        'new_customers_28d': 8,
        'active_customers_28d': 53,
      });
      expect(o.mrr, 150.0);
      expect(o.activeTrials, 12);
      expect(o.activeSubscriptions, 45);
      expect(o.revenue28d, 300.0);
    });

    test('fromMap usa 0 para campos faltantes', () {
      final o = RevenueCatOverviewMetrics.fromMap({});
      expect(o.mrr, 0.0);
      expect(o.activeTrials, 0);
    });
  });

  group('RevenueCatMetrics', () {
    test('fromMap parsea status y currency', () {
      final m = RevenueCatMetrics.fromMap({
        'status': 'ready',
        'currency': 'USD',
        'updated_at_label': '5 jun 2026',
      });
      expect(m.status, 'ready');
      expect(m.currency, 'USD');
      expect(m.updatedAtLabel, '5 jun 2026');
    });

    test('range() retorna defaults cuando no hay datos', () {
      final m = RevenueCatMetrics.fromMap({});
      final r = m.range(DateRange.d7);
      expect(r.revenue, 0.0);
      expect(r.timeSeries, isEmpty);
    });

    test('fromMap con mapa vacío no lanza excepción', () {
      expect(() => RevenueCatMetrics.fromMap({}), returnsNormally);
    });
  });
}
