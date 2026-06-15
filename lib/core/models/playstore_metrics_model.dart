class PlayStoreMetrics {
  const PlayStoreMetrics({
    this.rating = 0.0,
    this.totalReviews = 0,
    this.storeVisitors = 0,
    this.conversionRate = 0.0,
    this.estimatedInstalls = 0,
    this.crashRate = 0.0,
    this.crashAffectedUsers = 0,
    this.anrRate = 0.0,
    this.updatedAtLabel = '',
  });

  final double rating;
  final int totalReviews;
  final int storeVisitors;
  final double conversionRate;
  final int estimatedInstalls;
  final double crashRate;
  final int crashAffectedUsers;
  final double anrRate;
  final String updatedAtLabel;

  factory PlayStoreMetrics.fromMap(Map<String, dynamic> map) {
    return PlayStoreMetrics(
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (map['total_reviews'] as num?)?.toInt() ?? 0,
      storeVisitors: (map['store_visitors'] as num?)?.toInt() ?? 0,
      conversionRate: (map['conversion_rate'] as num?)?.toDouble() ?? 0.0,
      estimatedInstalls: (map['estimated_installs'] as num?)?.toInt() ?? 0,
      crashRate: (map['crash_rate'] as num?)?.toDouble() ?? 0.0,
      crashAffectedUsers: (map['crash_affected_users'] as num?)?.toInt() ?? 0,
      anrRate: (map['anr_rate'] as num?)?.toDouble() ?? 0.0,
      updatedAtLabel: map['updated_at_label'] as String? ?? '',
    );
  }

  String get ratingStr =>
      rating > 0 ? rating.toStringAsFixed(1) : '—';

  String get conversionStr =>
      conversionRate > 0
          ? '${(conversionRate * 100).toStringAsFixed(1)}%'
          : '—';

  String get crashRateStr =>
      crashRate > 0 ? '${crashRate.toStringAsFixed(2)}%' : '—';

  String get anrRateStr =>
      anrRate > 0 ? '${anrRate.toStringAsFixed(2)}%' : '—';

  String get estimatedInstallsStr =>
      estimatedInstalls > 0 ? '$estimatedInstalls' : '—';

  String get storeVisitorsStr =>
      storeVisitors > 0 ? '$storeVisitors' : '—';

  bool get hasData => storeVisitors > 0 || rating > 0 || estimatedInstalls > 0;
}
