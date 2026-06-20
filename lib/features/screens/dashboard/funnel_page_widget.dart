import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/models/appstore_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/funnel_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/onboarding_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/revenuecat_metrics_model.dart';
import 'package:dashboard_analitycs/core/services/appstore_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/funnel_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/onboarding_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/revenuecat_metrics_service.dart';
import 'package:dashboard_analitycs/core/widgets/app_shimmer.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:flutter/material.dart';

import 'shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class FunnelPage extends StatelessWidget {
  const FunnelPage({super.key, required this.range});
  final DateRange range;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FunnelMetrics?>(
      stream: FunnelMetricsService.stream(),
      builder: (context, funnelSnap) {
        return StreamBuilder<RevenueCatMetrics?>(
          stream: RevenueCatMetricsService.stream(),
          builder: (context, rcSnap) {
            return StreamBuilder<AppStoreMetrics?>(
              stream: AppStoreMetricsService.stream(),
              builder: (context, asSnap) {
                return StreamBuilder<OnboardingMetrics?>(
                  stream: OnboardingMetricsService.stream(),
                  builder: (context, onbSnap) {
                    if (funnelSnap.connectionState == ConnectionState.waiting &&
                        funnelSnap.data == null) {
                      return const _FunnelShimmer();
                    }
                    return _FunnelContent(
                      range: range,
                      funnel: funnelSnap.data,
                      rc: rcSnap.data,
                      appStore: asSnap.data,
                      onboarding: onbSnap.data,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _FunnelContent extends StatelessWidget {
  const _FunnelContent({
    required this.range,
    required this.funnel,
    required this.rc,
    required this.appStore,
    required this.onboarding,
  });

  final DateRange range;
  final FunnelMetrics? funnel;
  final RevenueCatMetrics? rc;
  final AppStoreMetrics? appStore;
  final OnboardingMetrics? onboarding;

  FunnelEvent? _findEvent(List<FunnelEvent> events, List<String> names) {
    for (final name in names) {
      try {
        return events.firstWhere((e) => e.name.toLowerCase() == name.toLowerCase());
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fRange = funnel?.range(range);
    final events = fRange?.events ?? [];
    final rcOverview = rc?.overview;

    // Descargas — App Store Connect
    final downloads = appStore?.downloadsLastMonth ?? 0;

    // Paso 2 — App abierta (app_open = cada arranque de la app, main.dart:37)
    final appOpenedE = _findEvent(events, ['app_open', 'first_open']);
    final appOpened = appOpenedE?.count ?? fRange?.appOpenCount ?? 0;
    final appOpenedUniq = appOpenedE?.uniqueUsers ?? fRange?.appOpenUnique ?? 0;

    // Card resumen — "Iniciaron onboarding" usa tutorial_begin (quien empezó)
    final onbBeginE = _findEvent(events, ['tutorial_begin', 'onboarding_step']);
    final onbBegin = onbBeginE?.count ?? fRange?.tutorialBeginCount ?? 0;
    final onbBeginUniq = onbBeginE?.uniqueUsers ?? fRange?.tutorialBeginUnique ?? 0;

    // Paso del embudo — "Onboarding completado" (usado cuando el embudo se reactive)
    // final onbE = _findEvent(events, ['tutorial_complete', 'tutorial_begin', 'onboarding_step']);
    // final onbCount = onbE?.count ?? 0;
    // final onboardingUniq = onbE?.uniqueUsers ?? 0;

    // Paso 4 — Registro / Login
    // sign_up = nuevo usuario registrado; login = inicio de sesión existente
    // final loginE = _findEvent(events, ['sign_up', 'login']);
    // final login = loginE?.count ?? 0;
    // final loginUniq = loginE?.uniqueUsers ?? 0;

    // Paso 6 — Trial
    final trialCount = fRange?.uniqueTrial ?? 0;
    final trialE = _findEvent(events, ['trial_started']);
    final trial = trialE?.count ?? trialCount;

    // Paso 7 — Suscripción comprada
    // ecommerce_purchase = evento estándar Firebase que manda la app; purchase como fallback
    final subE = _findEvent(events, [
      'ecommerce_purchase', 'purchase', 'app_store_subscription_convert', 'in_app_purchase',
    ]);
    final subscriptions = subE?.count ?? rcOverview?.activeSubscriptions ?? 0;

    // % conversión del free trial
    final trialConvPct = trial > 0 && subscriptions > 0
        ? (subscriptions / trial * 100).toStringAsFixed(0)
        : null;

    // % trials cancelados
    final trialsTotal = rc?.range(DateRange.all).activeTrials ?? 0;
    final trialsActive = rcOverview?.activeTrials ?? 0;
    final trialsCancelled = (trialsTotal - trialsActive).clamp(0, 999999);

    // EMBUDO COMPLETO temporalmente oculto — descomentar junto con el Panel de abajo
    // final obSteps = onboarding?.range(range)?.steps ?? [];
    // const obColors = [
    //   AppColors.chartBlue,   AppColors.chartGreen,  AppColors.chartPurple,
    //   AppColors.pink,        AppColors.chartAmber,  AppColors.chartOlive,
    //   AppColors.chartBlue,   AppColors.chartGreen,  AppColors.chartPurple,
    //   AppColors.pink,        AppColors.chartAmber,  AppColors.chartOlive,
    //   AppColors.chartBlue,   AppColors.chartGreen,  AppColors.success,
    // ];
    // var stepNum = 1;
    // final steps = <_FStep>[
    //   _FStep(num: stepNum++, eventCode: 'first_open', label: 'Primera apertura de la app',
    //     count: appOpened, unique: appOpenedUniq > 0 ? appOpenedUniq : null,
    //     baseline: baseline, color: AppColors.chartBlue, event: appOpenedE,
    //     extraInfo: downloads > 0 ? '↓ $downloads descargas iOS' : null,
    //   ),
    //   if (obSteps.isNotEmpty)
    //     for (final s in obSteps)
    //       _FStep(num: stepNum++, eventCode: 'onboarding_step_${s.stepNumber}',
    //         label: s.questionEs, count: s.uniqueUsers,
    //         unique: s.uniqueUsers > 0 ? s.uniqueUsers : null, baseline: baseline,
    //         color: obColors[(s.stepNumber - 1).clamp(0, obColors.length - 1)],
    //       )
    //   else
    //     _FStep(num: stepNum++, eventCode: 'tutorial_complete', label: 'Onboarding completado',
    //       count: onbCount, unique: onboardingUniq > 0 ? onboardingUniq : null,
    //       baseline: baseline, color: AppColors.chartGreen, event: onbE,
    //       subSteps: fRange?.onboardingSteps ?? [],
    //     ),
    //   _FStep(num: stepNum++, eventCode: 'sign_up', label: 'Registro completado',
    //     count: login, unique: loginUniq > 0 ? loginUniq : null,
    //     baseline: baseline, color: AppColors.chartPurple, event: loginE,
    //   ),
    //   _FStep(num: stepNum++, eventCode: 'paywall_viewed', label: 'Paywall vista',
    //     count: paywall, unique: paywallUniq > 0 ? paywallUniq : null,
    //     baseline: baseline, color: AppColors.pink, event: paywallE,
    //   ),
    //   _FStep(num: stepNum++, eventCode: 'trial_started', label: 'Free trial iniciado',
    //     count: trial, unique: trialUniq > 0 ? trialUniq : null,
    //     baseline: baseline, color: AppColors.chartAmber, event: trialE,
    //   ),
    //   _FStep(num: stepNum++, eventCode: 'ecommerce_purchase', label: 'Suscripción comprada',
    //     count: subscriptions, unique: subscriptionsUniq > 0 ? subscriptionsUniq : null,
    //     baseline: baseline, color: AppColors.success, event: subE,
    //   ),
    // ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // ── 6 CARDS ──────────────────────────────────────────────────────────
        Row(
          children: const [
            Expanded(
              child: SectionHeader(
                label: 'RESUMEN DEL PERÍODO',
                source: 'App Store · Firebase · RevenueCat',
              ),
            ),
            _FunnelRefreshButton(),
          ],
        ),
        const SizedBox(height: 14),
        ResponsiveGrid(
          minTileWidth: 220,
          children: [
            MetricCard(
              label: 'Descargas',
              value: downloads > 0 ? '$downloads' : '—',
              helperText: 'App Store Connect · último mes',
            ),
            MetricCard(
              label: 'Abrieron la app',
              value: appOpened > 0 ? '$appOpened' : '—',
              helperText: appOpenedUniq > 0 ? '$appOpenedUniq únicos · app_open' : 'Firebase · app_open',
            ),
            MetricCard(
              label: 'Iniciaron onboarding',
              value: onbBegin > 0 ? '$onbBegin' : '—',
              helperText: onbBeginUniq > 0 ? '$onbBeginUniq únicos · tutorial_begin' : 'tutorial_begin',
            ),
            MetricCard(
              label: 'Iniciaron free trial',
              value: trial > 0 ? '$trial' : '—',
              helperText: 'trial_started',
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── CARD DESTACADA — % conversión del trial ───────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.pinkLight,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '% de conversión del free trial',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      trialConvPct != null ? '$trialConvPct%' : '—',
                      style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w800,
                        letterSpacing: -1.5, height: 1, color: AppColors.pink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                subscriptions > 0 && trial > 0
                    ? '$subscriptions suscriptores\nde $trial trials iniciados'
                    : 'suscriptores que vinieron\ndel free trial',
                style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.ink2),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        const SizedBox(height: 42),

        // ── EMBUDO COMPLETO · EVENTOS MIXPANEL (temporalmente oculto) ────────
        // Row(
        //   children: [
        //     const Expanded(
        //       child: SectionHeader(
        //         label: 'EMBUDO COMPLETO · EVENTOS MIXPANEL',
        //         source: 'Firebase Analytics · RevenueCat',
        //       ),
        //     ),
        //     const _FunnelRefreshButton(),
        //   ],
        // ),
        // const SizedBox(height: 14),
        // Panel(
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       const PanelHeader(
        //         title: 'Embudo completo · eventos Mixpanel',
        //         trailing: 'toca un paso para ver detalles',
        //         badge: 'Mixpanel',
        //       ),
        //       const SizedBox(height: 28),
        //       for (int i = 0; i < steps.length; i++) ...[
        //         _FunnelStepRow(
        //           step: steps[i],
        //           funnel: funnel,
        //           currentRange: range,
        //           isLast: i == steps.length - 1,
        //         ),
        //         if (i < steps.length - 1)
        //           Padding(
        //             padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
        //             child: Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.ink3),
        //           ),
        //       ],
        //     ],
        //   ),
        // ),
        // const SizedBox(height: 42),

        // ── RESUMEN TRIALS ────────────────────────────────────────────────────
        const SectionHeader(label: 'ESTADO DE TRIALS', source: 'RevenueCat'),
        const SizedBox(height: 14),
        ResponsiveGrid(
          minTileWidth: 220,
          children: [
            MetricCard(
              label: 'Trials iniciados (acumulado)',
              value: trialsTotal > 0 ? '$trialsTotal' : '—',
              helperText: 'histórico total',
            ),
            MetricCard(
              label: 'Trials activos ahora',
              value: trialsActive > 0 ? '$trialsActive' : '—',
              helperText: 'en período de prueba',
            ),
            MetricCard(
              label: 'Trials cancelados',
              value: trialsCancelled > 0 ? '$trialsCancelled' : '—',
              accent: trialsCancelled > 0,
              helperText: 'cancelaron durante la prueba',
            ),
            MetricCard(
              label: '% cancelados',
              value: trialsTotal > 0 && trialsCancelled > 0
                  ? '${(trialsCancelled / trialsTotal * 100).toStringAsFixed(0)}%'
                  : '—',
              accent: trialsCancelled > 0,
              helperText: 'cancelados / total iniciados',
            ),
          ],
        ),
        const SizedBox(height: 48),

        // ── FUNNEL DE ONBOARDING · QUIZ (BigQuery) ────────────────────────────
        _OnboardingSection(
          data: onboarding?.range(range),
          onboarding: onboarding,
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FUNNEL STEP DATA
// ─────────────────────────────────────────────────────────────────────────────

class _FStep {
  const _FStep({
    required this.num,
    required this.eventCode,
    required this.label,
    required this.count,
    required this.unique,
    required this.baseline,
    required this.color,
    // ignore: unused_element_parameter
    this.event,
    // ignore: unused_element_parameter
    this.extraInfo,
    // ignore: unused_element_parameter
    this.subSteps = const [],
  });

  final int num;
  final String eventCode;
  final String label;
  final int count;
  final int? unique;
  final int baseline;
  final Color color;
  final FunnelEvent? event;
  final String? extraInfo;
  final List<OnboardingStep> subSteps;

  double get fraction => baseline > 0 && count > 0 ? (count / baseline).clamp(0.0, 1.0) : 0;
  String get pctStr => count > 0 ? '${(fraction * 100).toStringAsFixed(0)}%' : '—';
}

// ─────────────────────────────────────────────────────────────────────────────
// FUNNEL STEP ROW
// ─────────────────────────────────────────────────────────────────────────────

class _FunnelStepRow extends StatefulWidget {
  const _FunnelStepRow({
    required this.step,
    required this.funnel,
    required this.currentRange,
    required this.isLast,
  });

  final _FStep step;
  final FunnelMetrics? funnel;
  final DateRange currentRange;
  final bool isLast;

  @override
  State<_FunnelStepRow> createState() => _FunnelStepRowState();
}

class _FunnelStepRowState extends State<_FunnelStepRow> {
  bool _expanded = false;

  void _openDetail() {
    final step = widget.step;
    if (step.event == null || widget.funnel == null) return;
    showDialog(
      context: context,
      barrierColor: AppColors.ink.withAlpha(80),
      builder: (_) => _EventDetailDialog(
        funnel: widget.funnel!,
        event: step.event!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final hasData = step.count > 0;
    final hasSubSteps = step.subSteps.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: hasSubSteps
                ? () => setState(() => _expanded = !_expanded)
                : (step.event != null ? _openDetail : null),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${step.num}',
                          style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.eventCode,
                              style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: AppColors.ink2, fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              step.label,
                              style: const TextStyle(fontSize: 13, color: AppColors.ink3),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          hasData ? '${step.count}' : '—',
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: hasData ? AppColors.ink : AppColors.ink3,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          step.unique != null ? '${step.unique} únicos' : (step.extraInfo ?? ''),
                          style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          step.pctStr,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: hasData ? step.color : AppColors.ink3,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 22,
                        child: hasSubSteps
                            ? Icon(
                                _expanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 16,
                                color: AppColors.ink3,
                              )
                            : (step.event != null
                                ? const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.ink3)
                                : const SizedBox()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: step.fraction,
                        minHeight: 10,
                        backgroundColor: AppColors.progressBg,
                        valueColor: AlwaysStoppedAnimation(
                          hasData ? step.color : AppColors.shimmerBase,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sub-detalle colapsable — pasos de onboarding
          if (hasSubSteps && _expanded) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in step.subSteps)
                    _OnboardingSubRow(
                      step: s,
                      total: step.count > 0 ? step.count : 1,
                      color: step.color,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingSubRow extends StatelessWidget {
  const _OnboardingSubRow({
    required this.step,
    required this.total,
    required this.color,
  });

  final OnboardingStep step;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (step.count / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  step.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Text(
                '${step.count}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.progressBg,
              valueColor: AlwaysStoppedAnimation(color.withAlpha(160)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENT DETAIL DIALOG (tap en un paso del embudo)
// ─────────────────────────────────────────────────────────────────────────────

class _EventDetailDialog extends StatelessWidget {
  const _EventDetailDialog({required this.funnel, required this.event});
  final FunnelMetrics funnel;
  final FunnelEvent event;

  FunnelEvent? _inRange(DateRange r) {
    final events = funnel.range(r)?.events ?? [];
    try {
      return events.firstWhere((e) => e.name == event.name);
    } catch (_) {
      return null;
    }
  }

  Color _color() {
    if (event.name == 'paywall_viewed') return AppColors.chartAmber;
    if (event.name == 'trial_started') return AppColors.danger;
    if (event.name == 'subscription_purchased') return AppColors.success;
    if (event.name.contains('login') || event.name.contains('sesion')) return AppColors.pink;
    if (event.name.contains('onboarding')) return AppColors.chartPurple;
    return AppColors.chartBlue;
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final d7  = _inRange(DateRange.d7);
    final d30 = _inRange(DateRange.d30);
    final d90 = _inRange(DateRange.d90);
    final all = _inRange(DateRange.all) ?? event;
    final allCount = all.count > 0 ? all.count : event.count;
    final ratio = event.uniqueUsers > 0 ? event.count / event.uniqueUsers : 0.0;
    final hasTrend = d7 != null && d30 != null && d30.count > 0;
    final isTrendingUp = hasTrend && (d7.count / 7) > (d30.count / 30);
    final hasRangeData = d7 != null || d30 != null || d90 != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 10, height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Text(event.name, style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
                  ],
                )),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.ink3),
                ),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _StatTile(label: 'Ocurrencias', value: _fmt(event.count), color: color)),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(label: 'Usuarios únicos', value: _fmt(event.uniqueUsers), color: AppColors.chartBlue)),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(label: 'Por usuario', value: ratio.toStringAsFixed(1), color: AppColors.chartGreen)),
              ]),
              const SizedBox(height: 24),
              if (hasRangeData) ...[
                const Text('Actividad por período', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink3)),
                const SizedBox(height: 12),
                _RangeBar(label: '7 días',   count: d7?.count  ?? 0, maxCount: allCount, color: color),
                _RangeBar(label: '30 días',  count: d30?.count ?? 0, maxCount: allCount, color: color),
                _RangeBar(label: '90 días',  count: d90?.count ?? 0, maxCount: allCount, color: color),
                _RangeBar(label: 'Histórico', count: allCount,        maxCount: allCount, color: color),
                const SizedBox(height: 20),
              ],
              if (hasTrend)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isTrendingUp
                        ? AppColors.success.withAlpha(18)
                        : AppColors.danger.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Icon(
                      isTrendingUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 18,
                      color: isTrendingUp ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTrendingUp
                          ? 'Tendencia al alza vs el mes pasado'
                          : 'Tendencia a la baja vs el mes pasado',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: isTrendingUp ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.ink3)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.label, required this.count, required this.maxCount, required this.color});
  final String label;
  final int count;
  final int maxCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final f = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: f, minHeight: 8,
                backgroundColor: AppColors.progressBg,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              count > 0 ? '$count' : '—',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFRESH BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _FunnelRefreshButton extends StatefulWidget {
  const _FunnelRefreshButton();

  @override
  State<_FunnelRefreshButton> createState() => _FunnelRefreshButtonState();
}

class _FunnelRefreshButtonState extends State<_FunnelRefreshButton> {
  bool _loading = false;

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('dashboard_metrics').doc('funnel')
          .collection('refresh_requests')
          .add({'created_at': FieldValue.serverTimestamp()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sincronizando eventos (~30s)'),
          backgroundColor: AppColors.ink,
          duration: Duration(seconds: 4),
        ));
      }
    } catch (e) {
      log('Error al sincronizar ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al solicitar sincronización'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sincronizar desde Firebase Analytics',
      child: InkWell(
        onTap: _refresh,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pink))
              : const Icon(Icons.sync, size: 18, color: AppColors.pink),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class _FunnelShimmer extends StatelessWidget {
  const _FunnelShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const AppSkeletonBox(width: 200, height: 14, radius: 6),
          const SizedBox(height: 14),
          Row(children: const [
            Expanded(child: AppSkeletonBox(height: 100, radius: 18)),
            SizedBox(width: 12),
            Expanded(child: AppSkeletonBox(height: 100, radius: 18)),
            SizedBox(width: 12),
            Expanded(child: AppSkeletonBox(height: 100, radius: 18)),
          ]),
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(child: AppSkeletonBox(height: 100, radius: 18)),
            SizedBox(width: 12),
            Expanded(child: AppSkeletonBox(height: 100, radius: 18)),
            SizedBox(width: 12),
            Expanded(child: AppSkeletonBox(height: 100, radius: 18)),
          ]),
          const SizedBox(height: 14),
          const AppSkeletonBox(height: 80, radius: 18),
          const SizedBox(height: 42),
          const AppSkeletonBox(width: 280, height: 14, radius: 6),
          const SizedBox(height: 14),
          const AppSkeletonBox(height: 480, radius: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARDING FUNNEL SECTION (BigQuery · onboarding_step + onboarding_answer)
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingSection extends StatelessWidget {
  const _OnboardingSection({required this.data, required this.onboarding});

  final OnboardingRangeData? data;
  final OnboardingMetrics? onboarding;

  static const _stepColors = [
    AppColors.chartBlue,
    AppColors.chartGreen,
    AppColors.chartPurple,
    AppColors.pink,
    AppColors.chartAmber,
    AppColors.chartOlive,
    AppColors.chartBlue,
    AppColors.chartGreen,
    AppColors.chartPurple,
    AppColors.pink,
    AppColors.chartAmber,
    AppColors.chartOlive,
    AppColors.chartBlue,
    AppColors.chartGreen,
    AppColors.success,
  ];

  Color _colorFor(int n) => _stepColors[(n - 1).clamp(0, _stepColors.length - 1)];

  @override
  Widget build(BuildContext context) {
    final d = data;
    final hasData = d != null && d.hasData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(
          children: [
            const Expanded(
              child: SectionHeader(
                label: 'FUNNEL DE ONBOARDING · 15 PASOS',
                source: 'Firebase Analytics · onboarding_step / onboarding_answer',
              ),
            ),
            _OnboardingRefreshButton(),
          ],
        ),
        const SizedBox(height: 14),

        // ── No data notice ───────────────────────────────────────────────────
        if (!hasData)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sin datos de onboarding',
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Presiona ↻ para sincronizar datos desde Firebase Analytics.',
                  style: TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.5),
                ),
              ],
            ),
          )
        else ...[
          // ── KPI Cards ─────────────────────────────────────────────────────
          ResponsiveGrid(
            minTileWidth: 200,
            children: [
              MetricCard(
                label: 'Iniciaron quiz',
                value: '${d.totalStarted}',
                helperText: 'paso 1 · onboarding_step',
              ),
              MetricCard(
                label: 'Completaron quiz',
                value: '${d.totalCompleted}',
                helperText: 'paso 15 · personalization',
              ),
              MetricCard(
                label: '% completación',
                value: d.completionRate > 0
                    ? '${(d.completionRate * 100).toStringAsFixed(0)}%'
                    : '—',
                helperText: 'completados / iniciados',
              ),
              MetricCard(
                label: 'Mayor abandono',
                value: d.maxDropoffStep > 0 ? 'Paso ${d.maxDropoffStep}' : '—',
                accent: d.maxDropoffStep > 0,
                helperText: d.maxDropoffStep > 0 && d.steps.length >= d.maxDropoffStep
                    ? d.steps[d.maxDropoffStep - 1].stepName
                    : 'paso con más drop-off',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Updated label ────────────────────────────────────────────────
          if (onboarding?.updatedAtLabel.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Actualizado: ${onboarding!.updatedAtLabel}',
                style: const TextStyle(fontSize: 12, color: AppColors.ink3),
              ),
            ),

          // ── Step funnel panel ────────────────────────────────────────────
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PanelHeader(
                  title: 'Flujo completo del quiz de onboarding',
                  trailing: 'toca un paso para ver respuestas',
                ),
                const SizedBox(height: 24),
                for (int i = 0; i < d.steps.length; i++) ...[
                  _OnboardingStepRow(
                    step: d.steps[i],
                    answers: d.answersForStep(d.steps[i].stepNumber),
                    color: _colorFor(d.steps[i].stepNumber),
                    isMaxDropoff: d.steps[i].stepNumber == d.maxDropoffStep,
                  ),
                  if (i < d.steps.length - 1)
                    const Divider(height: 1, color: Color(0x0C000000)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARDING STEP ROW
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingStepRow extends StatefulWidget {
  const _OnboardingStepRow({
    required this.step,
    required this.answers,
    required this.color,
    required this.isMaxDropoff,
  });

  final OnboardingFunnelStep step;
  final OnboardingAnswerGroup? answers;
  final Color color;
  final bool isMaxDropoff;

  @override
  State<_OnboardingStepRow> createState() => _OnboardingStepRowState();
}

class _OnboardingStepRowState extends State<_OnboardingStepRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final hasAnswers = widget.answers != null && widget.answers!.options.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drop-off badge above step (shown between steps) ───────────────
          if (step.dropPct > 0) ...[
            Padding(
              padding: const EdgeInsets.only(left: 22, bottom: 6),
              child: Text(
                '${step.dropLabel} abandono',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.isMaxDropoff ? AppColors.danger : AppColors.ink3,
                ),
              ),
            ),
          ],

          // ── Row: num | name | count | pct ────────────────────────────────
          InkWell(
            onTap: hasAnswers
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${step.stepNumber}',
                          style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.stepName,
                              style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: AppColors.ink2, fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              step.questionEs,
                              style: const TextStyle(fontSize: 12, color: AppColors.ink3),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          step.uniqueUsers > 0 ? '${step.uniqueUsers}' : '—',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: step.uniqueUsers > 0 ? AppColors.ink : AppColors.ink3,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 46,
                        child: Text(
                          step.pctLabel,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: step.uniqueUsers > 0 ? widget.color : AppColors.ink3,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 22,
                        child: hasAnswers
                            ? Icon(
                                _expanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 16,
                                color: AppColors.ink3,
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: LinearProgressIndicator(
                            value: step.pctOfStart.clamp(0.0, 1.0),
                            minHeight: 14,
                            backgroundColor: AppColors.progressBg,
                            valueColor: AlwaysStoppedAnimation(
                              step.uniqueUsers > 0 ? widget.color : AppColors.shimmerBase,
                            ),
                          ),
                        ),
                        if (widget.isMaxDropoff && step.uniqueUsers > 0)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.danger.withAlpha(80),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Answer distribution (expandable) ─────────────────────────────
          if (hasAnswers && _expanded)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 10),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0x16000000), width: 2),
                  ),
                ),
                padding: const EdgeInsets.only(left: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'distribución de respuestas',
                      style: TextStyle(fontSize: 11, color: AppColors.ink3),
                    ),
                    const SizedBox(height: 10),
                    for (final opt in widget.answers!.options)
                      _AnswerOptionRow(option: opt, color: widget.color),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANSWER OPTION ROW
// ─────────────────────────────────────────────────────────────────────────────

class _AnswerOptionRow extends StatelessWidget {
  const _AnswerOptionRow({required this.option, required this.color});

  final OnboardingAnswerOption option;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              option.answer,
              style: const TextStyle(fontSize: 12, color: AppColors.ink2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: option.pct.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.progressBg,
                valueColor: AlwaysStoppedAnimation(color.withAlpha(180)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              option.pctLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '${option.uniqueUsers}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: AppColors.ink3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARDING REFRESH BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingRefreshButton extends StatefulWidget {
  @override
  State<_OnboardingRefreshButton> createState() => _OnboardingRefreshButtonState();
}

class _OnboardingRefreshButtonState extends State<_OnboardingRefreshButton> {
  bool _loading = false;

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('dashboard_metrics')
          .doc('onboarding')
          .collection('refresh_requests')
          .add({'created_at': FieldValue.serverTimestamp()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sincronizando desde Firebase Analytics (~30s)'),
          backgroundColor: AppColors.ink,
          duration: Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al solicitar sincronización'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sincronizar desde Firebase Analytics',
      child: InkWell(
        onTap: _refresh,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: _loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.chartBlue),
                )
              : const Icon(Icons.sync, size: 18, color: AppColors.chartBlue),
        ),
      ),
    );
  }
}
