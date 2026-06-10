class NewVsReturningPoint {
  final String date; // "YYYYMMDD"
  final int newUsers;
  final int returningUsers;

  const NewVsReturningPoint({
    required this.date,
    required this.newUsers,
    required this.returningUsers,
  });

  factory NewVsReturningPoint.fromMap(Map<String, dynamic> m) =>
      NewVsReturningPoint(
        date: m['date'] as String? ?? '',
        newUsers: (m['new_users'] as num?)?.toInt() ?? 0,
        returningUsers: (m['returning_users'] as num?)?.toInt() ?? 0,
      );
}

class RetentionCurvePoint {
  final int day;
  final double rate; // 0.0 – 1.0

  const RetentionCurvePoint({required this.day, required this.rate});

  factory RetentionCurvePoint.fromMap(Map<String, dynamic> m) =>
      RetentionCurvePoint(
        day: (m['day'] as num?)?.toInt() ?? 0,
        rate: (m['rate'] as num?)?.toDouble() ?? 0.0,
      );
}

class EngagementPoint {
  final String date; // "YYYYMMDD"
  final double avgSessionSec;

  const EngagementPoint({required this.date, required this.avgSessionSec});

  factory EngagementPoint.fromMap(Map<String, dynamic> m) => EngagementPoint(
    date: m['date'] as String? ?? '',
    avgSessionSec: (m['avg_session_sec'] as num?)?.toDouble() ?? 0.0,
  );
}

class LtvPoint {
  final int day;
  final double avgRevenue;

  const LtvPoint({required this.day, required this.avgRevenue});

  factory LtvPoint.fromMap(Map<String, dynamic> m) => LtvPoint(
    day: (m['day'] as num?)?.toInt() ?? 0,
    avgRevenue: (m['avg_revenue'] as num?)?.toDouble() ?? 0.0,
  );
}

class RetentionMetrics {
  final String status;
  final String updatedAtLabel;
  final List<NewVsReturningPoint> newVsReturning;
  final List<RetentionCurvePoint> retentionCurve;
  final List<EngagementPoint> engagementSeries;
  final List<LtvPoint> ltvCurve;

  const RetentionMetrics({
    required this.status,
    required this.updatedAtLabel,
    this.newVsReturning = const [],
    this.retentionCurve = const [],
    this.engagementSeries = const [],
    this.ltvCurve = const [],
  });

  static const empty = RetentionMetrics(status: 'idle', updatedAtLabel: '');

  factory RetentionMetrics.fromMap(Map<String, dynamic> map) => RetentionMetrics(
    status: map['status'] as String? ?? 'idle',
    updatedAtLabel: map['updated_at_label'] as String? ?? '',
    newVsReturning: (map['new_vs_returning'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NewVsReturningPoint.fromMap)
        .toList(),
    retentionCurve: (map['retention_curve'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RetentionCurvePoint.fromMap)
        .toList(),
    engagementSeries: (map['engagement_series'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(EngagementPoint.fromMap)
        .toList(),
    ltvCurve: (map['ltv_curve'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LtvPoint.fromMap)
        .toList(),
  );
}
