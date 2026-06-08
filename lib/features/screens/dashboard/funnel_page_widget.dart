import 'dart:developer';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/dash_colors.dart';
import 'package:dashboard_analitycs/core/models/funnel_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/revenuecat_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/user_model.dart';
import 'package:dashboard_analitycs/core/services/funnel_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/revenuecat_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/user_sync_service.dart';
import 'package:dashboard_analitycs/core/widgets/app_shimmer.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'empty_tables_component.dart';
import 'shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class FunnelPage extends StatefulWidget {
  const FunnelPage({super.key, required this.range});
  final DateRange range;

  @override
  State<FunnelPage> createState() => _FunnelPageState();
}

class _FunnelPageState extends State<FunnelPage> {
  List<UserModel> _allUsers = [];
  bool _loading = true;

  @override
  void didUpdateWidget(FunnelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) setState(() {});
  }

  List<UserModel> get _dateFiltered {
    final start = DashboardProvider.rangeStart(widget.range);
    if (start == null) return _allUsers;
    return _allUsers.where((u) {
      final d = DateTime.tryParse(u.createdAt);
      return d != null && d.isAfter(start);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      var users = await UserSyncService().getAllUsersLocal();
      if (users.isEmpty || users.every((u) => u.country.isEmpty)) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .limit(10000)
            .get();
        users = snap.docs
            .map((d) => UserModel.fromFirestore(d.id, d.data()))
            .toList();
      }
      if (mounted) setState(() => _allUsers = users);
    } catch (_) {
      // lista vacía si falla
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _FunnelShimmer();

    final filtered = _dateFiltered;
    final total = filtered.length;
    final proCount = filtered.where((u) => u.plan == 'pro').length;
    final convPct = total == 0 ? 0.0 : proCount / total * 100;

    // Previous period comparison for growth badge
    final now = DateTime.now();
    final days = switch (widget.range) {
      DateRange.d7  => 7,
      DateRange.d30 => 30,
      DateRange.d90 => 90,
      DateRange.all => null,
    };
    int prevTotal = 0;
    if (days != null) {
      final periodStart = now.subtract(Duration(days: days));
      final prevStart   = now.subtract(Duration(days: days * 2));
      prevTotal = _allUsers.where((u) {
        final d = DateTime.tryParse(u.createdAt);
        return d != null && d.isAfter(prevStart) && d.isBefore(periodStart);
      }).length;
    }
    final growthPct = prevTotal == 0
        ? 0.0
        : (total - prevTotal) / prevTotal * 100;
    final rangeName = switch (widget.range) {
      DateRange.d7  => 'semana',
      DateRange.d30 => 'mes',
      DateRange.d90 => 'trimestre',
      DateRange.all => '',
    };

    return StreamBuilder<RevenueCatMetrics?>(
      stream: RevenueCatMetricsService.stream(),
      builder: (context, rcSnap) {
        final rc = rcSnap.data;
        return StreamBuilder<FunnelMetrics?>(
          stream: FunnelMetricsService.stream(),
          builder: (context, funnelSnap) {
            final funnel = funnelSnap.data;
            final funnelRange = funnel?.range(widget.range);
            final hasPaywallData = funnelRange != null;
            final hasRcData = rc != null;

            // Android vs iOS from devices
            final devices = funnel?.devices ?? [];
            final androidCount = devices
                .where((d) => d.os.toLowerCase().contains('android'))
                .fold(0, (s, d) => s + d.count);
            final iosCount = devices
                .where((d) {
                  final os = d.os.toLowerCase();
                  return os.contains('ios') ||
                      os.contains('iphone') ||
                      os.contains('ipad');
                })
                .fold(0, (s, d) => s + d.count);
            final platformTotal = androidCount + iosCount;
            final androidFraction =
                platformTotal > 0 ? androidCount / platformTotal : 0.5;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Text(
                  'Embudo',
                  style: TextStyle(
                    fontSize: 44,
                    height: 1.03,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                    color: context.dc.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Flujo de conversión y retención de usuarios.',
                  style: TextStyle(fontSize: 18, color: context.dc.ink2),
                ),
                const SizedBox(height: 28),

                // ── TOP CARDS (4 en grid responsivo) ─────────────────────
                _TopCardsGrid(
                  total: total,
                  proCount: proCount,
                  convPct: convPct,
                  growthPct: growthPct,
                  prevTotal: prevTotal,
                  rangeName: rangeName,
                  activeTrials:
                      hasRcData ? rc.overview.activeTrials : null,
                  androidFraction: androidFraction,
                  androidCount: androidCount,
                  iosCount: iosCount,
                  hasDeviceData: platformTotal > 0,
                  funnel: funnel,
                  currentRange: widget.range,
                ),
                const SizedBox(height: 24),

                // ── FUNNEL STEPS ─────────────────────────────────────────
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PanelHeader(
                        title: 'Flujo de conversión',
                        trailing: 'Firestore · RevenueCat',
                      ),
                      const SizedBox(height: 24),
                      _FunnelSteps(
                        total: total,
                        paywall: hasPaywallData
                            ? funnelRange.uniquePaywall
                            : null,
                        trials:
                            hasRcData ? rc.overview.activeTrials : null,
                        pro: proCount,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── GROWTH CHART ─────────────────────────────────────────
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PanelHeader(
                        title: 'Nuevos usuarios',
                        trailing: 'Registro por período',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 280,
                        child: _GrowthChart(users: _allUsers),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── EVENTS ───────────────────────────────────────────────
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Eventos',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: context.dc.ink,
                            ),
                          ),
                          const Spacer(),
                          if (funnel?.updatedAtLabel.isNotEmpty == true)
                            Text(
                              funnel!.updatedAtLabel,
                              style: TextStyle(
                                  fontSize: 13, color: context.dc.ink3),
                            ),
                          const SizedBox(width: 10),
                          const Text(
                            'Firebase Analytics',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.ink3),
                          ),
                          const SizedBox(width: 10),
                          const _FunnelRefreshButton(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      funnel == null
                          ? const SizedBox(
                              height: 200,
                              child: EmptyTablesComponent(
                                title: 'Sin datos de eventos',
                                description:
                                    'Presiona ⟳ para cargar eventos desde Firebase Analytics.',
                              ),
                            )
                          : _EventsSection(
                              funnel: funnel,
                              currentRange: widget.range,
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── DEVICES ──────────────────────────────────────────────
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PanelHeader(
                        title: 'Dispositivos activos',
                        trailing: 'Firebase Analytics',
                      ),
                      const SizedBox(height: 16),
                      funnel == null || funnel.devices.isEmpty
                          ? const SizedBox(
                              height: 200,
                              child: EmptyTablesComponent(
                                title: 'Sin datos de dispositivos',
                                description:
                                    'Los dispositivos se sincronizan automáticamente.',
                              ),
                            )
                          : _DevicesList(devices: funnel.devices),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP CARDS — grid 4 columnas (2 en mobile)
// ─────────────────────────────────────────────────────────────────────────────

class _TopCardsGrid extends StatelessWidget {
  const _TopCardsGrid({
    required this.total,
    required this.proCount,
    required this.convPct,
    required this.growthPct,
    required this.prevTotal,
    required this.rangeName,
    required this.activeTrials,
    required this.androidFraction,
    required this.androidCount,
    required this.iosCount,
    required this.hasDeviceData,
    required this.funnel,
    required this.currentRange,
  });

  final int total;
  final int proCount;
  final double convPct;
  final double growthPct;
  final int prevTotal;
  final String rangeName;
  final int? activeTrials;
  final double androidFraction;
  final int androidCount;
  final int iosCount;
  final bool hasDeviceData;
  final FunnelMetrics? funnel;
  final DateRange currentRange;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        final cols =
            constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 600 ? 2 : 1;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;

        final cards = [
          _UsersCompareCard(
            total: total,
            proCount: proCount,
            growthPct: growthPct,
            hasPrevData: prevTotal > 0,
            rangeName: rangeName,
          ),
          _InsightCard(
            convPct: convPct,
            proCount: proCount,
            total: total,
          ),
          _SessionsCard(
            funnel: funnel,
            currentRange: currentRange,
            androidFraction: androidFraction,
            androidCount: androidCount,
            iosCount: iosCount,
            hasDeviceData: hasDeviceData,
          ),
          _TrialsCard(activeTrials: activeTrials),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(width: w, child: card),
          ],
        );
      },
    );
  }
}

// ── Users Compare Card (estilo "Visits") ─────────────────────────────────────

class _UsersCompareCard extends StatelessWidget {
  const _UsersCompareCard({
    required this.total,
    required this.proCount,
    required this.growthPct,
    required this.hasPrevData,
    required this.rangeName,
  });

  final int total;
  final int proCount;
  final double growthPct;
  final bool hasPrevData;
  final String rangeName;

  String _fmt(int n) {
    if (n < 1000) return '$n';
    final s = n.toString();
    return '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    final freeCount = total - proCount;
    final proFraction = total > 0 ? proCount / total : 0.0;
    final isPositive = growthPct >= 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.dc.elevated,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 14,
                          color: context.dc.ink3,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Usuarios',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.dc.ink2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasPrevData) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? AppColors.success.withAlpha(22)
                            : AppColors.danger.withAlpha(22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 11,
                            color: isPositive
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${growthPct.abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isPositive
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'vs $rangeName anterior',
                      style: TextStyle(
                          fontSize: 10, color: context.dc.ink3),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Big number
          Text(
            _fmt(total),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
              height: 1,
              color: context.dc.ink,
            ),
          ),
          const SizedBox(height: 16),
          // Pro vs Free split
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_outline_rounded,
                            size: 12, color: AppColors.pink),
                        const SizedBox(width: 4),
                        Text('Pro',
                            style: TextStyle(
                                fontSize: 11, color: context.dc.ink3)),
                      ],
                    ),
                    Text(
                      '${(proFraction * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.dc.ink,
                      ),
                    ),
                    Text('$proCount',
                        style: TextStyle(
                            fontSize: 11, color: context.dc.ink3)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.dc.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.dc.ink3,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Free',
                            style: TextStyle(
                                fontSize: 11, color: context.dc.ink3)),
                        const SizedBox(width: 4),
                        Icon(Icons.person_outline_rounded,
                            size: 12, color: AppColors.chartBlue),
                      ],
                    ),
                    Text(
                      '${((1 - proFraction) * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.dc.ink,
                      ),
                    ),
                    Text('$freeCount',
                        style: TextStyle(
                            fontSize: 11, color: context.dc.ink3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Split bar: pink=Pro, blue=Free
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 6,
              decoration:
                  const BoxDecoration(color: AppColors.chartBlue),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: total > 0
                      ? proFraction.clamp(0.01, 0.99)
                      : 0.01,
                  child: Container(color: AppColors.pink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Insight Card ──────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.convPct,
    required this.proCount,
    required this.total,
  });

  final double convPct;
  final int proCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isPositive = convPct > 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.dc.elevated,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.chartAmber.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 15,
                  color: AppColors.chartAmber,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Conversión Pro',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.dc.ink2,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.success.withAlpha(20)
                      : context.dc.progressBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.north_east_rounded
                          : Icons.south_east_rounded,
                      size: 12,
                      color: isPositive
                          ? AppColors.success
                          : AppColors.ink3,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isPositive ? 'Activo' : 'Sin datos',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPositive
                            ? AppColors.success
                            : AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${convPct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  height: 1,
                  color: context.dc.ink,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Icon(
                  Icons.north_east_rounded,
                  size: 20,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$proCount usuarios ',
                  style: const TextStyle(
                    color: AppColors.pink,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: 'han convertido a Pro\nde $total registrados',
                  style: TextStyle(
                    color: context.dc.ink2,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Split Card (Android vs iOS) ───────────────────────────────────────────────

class _SessionsCard extends StatelessWidget {
  const _SessionsCard({
    required this.funnel,
    required this.currentRange,
    required this.androidFraction,
    required this.androidCount,
    required this.iosCount,
    required this.hasDeviceData,
  });

  final FunnelMetrics? funnel;
  final DateRange currentRange;
  final double androidFraction;
  final int androidCount;
  final int iosCount;
  final bool hasDeviceData;

  int _sessionsInRange(DateRange r) {
    final events = funnel?.range(r)?.events ?? [];
    for (final name in ['session_start', 'app_open', 'user_engagement']) {
      try {
        return events.firstWhere((e) => e.name == name).count;
      } catch (_) {}
    }
    return 0;
  }

  String _fmtNum(int n) {
    if (n < 1000) return '$n';
    final s = n.toString();
    return '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    final iosFraction = 1.0 - androidFraction;
    final currentSessions = _sessionsInRange(currentRange);
    final d7Sessions     = _sessionsInRange(DateRange.d7);
    final d30Sessions    = _sessionsInRange(DateRange.d30);

    double? trendPct;
    bool isTrendPositive = true;
    if (d7Sessions > 0 && d30Sessions > 0) {
      final d7Rate  = d7Sessions  / 7;
      final d30Rate = d30Sessions / 30;
      trendPct = (d7Rate - d30Rate) / d30Rate * 100;
      isTrendPositive = trendPct >= 0;
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.dc.elevated,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(children: [
                  Icon(Icons.bar_chart_rounded, size: 14, color: context.dc.ink3),
                  const SizedBox(width: 5),
                  Text(
                    'Sesiones',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.dc.ink2),
                  ),
                ]),
              ),
              if (trendPct != null && trendPct.abs() > 0.1)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isTrendPositive
                            ? AppColors.success.withAlpha(22)
                            : AppColors.danger.withAlpha(22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isTrendPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 11,
                            color: isTrendPositive ? AppColors.success : AppColors.danger,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${trendPct.abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: isTrendPositive ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('vs semana anterior', style: TextStyle(fontSize: 10, color: context.dc.ink3)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Big number
          Text(
            currentSessions > 0 ? _fmtNum(currentSessions) : '—',
            style: TextStyle(
              fontSize: 42, fontWeight: FontWeight.w800,
              letterSpacing: -2, height: 1, color: context.dc.ink,
            ),
          ),
          const SizedBox(height: 16),
          // Android vs iOS split
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.phone_android_outlined, size: 12, color: AppColors.chartAmber),
                      const SizedBox(width: 4),
                      Text('Android', style: TextStyle(fontSize: 11, color: context.dc.ink3)),
                    ]),
                    Text(
                      hasDeviceData ? '${(androidFraction * 100).toStringAsFixed(0)}%' : '—',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.dc.ink),
                    ),
                    Text('$androidCount', style: TextStyle(fontSize: 11, color: context.dc.ink3)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: context.dc.surface, borderRadius: BorderRadius.circular(6)),
                child: Text('VS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.dc.ink3)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text('iOS', style: TextStyle(fontSize: 11, color: context.dc.ink3)),
                      const SizedBox(width: 4),
                      const Icon(Icons.phone_iphone_outlined, size: 12, color: AppColors.chartBlue),
                    ]),
                    Text(
                      hasDeviceData ? '${(iosFraction * 100).toStringAsFixed(0)}%' : '—',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.dc.ink),
                    ),
                    Text('$iosCount', style: TextStyle(fontSize: 11, color: context.dc.ink3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Split bar: amber=Android, blue=iOS
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 6,
              decoration: const BoxDecoration(color: AppColors.chartBlue),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: hasDeviceData ? androidFraction.clamp(0.01, 0.99) : 0.5,
                  child: Container(color: AppColors.chartAmber),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trials Card ───────────────────────────────────────────────────────────────

class _TrialsCard extends StatelessWidget {
  const _TrialsCard({required this.activeTrials});
  final int? activeTrials;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.dc.elevated,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.chartPurple.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_outlined,
                    size: 15, color: AppColors.chartPurple),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trials activos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.dc.ink2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            activeTrials != null ? '$activeTrials' : '—',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
              height: 1,
              color: context.dc.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            activeTrials != null
                ? activeTrials! > 0
                    ? 'en período de\nprueba ahora mismo'
                    : 'sin trials activos\nen este momento'
                : 'cargando desde\nRevenueCat...',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: context.dc.ink2,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.dc.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'RevenueCat',
              style: TextStyle(fontSize: 11, color: context.dc.ink3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FUNNEL STEPS
// ─────────────────────────────────────────────────────────────────────────────

class _FunnelSteps extends StatelessWidget {
  const _FunnelSteps({
    required this.total,
    required this.paywall,
    required this.trials,
    required this.pro,
  });

  final int total;
  final int? paywall;
  final int? trials;
  final int pro;

  @override
  Widget build(BuildContext context) {
    final baseline = total > 0 ? total : 1;
    final steps = [
      _StepData(label: 'Registrados', subtitle: 'Total de usuarios',
          countStr: '$total', fraction: 1.0,
          color: AppColors.chartBlue, icon: Icons.people_outline),
      _StepData(label: 'Paywall', subtitle: 'Vieron el paywall',
          countStr: paywall != null ? '$paywall' : '—',
          fraction: paywall != null ? (paywall! / baseline).clamp(0.0, 1.0) : 0.0,
          color: AppColors.chartPurple, icon: Icons.visibility_outlined,
          hasPendingData: paywall == null),
      _StepData(label: 'Trial', subtitle: 'Iniciaron prueba',
          countStr: trials != null ? '$trials' : '—',
          fraction: trials != null ? (trials! / baseline).clamp(0.0, 1.0) : 0.0,
          color: AppColors.chartAmber, icon: Icons.timer_outlined,
          hasPendingData: trials == null),
      _StepData(label: 'Pro', subtitle: 'Conversión final',
          countStr: '$pro',
          fraction: (pro / baseline).clamp(0.0, 1.0),
          color: AppColors.pink, icon: Icons.star_outline),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final colCount = constraints.maxWidth >= 480 ? 4 : 2;
        final w = (constraints.maxWidth - gap * (colCount - 1)) / colCount;
        return Wrap(
          spacing: gap, runSpacing: gap,
          children: [
            for (final s in steps) SizedBox(width: w, child: _StepCard(data: s)),
          ],
        );
      },
    );
  }
}

class _StepData {
  const _StepData({
    required this.label, required this.subtitle, required this.countStr,
    required this.fraction, required this.color, required this.icon,
    this.hasPendingData = false,
  });
  final String label;
  final String subtitle;
  final String countStr;
  final double fraction;
  final Color color;
  final IconData icon;
  final bool hasPendingData;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.data});
  final _StepData data;

  @override
  Widget build(BuildContext context) {
    final pctStr = data.hasPendingData
        ? 'Pendiente de sync'
        : '${(data.fraction * 100).toStringAsFixed(1)}% del total';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: context.dc.elevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 3, color: data.color),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: data.color.withAlpha(28),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(data.icon, size: 17, color: data.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.dc.ink)),
                        Text(data.subtitle, style: TextStyle(fontSize: 11, color: context.dc.ink3)),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 16),
                  Text(data.countStr, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: context.dc.ink)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: data.fraction, minHeight: 5,
                      backgroundColor: context.dc.progressBg,
                      valueColor: AlwaysStoppedAnimation(data.color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(pctStr, style: TextStyle(
                    fontSize: 11,
                    color: data.hasPendingData ? context.dc.ink3 : data.color,
                    fontWeight: data.hasPendingData ? FontWeight.normal : FontWeight.w600,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GROWTH CHART (LineChart + filtro de período)
// ─────────────────────────────────────────────────────────────────────────────

enum _GrowthPeriod {
  d7('7D'), d30('30D'), m3('3M'), m6('6M'), y1('1A');
  const _GrowthPeriod(this.label);
  final String label;
}

class _GrowthChart extends StatefulWidget {
  const _GrowthChart({required this.users});
  final List<UserModel> users;

  @override
  State<_GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<_GrowthChart> {
  _GrowthPeriod _period = _GrowthPeriod.m6;

  List<({String label, int count})> _buildPoints() {
    switch (_period) {
      case _GrowthPeriod.d7:  return _daily(7);
      case _GrowthPeriod.d30: return _daily(30);
      case _GrowthPeriod.m3:  return _monthly(3);
      case _GrowthPeriod.m6:  return _monthly(6);
      case _GrowthPeriod.y1:  return _monthly(12);
    }
  }

  List<({String label, int count})> _daily(int days) {
    final now = DateTime.now();
    final counts = <String, int>{};
    for (final u in widget.users) {
      final d = DateTime.tryParse(u.createdAt);
      if (d == null) continue;
      final key = '${d.year}-${d.month}-${d.day}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return List.generate(days, (i) {
      final d = now.subtract(Duration(days: days - 1 - i));
      final key = '${d.year}-${d.month}-${d.day}';
      final label = days <= 7
          ? ['Dom','Lun','Mar','Mié','Jue','Vie','Sáb'][d.weekday % 7]
          : '${d.day}/${d.month}';
      return (label: label, count: counts[key] ?? 0);
    });
  }

  List<({String label, int count})> _monthly(int months) {
    final now = DateTime.now();
    const mLabels = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final counts = <String, int>{};
    for (final u in widget.users) {
      final d = DateTime.tryParse(u.createdAt);
      if (d == null) continue;
      counts['${d.year}-${d.month}'] = (counts['${d.year}-${d.month}'] ?? 0) + 1;
    }
    return List.generate(months, (i) {
      int m = now.month - (months - 1 - i);
      int y = now.year;
      while (m <= 0) { m += 12; y--; }
      return (label: mLabels[m], count: counts['$y-$m'] ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();
    final allZero = points.every((p) => p.count == 0);
    final surfaceColor = context.dc.surface;
    final showEveryN = points.length > 14 ? 7 : points.length > 7 ? 3 : 1;

    return Column(
      children: [
        Row(
          children: [
            for (final p in _GrowthPeriod.values) ...[
              _PeriodChip(label: p.label, selected: _period == p,
                  onTap: () => setState(() => _period = p)),
              if (p != _GrowthPeriod.values.last) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: allZero
              ? const EmptyTablesComponent(
                  title: 'Sin actividad en este período',
                  description: 'No hay registros para el rango seleccionado.')
              : _buildLineChart(context, points, surfaceColor, showEveryN),
        ),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context,
      List<({String label, int count})> points, Color surfaceColor, int showEveryN) {
    final maxVal = points.map((p) => p.count).fold(0, math.max).toDouble();
    final maxY = (maxVal * 1.35).ceilToDouble().clamp(5.0, double.infinity);
    final gridInterval = maxY <= 10 ? 2.0 : maxY <= 50 ? 10.0 : (maxY / 5).ceilToDouble();

    return LineChart(LineChartData(
      minY: 0, maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: [for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].count.toDouble())],
          isCurved: true, curveSmoothness: 0.3,
          color: AppColors.pink, barWidth: 2.5, isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [AppColors.pink.withAlpha(46), AppColors.pink.withAlpha(0)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
          dotData: FlDotData(
            show: points.length <= 12,
            getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
              radius: 4, color: AppColors.pink, strokeColor: surfaceColor, strokeWidth: 2.5),
          ),
        ),
      ],
      gridData: FlGridData(
        show: true, drawVerticalLine: false, horizontalInterval: gridInterval,
        getDrawingHorizontalLine: (_) => FlLine(color: AppColors.line, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 36, interval: gridInterval,
          getTitlesWidget: (value, meta) {
            if (value == meta.max) return const SizedBox.shrink();
            return SideTitleWidget(meta: meta,
              child: Text('${value.toInt()}', style: const TextStyle(fontSize: 11, color: AppColors.ink3)));
          },
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 28,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= points.length) return const SizedBox.shrink();
            if (i % showEveryN != 0 && i != points.length - 1) return const SizedBox.shrink();
            return SideTitleWidget(meta: meta,
              child: Text(points[i].label, style: const TextStyle(fontSize: 10, color: AppColors.ink3)));
          },
        )),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.ink,
          tooltipBorderRadius: BorderRadius.circular(10),
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipItems: (spots) => spots.map((spot) {
            final i = spot.x.toInt();
            final label = (i >= 0 && i < points.length) ? points[i].label : '';
            final count = spot.y.toInt();
            return LineTooltipItem('$label\n',
              const TextStyle(color: AppColors.white, fontWeight: FontWeight.w500, fontSize: 12),
              children: [TextSpan(
                text: '$count usuario${count == 1 ? '' : 's'}',
                style: const TextStyle(color: AppColors.pinkLight, fontWeight: FontWeight.w700, fontSize: 14),
              )],
            );
          }).toList(),
        ),
      ),
    ));
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink : context.dc.surface,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: context.dc.divider, width: 1),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: selected ? AppColors.white : context.dc.ink3,
        )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _EventsSection extends StatefulWidget {
  const _EventsSection({required this.funnel, required this.currentRange});
  final FunnelMetrics funnel;
  final DateRange currentRange;

  @override
  State<_EventsSection> createState() => _EventsSectionState();
}

class _EventsSectionState extends State<_EventsSection> {
  late DateRange _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = DateRange.all;
  }

  List<FunnelEvent> get _events {
    final rangeData = widget.funnel.range(_selectedRange);
    if (rangeData != null && rangeData.events.isNotEmpty) return rangeData.events;
    return widget.funnel.allEvents;
  }

  void _openDetail(BuildContext context, FunnelEvent event) {
    showDialog(
      context: context,
      barrierColor: AppColors.ink.withAlpha(80),
      builder: (_) => _EventDetailDialog(funnel: widget.funnel, event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;

    String rangeFullLabel(DateRange r) => switch (r) {
      DateRange.all => 'Todos los eventos',
      DateRange.d7  => 'Últimos 7 días',
      DateRange.d30 => 'Últimos 30 días',
      DateRange.d90 => 'Últimos 90 días',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: context.dc.elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.dc.divider),
          ),
          child: DropdownButton<DateRange>(
            value: _selectedRange,
            underline: const SizedBox.shrink(),
            isDense: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: context.dc.ink3),
            dropdownColor: context.dc.elevated,
            borderRadius: BorderRadius.circular(12),
            style: TextStyle(fontSize: 13, color: context.dc.ink),
            items: DateRange.values.map((r) => DropdownMenuItem(
              value: r,
              child: Text(rangeFullLabel(r)),
            )).toList(),
            onChanged: (r) { if (r != null) setState(() => _selectedRange = r); },
          ),
        ),
        const SizedBox(height: 20),
        if (events.isEmpty)
          const SizedBox(
            height: 180,
            child: EmptyTablesComponent(
              title: 'Sin datos para este período',
              description: 'Presiona ⟳ para sincronizar desde Firebase Analytics.',
            ),
          )
        else ...[
          _EventsBarChart(events: events, onEventTap: (e) => _openDetail(context, e)),
          const SizedBox(height: 24),
          _EventsList(events: events, onEventTap: (e) => _openDetail(context, e)),
        ],
      ],
    );
  }
}

// ── Events bar chart ──────────────────────────────────────────────────────────

class _EventsBarChart extends StatelessWidget {
  const _EventsBarChart({required this.events, this.onEventTap});
  final List<FunnelEvent> events;
  final void Function(FunnelEvent)? onEventTap;

  static const List<Color> _palette = [
    AppColors.chartBlue, AppColors.chartGreen, AppColors.chartPurple,
    AppColors.chartAmber, AppColors.chartRed, AppColors.chartOlive, AppColors.chartPink,
  ];

  Color _colorFor(FunnelEvent e, int index) {
    if (e.name == 'paywall_viewed') return AppColors.chartPurple;
    if (e.name == 'trial_started') return AppColors.chartAmber;
    if (e.name == 'subscription_purchased') return AppColors.pink;
    return _palette[index % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final top = events.take(10).toList();
    final totalCount = top.fold(0, (s, e) => s + e.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Top eventos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.dc.ink3)),
            const SizedBox(width: 8),
            Text('· toca para ver detalles', style: TextStyle(fontSize: 12, color: context.dc.ink3)),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < top.length; i++) ...[
          _EventBarRow(
            event: top[i],
            total: totalCount,
            color: _colorFor(top[i], i),
            onTap: () => onEventTap?.call(top[i]),
          ),
          if (i < top.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EventBarRow extends StatelessWidget {
  const _EventBarRow({required this.event, required this.total, required this.color, this.onTap});
  final FunnelEvent event;
  final int total;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? event.count / total : 0.0;
    final pct = (fraction * 100).toStringAsFixed(1);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          if (event.isKeyEvent)
            Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle))
          else
            const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: Text(event.displayName, style: TextStyle(fontSize: 13, color: context.dc.ink2),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0), minHeight: 9,
              backgroundColor: context.dc.progressBg,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          )),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(width: 6),
                Text('${event.count}', style: TextStyle(fontSize: 12, color: context.dc.ink3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full Events List ──────────────────────────────────────────────────────────

class _EventsList extends StatefulWidget {
  const _EventsList({required this.events, this.onEventTap});
  final List<FunnelEvent> events;
  final void Function(FunnelEvent)? onEventTap;

  @override
  State<_EventsList> createState() => _EventsListState();
}

class _EventsListState extends State<_EventsList> {
  String _query = '';
  int _page = 0;
  static const int _pageSize = 20;

  List<FunnelEvent> get _filtered {
    if (_query.isEmpty) return widget.events;
    final q = _query.toLowerCase();
    return widget.events.where((e) => e.displayName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final pageCount = (filtered.length / _pageSize).ceil().clamp(1, 9999);
    final page = _page.clamp(0, pageCount - 1);
    final start = page * _pageSize;
    final pageItems = filtered.skip(start).take(_pageSize).toList();
    final end = start + pageItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(color: context.dc.elevated, borderRadius: BorderRadius.circular(14)),
          child: TextField(
            onChanged: (v) => setState(() { _query = v; _page = 0; }),
            style: TextStyle(fontSize: 14, color: context.dc.ink),
            decoration: InputDecoration(
              hintText: 'Buscar evento...',
              hintStyle: TextStyle(fontSize: 14, color: context.dc.hint),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: context.dc.hint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Expanded(flex: 4, child: Text('Evento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: context.dc.ink3))),
            SizedBox(width: 110, child: Text('Ocurrencias', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: context.dc.ink3))),
            SizedBox(width: 100, child: Text('Usuarios', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: context.dc.ink3))),
          ]),
        ),
        const SizedBox(height: 8),
        if (pageItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text('Sin resultados para "$_query"', style: TextStyle(fontSize: 14, color: context.dc.ink3))),
          )
        else
          for (int i = 0; i < pageItems.length; i++)
            _EventRow(event: pageItems[i], index: i, onTap: () => widget.onEventTap?.call(pageItems[i])),
        if (pageCount > 1) ...[
          const SizedBox(height: 16),
          Row(children: [
            Text('$end de ${filtered.length} eventos', style: TextStyle(fontSize: 13, color: context.dc.ink3)),
            const Spacer(),
            _PageButton(icon: Icons.chevron_left_rounded, enabled: page > 0, onTap: () => setState(() => _page = page - 1)),
            const SizedBox(width: 8),
            Text('${page + 1} / $pageCount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.dc.ink2)),
            const SizedBox(width: 8),
            _PageButton(icon: Icons.chevron_right_rounded, enabled: page < pageCount - 1, onTap: () => setState(() => _page = page + 1)),
          ]),
        ],
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.index, this.onTap});
  final FunnelEvent event;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: index.isEven ? context.dc.elevated.withAlpha(80) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          if (event.isKeyEvent)
            Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(color: AppColors.pink, shape: BoxShape.circle))
          else
            const SizedBox(width: 16),
          Expanded(flex: 4, child: Text(event.displayName, style: TextStyle(fontSize: 14, color: context.dc.ink))),
          SizedBox(width: 110, child: Text('${event.count}', textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.dc.ink))),
          SizedBox(width: 100, child: Text('${event.uniqueUsers}', textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, color: context.dc.ink2))),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENT DETAIL DIALOG
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
    if (event.name == 'paywall_viewed') return AppColors.chartPurple;
    if (event.name == 'trial_started') return AppColors.chartAmber;
    if (event.name == 'subscription_purchased') return AppColors.pink;
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
    final ratio = event.uniqueUsers > 0
        ? event.count / event.uniqueUsers
        : 0.0;

    final hasTrend = d7 != null && d30 != null && d30.count > 0;
    final isTrendingUp = hasTrend && (d7.count / 7) > (d30.count / 30);
    final hasRangeData = d7 != null || d30 != null || d90 != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.dc.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(children: [
                if (event.isKeyEvent)
                  Container(
                    width: 10, height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.displayName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.dc.ink)),
                    Text(event.name, style: TextStyle(fontSize: 12, color: context.dc.ink3)),
                  ],
                )),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, size: 20, color: context.dc.ink3),
                ),
              ]),
              const SizedBox(height: 20),

              // ── 3 stat tiles ──
              Row(children: [
                Expanded(child: _StatTile(label: 'Ocurrencias', value: _fmt(event.count), color: color)),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(label: 'Usuarios únicos', value: _fmt(event.uniqueUsers), color: AppColors.chartBlue)),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(label: 'Por usuario', value: ratio.toStringAsFixed(1), color: AppColors.chartGreen)),
              ]),
              const SizedBox(height: 24),

              // ── Range comparison ──
              if (hasRangeData) ...[
                Text('Actividad por período', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.dc.ink3)),
                const SizedBox(height: 12),
                _RangeBar(label: '7 días',   count: d7?.count  ?? 0, maxCount: allCount, color: color),
                _RangeBar(label: '30 días',  count: d30?.count ?? 0, maxCount: allCount, color: color),
                _RangeBar(label: '90 días',  count: d90?.count ?? 0, maxCount: allCount, color: color),
                _RangeBar(label: 'Histórico',count: allCount,         maxCount: allCount, color: color),
                const SizedBox(height: 20),
              ],

              // ── Trend indicator ──
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
                      size: 20,
                      color: isTrendingUp ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      isTrendingUp
                          ? 'Tendencia al alza — el promedio diario de los últimos 7 días supera el del mes anterior'
                          : 'Tendencia a la baja — el promedio diario de los últimos 7 días está por debajo del mes',
                      style: TextStyle(
                        fontSize: 13,
                        color: isTrendingUp ? AppColors.success : AppColors.danger,
                        height: 1.4,
                      ),
                    )),
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
        color: context.dc.elevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: context.dc.ink3)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.dc.ink)),
          const SizedBox(height: 2),
          Container(width: 20, height: 2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
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

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0 ? count / maxCount : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 12, color: context.dc.ink3))),
        const SizedBox(width: 10),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0), minHeight: 8,
            backgroundColor: context.dc.progressBg,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        )),
        const SizedBox(width: 10),
        SizedBox(width: 44, child: Text(_fmt(count), textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.dc.ink2))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEVICES LIST
// ─────────────────────────────────────────────────────────────────────────────

class _DevicesList extends StatefulWidget {
  const _DevicesList({required this.devices});
  final List<DeviceEntry> devices;

  @override
  State<_DevicesList> createState() => _DevicesListState();
}

class _DevicesListState extends State<_DevicesList> {
  String? _osFilter;
  int _page = 0;
  static const int _pageSize = 20;

  Set<String> get _availableOs {
    final tags = <String>{};
    for (final d in widget.devices) {
      final os = d.os.toLowerCase();
      if (os.contains('android')) tags.add('Android');
      if (os.contains('ios') || os.contains('iphone') || os.contains('ipad')) tags.add('iOS');
    }
    return tags;
  }

  List<DeviceEntry> get _filtered {
    if (_osFilter == null) return widget.devices;
    return widget.devices.where((d) {
      final os = d.os.toLowerCase();
      if (_osFilter == 'Android') return os.contains('android');
      if (_osFilter == 'iOS') return os.contains('ios') || os.contains('iphone') || os.contains('ipad');
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final osTags = _availableOs;
    final filtered = _filtered;
    final pageCount = (filtered.length / _pageSize).ceil().clamp(1, 9999);
    final page = _page.clamp(0, pageCount - 1);
    final start = page * _pageSize;
    final pageItems = filtered.skip(start).take(_pageSize).toList();
    final end = start + pageItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (osTags.length > 1) ...[
          Wrap(spacing: 8, children: [
            _OsChip(label: 'Todos', selected: _osFilter == null, onTap: () => setState(() { _osFilter = null; _page = 0; })),
            for (final tag in osTags)
              _OsChip(label: tag, selected: _osFilter == tag, onTap: () => setState(() { _osFilter = tag; _page = 0; })),
          ]),
          const SizedBox(height: 16),
        ],
        for (int i = 0; i < pageItems.length; i++) _DeviceRow(device: pageItems[i], index: i),
        if (pageCount > 1) ...[
          const SizedBox(height: 16),
          Row(children: [
            Text('$end de ${filtered.length} dispositivos', style: TextStyle(fontSize: 13, color: context.dc.ink3)),
            const Spacer(),
            _PageButton(icon: Icons.chevron_left_rounded, enabled: page > 0, onTap: () => setState(() => _page = page - 1)),
            const SizedBox(width: 8),
            Text('${page + 1} / $pageCount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.dc.ink2)),
            const SizedBox(width: 8),
            _PageButton(icon: Icons.chevron_right_rounded, enabled: page < pageCount - 1, onTap: () => setState(() => _page = page + 1)),
          ]),
        ],
      ],
    );
  }
}

class _OsChip extends StatelessWidget {
  const _OsChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink : context.dc.elevated,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? AppColors.white : context.dc.ink2)),
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({required this.device, required this.index});
  final DeviceEntry device;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isIos = device.os.toLowerCase().contains('ios') ||
        device.os.toLowerCase().contains('iphone') ||
        device.os.toLowerCase().contains('ipad');

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: index.isEven ? context.dc.elevated.withAlpha(80) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: context.dc.elevated, borderRadius: BorderRadius.circular(9)),
          child: Icon(
            isIos ? Icons.phone_iphone_outlined : Icons.phone_android_outlined,
            size: 17, color: isIos ? AppColors.chartBlue : AppColors.chartAmber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.model, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.dc.ink)),
            if (device.os.isNotEmpty) Text(device.os, style: TextStyle(fontSize: 12, color: context.dc.ink3)),
          ],
        )),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${device.count}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.dc.ink)),
            Text('${(device.fraction * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: context.dc.ink3)),
          ],
        ),
        const SizedBox(width: 16),
        SizedBox(width: 80, child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: device.fraction.clamp(0.0, 1.0), minHeight: 4,
            backgroundColor: context.dc.progressBg,
            valueColor: AlwaysStoppedAnimation(isIos ? AppColors.chartBlue : AppColors.chartAmber),
          ),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED: PAGE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _PageButton extends StatelessWidget {
  const _PageButton({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 32, height: 32,
        decoration: BoxDecoration(color: context.dc.elevated, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: enabled ? context.dc.ink2 : context.dc.ink3),
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
          const SizedBox(height: 18),
          const AppSkeletonBox(width: 180, height: 48, radius: 12),
          const SizedBox(height: 10),
          const AppSkeletonBox(width: 300, height: 22, radius: 8),
          const SizedBox(height: 28),
          Row(children: const [
            Expanded(child: AppSkeletonBox(height: 180, radius: 24)),
            SizedBox(width: 14),
            Expanded(child: AppSkeletonBox(height: 180, radius: 24)),
            SizedBox(width: 14),
            Expanded(child: AppSkeletonBox(height: 180, radius: 24)),
            SizedBox(width: 14),
            Expanded(child: AppSkeletonBox(height: 180, radius: 24)),
          ]),
          const SizedBox(height: 18),
          const AppSkeletonBox(height: 180, radius: 32),
          const SizedBox(height: 18),
          const AppSkeletonBox(height: 300, radius: 32),
          const SizedBox(height: 18),
          const AppSkeletonBox(height: 400, radius: 32),
          const SizedBox(height: 18),
          const AppSkeletonBox(height: 200, radius: 32),
        ],
      ),
    );
  }
}
