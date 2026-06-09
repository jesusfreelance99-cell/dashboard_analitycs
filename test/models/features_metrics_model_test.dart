import 'package:dashboard_analitycs/core/models/features_metrics_model.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeaturesTimeSeries', () {
    test('fromList con lista vacía devuelve valores por defecto', () {
      final ts = FeaturesTimeSeries.fromList([]);
      expect(ts.dates, isEmpty);
      expect(ts.activeUsers, isEmpty);
      expect(ts.sessions, isEmpty);
      expect(ts.revenue, isEmpty);
      expect(ts.hasData, false);
    });

    test('fromList ignora entradas que no son Map', () {
      final ts = FeaturesTimeSeries.fromList([null, 'string', 42]);
      expect(ts.dates, isEmpty);
    });

    test('fromList parsea correctamente campos válidos', () {
      final ts = FeaturesTimeSeries.fromList([
        {'date': '20260601', 'active_users': 10, 'sessions': 15, 'revenue': 3.5},
        {'date': '20260602', 'active_users': 20, 'sessions': 30, 'revenue': 7.0},
      ]);
      expect(ts.dates, ['20260601', '20260602']);
      expect(ts.activeUsers, [10, 20]);
      expect(ts.sessions, [15, 30]);
      expect(ts.revenue, [3.5, 7.0]);
      expect(ts.hasData, true);
    });

    test('fromList tolera campos nulos usando defaults', () {
      final ts = FeaturesTimeSeries.fromList([
        {'date': '20260601'},
      ]);
      expect(ts.activeUsers, [0]);
      expect(ts.sessions, [0]);
      expect(ts.revenue, [0.0]);
    });

    test('maxValue retorna el máximo entre activeUsers y sessions', () {
      final ts = FeaturesTimeSeries.fromList([
        {'date': '20260601', 'active_users': 50, 'sessions': 80},
        {'date': '20260602', 'active_users': 30, 'sessions': 20},
      ]);
      expect(ts.maxValue, 80);
    });

    test('maxValue con listas vacías no lanza excepción', () {
      const ts = FeaturesTimeSeries();
      expect(ts.maxValue, 0);
    });
  });

  group('FeaturesMetrics.fromMap', () {
    test('devuelve defaults cuando el map está vacío', () {
      final m = FeaturesMetrics.fromMap({});
      expect(m.status, 'idle');
      expect(m.updatedAtLabel, '');
      expect(m.retention, isEmpty);
      expect(m.timeSeries.hasData, false);
    });

    test('parsea status y updatedAtLabel', () {
      final m = FeaturesMetrics.fromMap({
        'status': 'ready',
        'updated_at_label': '5 jun 2026',
      });
      expect(m.status, 'ready');
      expect(m.updatedAtLabel, '5 jun 2026');
    });

    test('session() devuelve defaults cuando no hay datos', () {
      final m = FeaturesMetrics.fromMap({});
      final sm = m.session(DateRange.d7);
      expect(sm?.activeUsers, 0);
      expect(sm?.sessions, 0);
    });

    test('featureList() devuelve lista vacía cuando no hay datos', () {
      final m = FeaturesMetrics.fromMap({});
      expect(m.featureList(DateRange.d30), isEmpty);
    });

    test('parsea timeSeries desde time_series', () {
      final m = FeaturesMetrics.fromMap({
        'time_series': [
          {'date': '20260601', 'active_users': 5, 'sessions': 8},
        ],
      });
      expect(m.timeSeries.hasData, true);
      expect(m.timeSeries.activeUsers, [5]);
    });
  });

  group('SessionMetrics', () {
    test('avgDurationFormatted devuelve — cuando es 0', () {
      const sm = SessionMetrics();
      expect(sm.avgDurationFormatted, '—');
    });

    test('avgDurationFormatted formatea segundos correctamente', () {
      const sm = SessionMetrics(avgDurationSec: 317);
      expect(sm.avgDurationFormatted, '5m 17s');
    });

    test('engagementRatePct convierte rate a porcentaje', () {
      const sm = SessionMetrics(engagementRate: 0.742);
      expect(sm.engagementRatePct, '74.2%');
    });
  });

  group('FeatureEventRow', () {
    test('displayName retorna label conocido', () {
      const row = FeatureEventRow(
        name: 'expense_added',
        count: 10,
        uniqueUsers: 5,
        perSession: 1.0,
      );
      expect(row.displayName, 'Registrar gasto');
    });

    test('displayName convierte snake_case a Title Case cuando no hay label', () {
      const row = FeatureEventRow(
        name: 'custom_event_name',
        count: 1,
        uniqueUsers: 1,
        perSession: 0,
      );
      expect(row.displayName, 'Custom Event Name');
    });

    test('category retorna financial para expense_added', () {
      const row = FeatureEventRow(
        name: 'expense_added',
        count: 0,
        uniqueUsers: 0,
        perSession: 0,
      );
      expect(row.category, FeatureCategory.financial);
    });

    test('category retorna other para evento desconocido', () {
      const row = FeatureEventRow(
        name: 'unknown_event',
        count: 0,
        uniqueUsers: 0,
        perSession: 0,
      );
      expect(row.category, FeatureCategory.other);
    });

    test('fromMap tolera campos nulos', () {
      final row = FeatureEventRow.fromMap({});
      expect(row.name, '');
      expect(row.count, 0);
      expect(row.uniqueUsers, 0);
      expect(row.perSession, 0.0);
    });
  });

  group('FeatureRetentionRow', () {
    test('fromMap parsea correctamente', () {
      final row = FeatureRetentionRow.fromMap({
        'name': 'expense_added',
        'd1_users': 100,
        'd7_users': 60,
        'd30_users': 200,
        'retention_score': 0.5,
      });
      expect(row.name, 'expense_added');
      expect(row.d1Users, 100);
      expect(row.retentionScore, 0.5);
    });

    test('fromMap usa 0 para campos faltantes', () {
      final row = FeatureRetentionRow.fromMap({'name': 'test'});
      expect(row.d1Users, 0);
      expect(row.d7Users, 0);
      expect(row.retentionScore, 0.0);
    });
  });
}
