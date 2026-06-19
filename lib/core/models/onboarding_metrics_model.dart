import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';

class OnboardingMetrics {
  final String status;
  final String updatedAtLabel;
  final Map<DateRange, OnboardingRangeData> ranges;

  const OnboardingMetrics({
    required this.status,
    required this.updatedAtLabel,
    required this.ranges,
  });

  static const empty = OnboardingMetrics(status: 'idle', updatedAtLabel: '', ranges: {});

  OnboardingRangeData? range(DateRange r) => ranges[r];

  factory OnboardingMetrics.fromMap(Map<String, dynamic> map) {
    final raw = map['ranges'] as Map<String, dynamic>? ?? {};
    return OnboardingMetrics(
      status: map['status'] as String? ?? 'idle',
      updatedAtLabel: map['updated_at_label'] as String? ?? '',
      ranges: {
        DateRange.d7:  OnboardingRangeData.fromMap(raw['d7']  as Map<String, dynamic>? ?? {}),
        DateRange.d30: OnboardingRangeData.fromMap(raw['d30'] as Map<String, dynamic>? ?? {}),
        DateRange.d90: OnboardingRangeData.fromMap(raw['d90'] as Map<String, dynamic>? ?? {}),
        DateRange.all: OnboardingRangeData.fromMap(raw['all'] as Map<String, dynamic>? ?? {}),
      },
    );
  }
}

class OnboardingRangeData {
  final int totalStarted;
  final int totalCompleted;
  final double completionRate;
  final int maxDropoffStep;
  final List<OnboardingFunnelStep> steps;
  final List<OnboardingAnswerGroup> answers;

  const OnboardingRangeData({
    this.totalStarted = 0,
    this.totalCompleted = 0,
    this.completionRate = 0,
    this.maxDropoffStep = 0,
    this.steps = const [],
    this.answers = const [],
  });

  bool get hasData => totalStarted > 0;

  factory OnboardingRangeData.fromMap(Map<String, dynamic> m) {
    final stepsRaw   = (m['steps']   as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
    final answersRaw = (m['answers'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
    return OnboardingRangeData(
      totalStarted:    (m['total_started']    as num?)?.toInt() ?? 0,
      totalCompleted:  (m['total_completed']  as num?)?.toInt() ?? 0,
      completionRate:  (m['completion_rate']  as num?)?.toDouble() ?? 0,
      maxDropoffStep:  (m['max_dropoff_step'] as num?)?.toInt() ?? 0,
      steps:   stepsRaw.map(OnboardingFunnelStep.fromMap).toList(),
      answers: answersRaw.map(OnboardingAnswerGroup.fromMap).toList(),
    );
  }

  OnboardingAnswerGroup? answersForStep(int stepNumber) {
    try {
      return answers.firstWhere((a) => a.stepNumber == stepNumber);
    } catch (_) {
      return null;
    }
  }
}

class OnboardingFunnelStep {
  final int stepNumber;
  final String stepName;
  final String questionEs;
  final int uniqueUsers;
  final int eventCount;
  final double pctOfStart;
  final double dropPct;

  const OnboardingFunnelStep({
    required this.stepNumber,
    required this.stepName,
    required this.questionEs,
    required this.uniqueUsers,
    required this.eventCount,
    required this.pctOfStart,
    required this.dropPct,
  });

  factory OnboardingFunnelStep.fromMap(Map<String, dynamic> m) => OnboardingFunnelStep(
    stepNumber:  (m['step_number']  as num?)?.toInt() ?? 0,
    stepName:    m['step_name']     as String? ?? '',
    questionEs:  m['question_es']   as String? ?? '',
    uniqueUsers: (m['unique_users'] as num?)?.toInt() ?? 0,
    eventCount:  (m['event_count']  as num?)?.toInt() ?? 0,
    pctOfStart:  (m['pct_of_start'] as num?)?.toDouble() ?? 0,
    dropPct:     (m['drop_pct']     as num?)?.toDouble() ?? 0,
  );

  String get pctLabel => uniqueUsers > 0 ? '${(pctOfStart * 100).toStringAsFixed(0)}%' : '—';
  String get dropLabel => dropPct > 0 ? '−${(dropPct * 100).toStringAsFixed(0)}%' : '';
}

class OnboardingAnswerGroup {
  final int stepNumber;
  final String questionKey;
  final String questionEs;
  final List<OnboardingAnswerOption> options;

  const OnboardingAnswerGroup({
    required this.stepNumber,
    required this.questionKey,
    required this.questionEs,
    required this.options,
  });

  factory OnboardingAnswerGroup.fromMap(Map<String, dynamic> m) {
    final opts = (m['options'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
    return OnboardingAnswerGroup(
      stepNumber:  (m['step_number']  as num?)?.toInt() ?? 0,
      questionKey: m['question_key'] as String? ?? '',
      questionEs:  m['question_es']  as String? ?? '',
      options:     opts.map(OnboardingAnswerOption.fromMap).toList(),
    );
  }
}

class OnboardingAnswerOption {
  final String answer;
  final int uniqueUsers;
  final double pct;

  const OnboardingAnswerOption({
    required this.answer,
    required this.uniqueUsers,
    required this.pct,
  });

  factory OnboardingAnswerOption.fromMap(Map<String, dynamic> m) => OnboardingAnswerOption(
    answer:      m['answer']       as String? ?? '',
    uniqueUsers: (m['unique_users'] as num?)?.toInt() ?? 0,
    pct:         (m['pct']          as num?)?.toDouble() ?? 0,
  );

  String get pctLabel => '${(pct * 100).toStringAsFixed(0)}%';
}
