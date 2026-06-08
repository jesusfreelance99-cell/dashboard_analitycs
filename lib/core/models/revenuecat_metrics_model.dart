import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';

class RevenueCatMetrics {
  const RevenueCatMetrics({
    required this.currency,
    required this.status,
    required this.source,
    required this.updatedAtLabel,
    required this.overview,
    required this.ranges,
  });

  final String currency;
  final String status;
  final String source;
  final String updatedAtLabel;
  final RevenueCatOverviewMetrics overview;
  final Map<DateRange, RevenueCatRangeMetrics> ranges;

  factory RevenueCatMetrics.fromMap(Map<String, dynamic> map) {
    final rangeMap = (map['ranges'] as Map<String, dynamic>? ?? const {});

    return RevenueCatMetrics(
      currency: map['currency'] as String? ?? 'USD',
      status: map['status'] as String? ?? 'idle',
      source: map['source'] as String? ?? 'RevenueCat',
      updatedAtLabel: map['updated_at_label'] as String? ?? '',
      overview: RevenueCatOverviewMetrics.fromMap(
        map['overview'] as Map<String, dynamic>? ?? const {},
      ),
      ranges: {
        DateRange.d7: RevenueCatRangeMetrics.fromMap(
          rangeMap['d7'] as Map<String, dynamic>? ?? const {},
        ),
        DateRange.d30: RevenueCatRangeMetrics.fromMap(
          rangeMap['d30'] as Map<String, dynamic>? ?? const {},
        ),
        DateRange.d90: RevenueCatRangeMetrics.fromMap(
          rangeMap['d90'] as Map<String, dynamic>? ?? const {},
        ),
        DateRange.all: RevenueCatRangeMetrics.fromMap(
          rangeMap['all'] as Map<String, dynamic>? ?? const {},
        ),
      },
    );
  }

  RevenueCatRangeMetrics range(DateRange dateRange) {
    return ranges[dateRange] ?? const RevenueCatRangeMetrics();
  }
}

class RevenueCatOverviewMetrics {
  const RevenueCatOverviewMetrics({
    this.mrr = 0,
    this.activeTrials = 0,
    this.activeSubscriptions = 0,
    this.revenue28d = 0,
    this.newCustomers28d = 0,
    this.activeCustomers28d = 0,
  });

  final double mrr;
  final int activeTrials;
  final int activeSubscriptions;
  final double revenue28d;
  final int newCustomers28d;
  final int activeCustomers28d;

  factory RevenueCatOverviewMetrics.fromMap(Map<String, dynamic> map) {
    return RevenueCatOverviewMetrics(
      mrr: (map['mrr'] as num?)?.toDouble() ?? 0,
      activeTrials: (map['active_trials'] as num?)?.toInt() ?? 0,
      activeSubscriptions: (map['active_subscriptions'] as num?)?.toInt() ?? 0,
      revenue28d: (map['revenue_28d'] as num?)?.toDouble() ?? 0,
      newCustomers28d: (map['new_customers_28d'] as num?)?.toInt() ?? 0,
      activeCustomers28d: (map['active_customers_28d'] as num?)?.toInt() ?? 0,
    );
  }

  String get mrrLabel => RevenueCatRangeMetrics.formatCurrency(mrr);
  String get activeTrialsLabel =>
      RevenueCatRangeMetrics.formatInteger(activeTrials);
  String get activeSubscriptionsLabel =>
      RevenueCatRangeMetrics.formatInteger(activeSubscriptions);
  String get revenue28dLabel =>
      RevenueCatRangeMetrics.formatCurrency(revenue28d);
  String get newCustomers28dLabel =>
      RevenueCatRangeMetrics.formatInteger(newCustomers28d);
  String get activeCustomers28dLabel =>
      RevenueCatRangeMetrics.formatInteger(activeCustomers28d);
}

class RevenueCatDailyPoint {
  final String date;
  final double revenue;

  const RevenueCatDailyPoint({required this.date, required this.revenue});

  factory RevenueCatDailyPoint.fromMap(Map<String, dynamic> m) {
    return RevenueCatDailyPoint(
      date: m['date'] as String? ?? '',
      revenue: (m['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RevenueCatRangeMetrics {
  const RevenueCatRangeMetrics({
    this.mrr = 0,
    this.revenue = 0,
    this.activeSubscriptions = 0,
    this.activeTrials = 0,
    this.churn = 0,
    this.newCustomers = 0,
    this.activeCustomers = 0,
    this.revenueBars = const [42, 68, 88, 124, 98],
    this.timeSeries = const [],
    this.periodLabel = '',
  });

  final double mrr;
  final double revenue;
  final int activeSubscriptions;
  final int activeTrials;
  final double churn;
  final int newCustomers;
  final int activeCustomers;
  final List<double> revenueBars;
  final List<RevenueCatDailyPoint> timeSeries;
  final String periodLabel;

  factory RevenueCatRangeMetrics.fromMap(Map<String, dynamic> map) {
    final rawBars = (map['revenue_bars'] as List<dynamic>? ?? const [])
        .map((item) => (item as num?)?.toDouble() ?? 0)
        .toList();

    final rawSeries = map['revenue_time_series'] as List<dynamic>? ?? const [];

    return RevenueCatRangeMetrics(
      mrr: (map['mrr'] as num?)?.toDouble() ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0,
      activeSubscriptions: (map['active_subscriptions'] as num?)?.toInt() ?? 0,
      activeTrials: (map['active_trials'] as num?)?.toInt() ?? 0,
      churn: (map['churn'] as num?)?.toDouble() ?? 0,
      newCustomers: (map['new_customers'] as num?)?.toInt() ?? 0,
      activeCustomers: (map['active_customers'] as num?)?.toInt() ?? 0,
      revenueBars: rawBars.isEmpty ? const [42, 68, 88, 124, 98] : rawBars,
      timeSeries: rawSeries
          .whereType<Map<String, dynamic>>()
          .map(RevenueCatDailyPoint.fromMap)
          .toList(),
      periodLabel: map['period_label'] as String? ?? '',
    );
  }

  String get mrrLabel => formatCurrency(mrr);
  String get revenueLabel => formatCurrency(revenue);
  String get activeSubscriptionsLabel => formatInteger(activeSubscriptions);
  String get activeTrialsLabel => formatInteger(activeTrials);
  String get newCustomersLabel => formatInteger(newCustomers);
  String get activeCustomersLabel => formatInteger(activeCustomers);

  String get churnLabel {
    final percent = churn <= 1 ? churn * 100 : churn;
    if (percent <= 0) return '—';
    return '${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}%';
  }

  static String formatCurrency(double value) {
    if (value <= 0) return '—';
    final rounded = value >= 100
        ? value.round().toString()
        : value.toStringAsFixed(0);
    return '\$$rounded';
  }

  static String formatInteger(int value) {
    if (value <= 0) return '0';
    return value.toString();
  }
}
