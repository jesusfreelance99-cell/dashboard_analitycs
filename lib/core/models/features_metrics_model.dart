import 'dart:math' as math;

import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';

class FeaturesTimeSeries {
  final List<String> dates; // "YYYYMMDD"
  final List<int> activeUsers;
  final List<int> sessions;
  final List<double> revenue;

  const FeaturesTimeSeries({
    this.dates = const [],
    this.activeUsers = const [],
    this.sessions = const [],
    this.revenue = const [],
  });

  bool get hasData => dates.isNotEmpty;
  int get maxValue => [
    activeUsers.isEmpty ? 0 : activeUsers.reduce(math.max),
    sessions.isEmpty ? 0 : sessions.reduce(math.max),
  ].reduce(math.max);

  factory FeaturesTimeSeries.fromList(List<dynamic> raw) {
    final points = raw.whereType<Map<String, dynamic>>().toList();
    return FeaturesTimeSeries(
      dates: points.map((p) => p['date'] as String? ?? '').toList(),
      activeUsers: points
          .map((p) => (p['active_users'] as num?)?.toInt() ?? 0)
          .toList(),
      sessions: points
          .map((p) => (p['sessions'] as num?)?.toInt() ?? 0)
          .toList(),
      revenue: points
          .map((p) => (p['revenue'] as num?)?.toDouble() ?? 0.0)
          .toList(),
    );
  }
}

class RetentionPoint {
  final int day;
  final double rate; // 0.0 – 1.0
  const RetentionPoint({required this.day, required this.rate});
}

class FeaturesMetrics {
  final String status;
  final String updatedAtLabel;
  final Map<DateRange, SessionMetrics> sessionMetrics;
  final Map<DateRange, List<FeatureEventRow>> features;
  final List<FeatureRetentionRow> retention;
  final List<RetentionPoint> retentionCurve;
  final FeaturesTimeSeries timeSeries;

  const FeaturesMetrics({
    required this.status,
    required this.updatedAtLabel,
    required this.sessionMetrics,
    required this.features,
    required this.retention,
    this.retentionCurve = const [],
    this.timeSeries = const FeaturesTimeSeries(),
  });

  static const empty = FeaturesMetrics(
    status: 'idle',
    updatedAtLabel: '',
    sessionMetrics: {},
    features: {},
    retention: [],
  );

  SessionMetrics? session(DateRange r) => sessionMetrics[r];
  List<FeatureEventRow> featureList(DateRange r) => features[r] ?? [];

  factory FeaturesMetrics.fromMap(Map<String, dynamic> map) {
    final smRaw = map['session_metrics'] as Map<String, dynamic>? ?? {};
    final featRaw = map['features'] as Map<String, dynamic>? ?? {};
    final retRaw = (map['retention'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>();
    final curveRaw = (map['retention_curve'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>();
    final tsRaw = map['time_series'] as List<dynamic>? ?? [];

    return FeaturesMetrics(
      status: map['status'] as String? ?? 'idle',
      updatedAtLabel: map['updated_at_label'] as String? ?? '',
      sessionMetrics: {
        DateRange.d7: SessionMetrics.fromMap(
          smRaw['d7'] as Map<String, dynamic>? ?? {},
        ),
        DateRange.d30: SessionMetrics.fromMap(
          smRaw['d30'] as Map<String, dynamic>? ?? {},
        ),
        DateRange.d90: SessionMetrics.fromMap(
          smRaw['d90'] as Map<String, dynamic>? ?? {},
        ),
        DateRange.all: SessionMetrics.fromMap(
          smRaw['d1'] as Map<String, dynamic>? ?? {},
        ),
      },
      features: {
        DateRange.d7: _parseFeatureList(featRaw['d7']),
        DateRange.d30: _parseFeatureList(featRaw['d30']),
        DateRange.d90: _parseFeatureList(featRaw['d90']),
        DateRange.all: _parseFeatureList(featRaw['d90']),
      },
      retention: retRaw.map(FeatureRetentionRow.fromMap).toList(),
      retentionCurve: curveRaw
          .map((p) => RetentionPoint(
                day: (p['day'] as num?)?.toInt() ?? 0,
                rate: (p['rate'] as num?)?.toDouble() ?? 0,
              ))
          .toList(),
      timeSeries: FeaturesTimeSeries.fromList(tsRaw),
    );
  }

  static List<FeatureEventRow> _parseFeatureList(dynamic raw) =>
      (raw as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FeatureEventRow.fromMap)
          .toList();
}

class SessionMetrics {
  final int sessions;
  final int activeUsers;
  final double sessionsPerUser;
  final double avgDurationSec;
  final int engagedSessions;
  final double engagementRate;

  const SessionMetrics({
    this.sessions = 0,
    this.activeUsers = 0,
    this.sessionsPerUser = 0,
    this.avgDurationSec = 0,
    this.engagedSessions = 0,
    this.engagementRate = 0,
  });

  String get avgDurationFormatted {
    if (avgDurationSec <= 0) return '—';
    final total = avgDurationSec.round();
    final m = total ~/ 60;
    final s = total % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  String get engagementRatePct =>
      '${(engagementRate * 100).toStringAsFixed(1)}%';

  factory SessionMetrics.fromMap(Map<String, dynamic> m) => SessionMetrics(
    sessions: (m['sessions'] as num?)?.toInt() ?? 0,
    activeUsers: (m['active_users'] as num?)?.toInt() ?? 0,
    sessionsPerUser: (m['sessions_per_user'] as num?)?.toDouble() ?? 0,
    avgDurationSec: (m['avg_duration_sec'] as num?)?.toDouble() ?? 0,
    engagedSessions: (m['engaged_sessions'] as num?)?.toInt() ?? 0,
    engagementRate: (m['engagement_rate'] as num?)?.toDouble() ?? 0,
  );
}

class FeatureEventRow {
  final String name;
  final int count;
  final int uniqueUsers;
  final double perSession;

  const FeatureEventRow({
    required this.name,
    required this.count,
    required this.uniqueUsers,
    required this.perSession,
  });

  factory FeatureEventRow.fromMap(Map<String, dynamic> m) => FeatureEventRow(
    name: m['name'] as String? ?? '',
    count: (m['count'] as num?)?.toInt() ?? 0,
    uniqueUsers: (m['unique_users'] as num?)?.toInt() ?? 0,
    perSession: (m['per_session'] as num?)?.toDouble() ?? 0,
  );

  String get displayName {
    const labels = <String, String>{
      // Finanzas
      'expense_added': 'Registrar gasto',
      'income_added': 'Registrar ingreso',
      'transaction_categorized': 'Categorizar transacción',
      'account_connected': 'Conectar cuenta',
      'feature_import_transactions_used': 'Importar transacciones',
      // Presupuesto / Metas
      'budget_created': 'Crear presupuesto',
      'category_created': 'Crear categoría',
      'goal_created': 'Crear meta',
      'report_viewed': 'Ver reporte',
      // Voz
      'feature_voice_expense_used': 'Voz — registrar gasto',
      'voice_entry_used': 'Entrada por voz',
      // Widget
      'widget_entry_used': 'Widget rápido',
      // Suscripción
      'subscription_tracked': 'Rastrear suscripción',
      'subscription_restored': 'Restaurar suscripción',
      'app_store_subscription_renew': 'Renovación suscripción',
      'app_store_subscription_convert': 'Conversión suscripción',
      // Conversión
      'paywall_viewed': 'Vio el paywall',
      'trial_started': 'Inició prueba',
      'purchase': 'Compra realizada',
      'purchase_cancelled': 'Compra cancelada',
      'plan_selected': 'Seleccionó plan',
      'in_app_purchase': 'Compra in-app',
      // Auth
      'sign_up': 'Registro',
      'login': 'Inicio de sesión',
      // Onboarding
      'tutorial_begin': 'Onboarding iniciado',
      'tutorial_complete': 'Onboarding completado',
      'onboarding_step': 'Paso de onboarding',
      // Notificaciones
      'notification_open': 'Notificación abierta',
      'notification_foreground': 'Notificación recibida',
    };
    return labels[name] ??
        name
            .split('_')
            .map(
              (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');
  }

  FeatureCategory get category {
    if (const {
      'expense_added', 'income_added', 'transaction_categorized',
      'account_connected', 'feature_import_transactions_used',
    }.contains(name)) { return FeatureCategory.financial; }
    if (const {
      'budget_created', 'category_created', 'goal_created', 'report_viewed',
    }.contains(name)) { return FeatureCategory.budget; }
    if (const {'feature_voice_expense_used', 'voice_entry_used'}.contains(name)) {
      return FeatureCategory.voice;
    }
    if (name == 'widget_entry_used') { return FeatureCategory.widget; }
    if (const {
      'subscription_tracked', 'subscription_restored',
      'app_store_subscription_renew', 'app_store_subscription_convert',
    }.contains(name)) { return FeatureCategory.subscription; }
    if (const {
      'paywall_viewed', 'trial_started', 'purchase',
      'purchase_cancelled', 'plan_selected', 'in_app_purchase',
    }.contains(name)) { return FeatureCategory.conversion; }
    if (const {'sign_up', 'login'}.contains(name)) { return FeatureCategory.auth; }
    if (const {
      'tutorial_begin', 'tutorial_complete', 'onboarding_step',
    }.contains(name)) { return FeatureCategory.onboarding; }
    if (const {'notification_open', 'notification_foreground'}.contains(name)) {
      return FeatureCategory.notification;
    }
    return FeatureCategory.other;
  }
}

enum FeatureCategory {
  financial,
  budget,
  voice,
  widget,
  subscription,
  conversion,
  auth,
  onboarding,
  notification,
  other,
}

class FeatureRetentionRow {
  final String name;
  final int d1Users;
  final int d7Users;
  final int d30Users;
  final double retentionScore;

  const FeatureRetentionRow({
    required this.name,
    required this.d1Users,
    required this.d7Users,
    required this.d30Users,
    required this.retentionScore,
  });

  factory FeatureRetentionRow.fromMap(Map<String, dynamic> m) =>
      FeatureRetentionRow(
        name: m['name'] as String? ?? '',
        d1Users: (m['d1_users'] as num?)?.toInt() ?? 0,
        d7Users: (m['d7_users'] as num?)?.toInt() ?? 0,
        d30Users: (m['d30_users'] as num?)?.toInt() ?? 0,
        retentionScore: (m['retention_score'] as num?)?.toDouble() ?? 0,
      );
}
