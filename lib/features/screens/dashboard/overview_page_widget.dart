import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dashboard_analitycs/core/models/appstore_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/funnel_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/retention_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/revenuecat_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/user_model.dart';
import 'package:dashboard_analitycs/core/services/appstore_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/country_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/funnel_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/retention_metrics_service.dart';
import 'package:dashboard_analitycs/core/models/playstore_metrics_model.dart';
import 'package:dashboard_analitycs/core/services/playstore_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/revenuecat_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/user_metrics_service.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'empty_tables_component.dart';
import 'geo_donut_panel.dart';
import 'models.dart';
import 'shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              AppColors.shimmerBase,
              AppColors.shimmerLight,
              AppColors.white,
              AppColors.shimmerLight,
              AppColors.shimmerBase,
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ).createShader(bounds),
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

class _ShimBox extends StatelessWidget {
  const _ShimBox({this.width, this.height = 20, this.radius = 10});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

Widget _shimGrid(int count) => GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 300,
    mainAxisExtent: 110,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  ),
  itemCount: count,
  itemBuilder: (_, idx) => Container(
    decoration: BoxDecoration(
      color: AppColors.shimmerBase,
      borderRadius: BorderRadius.circular(18),
    ),
  ),
);

class _AppStoreShimmer extends StatelessWidget {
  const _AppStoreShimmer();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const _ShimBox(width: 180, height: 16, radius: 6),
          const SizedBox(height: 14),
          _shimGrid(3),
          const SizedBox(height: 42),
          const _ShimBox(width: 200, height: 16, radius: 6),
          const SizedBox(height: 14),
          _shimGrid(4),
          const SizedBox(height: 42),
          const _ShimBox(width: 160, height: 16, radius: 6),
          const SizedBox(height: 14),
          _shimGrid(4),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW PAGE
// ─────────────────────────────────────────────────────────────────────────────

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.range, required this.isCompact});

  final DateRange range;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStoreMetrics?>(
      stream: AppStoreMetricsService.stream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _AppStoreShimmer();
        }
        return StreamBuilder<RevenueCatMetrics?>(
          stream: RevenueCatMetricsService.stream(),
          builder: (context, revenueSnap) {
            return StreamBuilder<FunnelMetrics?>(
              stream: FunnelMetricsService.stream(),
              builder: (context, funnelSnap) {
                return StreamBuilder<RetentionMetrics?>(
                  stream: RetentionMetricsService.stream(),
                  builder: (context, retSnap) {
                    return StreamBuilder<PlayStoreMetrics?>(
                      stream: PlayStoreMetricsService.stream(),
                      builder: (context, playSnap) {
                        return _OverviewContent(
                          range: range,
                          isCompact: isCompact,
                          appStore: snap.data,
                          revenueCat: revenueSnap.data,
                          funnel: funnelSnap.data,
                          retention: retSnap.data,
                          playStore: playSnap.data,
                        );
                      },
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
// CONTENIDO REAL
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewContent extends StatefulWidget {
  const _OverviewContent({
    required this.range,
    required this.isCompact,
    required this.appStore,
    required this.revenueCat,
    required this.funnel,
    required this.retention,
    required this.playStore,
  });

  final DateRange range;
  final bool isCompact;
  final AppStoreMetrics? appStore;
  final RevenueCatMetrics? revenueCat;
  final FunnelMetrics? funnel;
  final RetentionMetrics? retention;
  final PlayStoreMetrics? playStore;

  @override
  State<_OverviewContent> createState() => _OverviewContentState();
}

class _OverviewContentState extends State<_OverviewContent> {
  String _platform = 'ios';
  String _continentFilter = 'Todos';
  Future<List<CountryEntry>>? _countryFuture;

  @override
  void initState() {
    super.initState();
    _countryFuture = _loadCountries();
  }

  Future<List<CountryEntry>> _loadCountries() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .limit(10000)
          .get();
      final countMap = <String, int>{};
      for (final doc in snap.docs) {
        final u = UserModel.fromFirestore(doc.id, doc.data());
        final name = u.country.trim();
        countMap[name] = (countMap[name] ?? 0) + 1;
      }
      return CountryMetricsService.fromCounts(countMap);
    } catch (_) {
      return [];
    }
  }

  // ignore: unused_element
  int _eventUniques(List<FunnelEvent> events, String name) =>
      events.where((e) => e.name == name).fold(0, (s, e) => s + e.uniqueUsers);

  Widget _buildAndroidStoreCards() {
    final ps = widget.playStore;
    final rcOverview = widget.revenueCat?.overview;
    final rcRange = widget.revenueCat?.range(widget.range);
    final hasRangeNewCustomers = (rcRange?.newCustomers ?? 0) > 0;
    final newCustomers = hasRangeNewCustomers
        ? rcRange!.newCustomers
        : (rcOverview?.newCustomers28d ?? 0);
    if (ps == null) return const _AppStoreCardsShimmer();
    return ResponsiveGrid(
      minTileWidth: 250,
      children: [
        MetricCard(
          label: 'Impresiones',
          value: ps.storeVisitorsStr,
          helperText: 'visitas a la ficha en Play Store',
        ),
        MetricCard(
          label: 'Nuevos clientes',
          value: newCustomers > 0 ? '$newCustomers' : '—',
          helperText: hasRangeNewCustomers
              ? 'RevenueCat · ${rcRange!.periodLabel}'
              : 'RevenueCat · últimos 28 días',
        ),
        MetricCard(
          label: 'Rating',
          value: ps.ratingStr,
          valueSuffix: ps.rating > 0
              ? const Icon(
                  Icons.star_rounded,
                  color: AppColors.starAmber,
                  size: 26,
                )
              : null,
          badgeText: ps.totalReviews > 0
              ? '${ps.totalReviews} reseñas'
              : 'Sin reseñas aún',
          badgeType: BadgeType.neutral,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final as = widget.appStore;
    final rc = widget.revenueCat;
    final funnel = widget.funnel;
    final rcOverview = rc?.overview;
    final rcRange = rc?.range(widget.range);

    // final funnelRange = funnel?.range(widget.range);
    // final funnelEvents = funnelRange?.events ?? [];

    final newCustomers = (rcRange?.newCustomers ?? 0) > 0
        ? rcRange!.newCustomers
        : (rcOverview?.newCustomers28d ?? 0);

    // Ratio comercial de referencia: stock de suscripciones activas vs nuevos clientes.
    final activeSubs = rcOverview?.activeSubscriptions ?? 0;
    final activeSubsToNewCustomers = newCustomers > 0 && activeSubs > 0
        ? '${(activeSubs / newCustomers * 100).toStringAsFixed(1)}%'
        : '—';
    final activeSubsToNewCustomersHelper = newCustomers > 0 && activeSubs > 0
        ? '$activeSubs activas de $newCustomers nuevos clientes'
        : 'suscripciones activas · nuevos clientes';

    // Usuarios iOS / Android desde funnel devices
    final devices = funnel?.devices ?? [];
    final iosCount = devices
        .where(
          (d) =>
              d.os.toLowerCase().contains('ios') ||
              d.os.toLowerCase().contains('iphone') ||
              d.os.toLowerCase().contains('ipad'),
        )
        .fold(0, (s, d) => s + d.count);
    final androidCount = devices
        .where((d) => d.os.toLowerCase().contains('android'))
        .fold(0, (s, d) => s + d.count);

    // Funnel steps — ocultos junto con _OverviewFunnel
    // final funnelBase    = rcOverview?.activeCustomers28d ?? 0;
    // final funnelOpen    = _eventUniques(funnelEvents, 'app_open') > 0
    //     ? _eventUniques(funnelEvents, 'app_open')
    //     : _eventUniques(funnelEvents, 'first_open') > 0
    //     ? _eventUniques(funnelEvents, 'first_open')
    //     : _eventUniques(funnelEvents, 'session_start');
    // final funnelSignup  = _eventUniques(funnelEvents, 'onboarding_step') > 0
    //     ? _eventUniques(funnelEvents, 'onboarding_step')
    //     : _eventUniques(funnelEvents, 'sign_up') > 0
    //     ? _eventUniques(funnelEvents, 'sign_up')
    //     : _eventUniques(funnelEvents, 'registration_completed');
    // final funnelTutorial = _eventUniques(funnelEvents, 'tutorial_complete');
    // final funnelLogin   = _eventUniques(funnelEvents, 'login');
    // final funnelPaywall = funnelRange?.uniquePaywall ?? 0;
    // final funnelTrial   = funnelRange?.uniqueTrial ?? rcOverview?.activeTrials ?? 0;
    // final funnelSub     = _eventUniques(funnelEvents, 'purchase') > 0
    //     ? _eventUniques(funnelEvents, 'purchase')
    //     : _eventUniques(funnelEvents, 'app_store_subscription_convert') > 0
    //     ? _eventUniques(funnelEvents, 'app_store_subscription_convert')
    //     : activeSubs;

    // funnelSteps — oculto junto con _OverviewFunnel
    // final funnelSteps = [
    //   _FunnelStep('Descarga', funnelBase, AppColors.chartBlue,
    //     tooltip: 'Los nuevos clientes son clientes vistos por primera vez en el período que se mide.'),
    //   _FunnelStep('App abierta', funnelOpen, AppColors.chartGreen),
    //   _FunnelStep('Onboarding', funnelSignup, AppColors.chartPurple),
    //   _FunnelStep('Tutorial', funnelTutorial, AppColors.chartOlive),
    //   _FunnelStep('Login', funnelLogin, AppColors.pink),
    //   _FunnelStep('Paywall', funnelPaywall, AppColors.chartAmber),
    //   _FunnelStep('Trial', funnelTrial, AppColors.danger),
    //   _FunnelStep('Suscripción', funnelSub, AppColors.success),
    // ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // ── PLATFORM TOGGLE ──────────────────────────────────────────────
        _PlatformToggle(
          selected: _platform,
          onSelect: (p) => setState(() => _platform = p),
        ),
        const SizedBox(height: 20),

        // ── TIENDA Y DESCARGAS ───────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                label: 'TIENDA Y DESCARGAS',
                source: _platform == 'android'
                    ? (widget.playStore != null
                          ? 'Play Store · ${widget.playStore!.updatedAtLabel}'
                          : 'Play Store')
                    : (as != null
                          ? 'App Store · ${as.periodLabel}'
                          : 'App Store'),
              ),
            ),
            if (_platform == 'android')
              const _PlayStoreRefreshButton()
            else
              const _AppStoreRefreshButton(),
          ],
        ),
        const SizedBox(height: 14),
        if (_platform == 'android')
          _buildAndroidStoreCards()
        else if (as == null)
          const _AppStoreCardsShimmer()
        else
          ResponsiveGrid(
            minTileWidth: 250,
            children: [
              MetricCard(
                label: 'Primeras descargas',
                value: (rcOverview?.activeCustomers28d ?? 0) > 0
                    ? '${rcOverview!.activeCustomers28d}'
                    : '—',
                helperText: 'clientes activos · RevenueCat',
              ),
              MetricCard(
                label: 'Impresiones',
                value: as.impressionsStr,
                helperText: 'visitas a la ficha en App Store',
                infoTooltip:
                    'El número de veces que se ha visto el icono de la app en App Store en dispositivos con iOS 8, macOS 10.14.1, tvOS 9, visionOS 1.0 o versiones posteriores.',
              ),
              MetricCard(
                label: 'Visualizaciones',
                value: as.pageViewsStr,
                helperText: 'página del producto · App Store',
                infoTooltip:
                    'El número de veces que se ha visto la página del producto de la app en App Store en dispositivos con iOS 8, macOS 10.14.1, tvOS 9, visionOS 1.0 o versiones posteriores.',
              ),
              MetricCard(
                label: 'Conversión',
                value: () {
                  final pv = as.pageViews ?? 0;
                  final rc = rcOverview?.activeCustomers28d ?? 0;
                  if (pv > 0 && rc > 0) {
                    return '${(rc / pv * 100).toStringAsFixed(1)}%';
                  }
                  return as.conversionStr;
                }(),
                helperText: 'visualizaciones → clientes RC',
                infoTooltip:
                    'Se calcula dividiendo el número total de clientes activos (RevenueCat, últimos 28 días) por las visualizaciones de la página del producto en App Store.',
              ),
              MetricCard(
                label: 'Rating',
                value: as.ratingStr,
                valueSuffix: as.rating > 0
                    ? const Icon(
                        Icons.star_rounded,
                        color: AppColors.starAmber,
                        size: 26,
                      )
                    : null,
                badgeText: as.totalReviews > 0
                    ? '${as.totalReviews} reseñas'
                    : 'Sin reseñas aún',
                badgeType: BadgeType.neutral,
              ),
            ],
          ),
        const SizedBox(height: 42),

        // ── INGRESOS Y SUSCRIPCIONES ─────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                label: 'INGRESOS Y SUSCRIPCIONES',
                source: rc == null
                    ? 'RevenueCat'
                    : rc.updatedAtLabel.isEmpty
                    ? rc.source
                    : '${rc.source} · ${rc.updatedAtLabel}',
              ),
            ),
            const _RevenueCatRefreshButton(),
          ],
        ),

        _SubgroupLabel('Suscripciones · RevenueCat'),
        ResponsiveGrid(
          minTileWidth: 200,
          children: [
            MetricCard(
              label: 'Suscripciones activas',
              value: (rcOverview?.activeSubscriptions ?? 0) > 0
                  ? '${rcOverview!.activeSubscriptions}'
                  : '0',
              helperText: 'pagando ahora · producción',
            ),
            /* MetricCard(
              label: 'En prueba',
              value: (rcOverview?.activeTrials ?? 0) > 0
                  ? '${rcOverview!.activeTrials}'
                  : '0',
              helperText: 'free trial activo',
            ), */
            MetricCard(
              label: 'Clientes activos',
              value: (rcOverview?.activeCustomers28d ?? 0) > 0
                  ? '${rcOverview!.activeCustomers28d}'
                  : '—',
              helperText: 'últimos 28 días',
            ),
            MetricCard(
              label: 'Active trials',
              value: rc?.range(DateRange.all).activeTrialsLabel ?? '0',
              helperText: 'acumulado · todo el tiempo',
            ),
          ],
        ),

        _SubgroupLabel('Ingresos'),
        ResponsiveGrid(
          minTileWidth: 220,
          children: [
            MetricCard(
              label: 'MRR',
              value: rcOverview?.mrrLabel ?? '—',
              accent: true,
              helperText: 'ingresos recurrentes mensuales',
            ),
            MetricCard(
              label: 'Activos / nuevos clientes',
              value: activeSubsToNewCustomers,
              helperText: activeSubsToNewCustomersHelper,
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (rcRange != null)
          _RevenueBarsPanel(
            bars: rcRange.revenueBars,
            revenueLabel: rcRange.revenueLabel,
            periodLabel: rcRange.periodLabel,
            totalRevenue: rcRange.revenue,
          ),

        const SizedBox(height: 14),
        FutureBuilder<UserCounts>(
          future: UserMetricsService.future,
          builder: (context, snap) {
            final u = snap.data ?? UserCounts.empty;
            final pagoYTrial =
                (rcOverview?.activeSubscriptions ?? 0) +
                (rcOverview?.activeTrials ?? 0);
            final soloGratuito = (u.total - pagoYTrial).clamp(0, 999999);
            return ResponsiveGrid(
              minTileWidth: 220,
              children: [
                MetricCard(
                  label: 'Usuarios activos totales',
                  value: u.total > 0 ? '${u.total}' : '—',
                  helperText: 'últimos 28 días',
                ),
                MetricCard(
                  label: 'Usuarios de pago (+trial)',
                  value: pagoYTrial > 0 ? '$pagoYTrial' : '—',
                  helperText: 'suscripción o prueba activa',
                ),
                MetricCard(
                  label: 'Plan gratuito activos',
                  value: u.total > 0 ? '$soloGratuito' : '—',
                  helperText: 'sin trial ni compra',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 42),

        // ── RETENCIÓN Y CANCELACIONES ────────────────────────────────────
        const SectionHeader(
          label: 'RETENCIÓN Y CANCELACIONES',
          source: 'Firebase · RevenueCat',
        ),
        const SizedBox(height: 14),
        ResponsiveGrid(
          minTileWidth: 220,
          children: [
            MetricCard(
              label: 'Cancelaciones',
              value: rcOverview?.cancelledLabel ?? '—',
              accent: true,
              helperText: 'planes pagos cancelados',
            ),
            MetricCard(
              label: '% Churn',
              value: rcOverview?.churnRateLabel ?? '—',
              accent: true,
              helperText: 'cancelados / activos',
            ),
            MetricCard(
              label: 'Mes 1',
              value: rcOverview?.subRetentionP1Label ?? '—',
              helperText: 'retención 1er mes · suscripciones',
            ),
            MetricCard(
              label: 'Mes 6',
              value: rcOverview?.subRetentionP6Label ?? '—',
              accent: (rcOverview?.subRetentionP6 ?? 0) > 0,
              helperText: 'retención 6° mes · suscripciones',
            ),
          ],
        ),
        const SizedBox(height: 42),

        // ── EMBUDO DE CONVERSIÓN (temporalmente oculto) ──────────────────
        // const SectionHeader(
        //   label: 'EMBUDO DE CONVERSIÓN',
        //   source: 'Firebase · RevenueCat',
        // ),
        // const SizedBox(height: 14),
        // _OverviewFunnel(
        //   steps: funnelSteps,
        //   totalEvents: funnelEvents.fold(0, (s, e) => s + e.count),
        //   totalUsers: funnelEvents.fold(
        //     0,
        //     (s, e) => s > e.uniqueUsers ? s : e.uniqueUsers,
        //   ),
        // ),
        // const SizedBox(height: 42),

        // ── USUARIOS ─────────────────────────────────────────────────────
        const SectionHeader(label: 'USUARIOS', source: 'Firebase'),
        const SizedBox(height: 14),
        FutureBuilder<UserCounts>(
          future: UserMetricsService.future,
          builder: (context, snap) {
            final u = snap.data ?? UserCounts.empty;
            return Column(
              children: [
                ResponsiveGrid(
                  minTileWidth: 220,
                  children: [
                    MetricCard(
                      label: 'Registrados únicos',
                      value: u.total > 0 ? '${u.total}' : '—',
                      badgeText: u.newToday > 0 ? '↑ ${u.newToday} hoy' : null,
                      badgeType: BadgeType.positive,
                      helperText: 'total',
                    ),
                    MetricCard(
                      label: 'Usuarios iOS',
                      value: iosCount > 0
                          ? '$iosCount'
                          : (u.total > 0 ? '${u.total}' : '—'),
                      helperText: 'solo iOS disponible',
                    ),
                    MetricCard(
                      label: 'Usuarios Android',
                      value: androidCount > 0 ? '$androidCount' : '0',
                      helperText: 'pendiente de lanzamiento',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Builder(
                  builder: (context) {
                    final rcPro = rcOverview?.activeSubscriptions ?? 0;
                    final total = u.total;
                    final proProp = total > 0 && rcPro > 0
                        ? (rcPro / total).clamp(0.0, 1.0)
                        : u.proProportion;
                    final freeCount = total > 0
                        ? (total - rcPro).clamp(0, 999999)
                        : u.free;
                    final proPercent = total > 0 && rcPro > 0
                        ? '${(rcPro / total * 100).toStringAsFixed(0)}%'
                        : u.proPercent;
                    final freePercent = total > 0 && freeCount > 0
                        ? '${(freeCount / total * 100).toStringAsFixed(0)}%'
                        : u.freePercent;
                    return Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PanelHeader(
                            title: 'Pro vs Free',
                            trailing: '$total usuarios',
                          ),
                          const SizedBox(height: 28),
                          PlanDistributionBar(proportion: proProp),
                          const SizedBox(height: 28),
                          PlanRow(
                            icon: const FaIcon(
                              FontAwesomeIcons.crown,
                              size: 24,
                            ),
                            iconBackground: AppColors.goldLight,
                            iconColor: AppColors.goldDark,
                            title: 'Plan Pro',
                            subtitle: 'activos · RevenueCat',
                            value: rcPro > 0 ? '$rcPro' : '${u.pro}',
                            percentage: proPercent,
                          ),
                          const SizedBox(height: 26),
                          PlanRow(
                            icon: const Icon(
                              FluentIcons.gift_20_regular,
                              size: 24,
                            ),
                            iconBackground: AppColors.fieldBg,
                            iconColor: AppColors.ink3,
                            title: 'Plan Gratuito',
                            value: '$freeCount',
                            percentage: freePercent,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 42),

        // ── DISTRIBUCIÓN GEOGRÁFICA ──────────────────────────────────────
        const SectionHeader(
          label: 'DISTRIBUCIÓN GEOGRÁFICA',
          source: 'Firebase',
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<CountryEntry>>(
          future: _countryFuture,
          builder: (context, countrySnap) {
            if (countrySnap.connectionState == ConnectionState.waiting) {
              return const Panel(child: _CountryShimmer());
            }
            final entries = countrySnap.data ?? [];
            if (entries.isEmpty) {
              return const Panel(
                child: EmptyTablesComponent(
                  title: 'Sin datos de país',
                  description: 'Aún no hay registros de ubicación.',
                ),
              );
            }
            return Panel(
              child: GeoDonutPanel(
                allEntries: entries,
                filter: _continentFilter,
                onFilterChanged: (v) => setState(() => _continentFilter = v),
              ),
            );
          },
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLATFORM TOGGLE
// ─────────────────────────────────────────────────────────────────────────────

class _PlatformToggle extends StatelessWidget {
  const _PlatformToggle({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const options = [('ios', 'iOS'), ('android', 'Android')];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (key, label) in options)
            _PlatformBtn(
              label: label,
              selected: selected == key,
              onTap: () => onSelect(key),
            ),
        ],
      ),
    );
  }
}

class _PlatformBtn extends StatelessWidget {
  const _PlatformBtn({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBGROUP LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _SubgroupLabel extends StatelessWidget {
  const _SubgroupLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 14),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppColors.ink3,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(thickness: 1, color: AppColors.line)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI CONVERSION FUNNEL
// ─────────────────────────────────────────────────────────────────────────────

class _FunnelStep {
  final String label;
  final int count;
  final Color color;
  final String? tooltip;
  // ignore: unused_element_parameter
  const _FunnelStep(this.label, this.count, this.color, {this.tooltip});
}

// ignore: unused_element
class _OverviewFunnel extends StatelessWidget {
  const _OverviewFunnel({
    required this.steps,
    // ignore: unused_element_parameter
    this.totalEvents = 0,
    // ignore: unused_element_parameter
    this.totalUsers = 0,
  });
  final List<_FunnelStep> steps;
  final int totalEvents;
  final int totalUsers;

  @override
  Widget build(BuildContext context) {
    final base = steps.isEmpty ? 1 : (steps[0].count > 0 ? steps[0].count : 1);
    const maxH = 90.0;

    String fmt(int n) {
      if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
      return '$n';
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: PanelHeader(
                  title: 'Flujo de conversión',
                  trailing: 'Firebase · RevenueCat',
                ),
              ),
              if (totalEvents > 0) ...[
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmt(totalEvents),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const Text(
                      'eventos totales',
                      style: TextStyle(fontSize: 11, color: AppColors.ink3),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmt(totalUsers),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const Text(
                      'usuarios activos',
                      style: TextStyle(fontSize: 11, color: AppColors.ink3),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: maxH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < steps.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: (steps[i].count / base * maxH).clamp(4.0, maxH),
                      decoration: BoxDecoration(
                        color: steps[i].count > 0
                            ? steps[i].color
                            : AppColors.shimmerBase,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        steps[i].count > 0 ? '${steps[i].count}' : '—',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        steps[i].count > 0
                            ? '${(steps[i].count / base * 100).toStringAsFixed(0)}%'
                            : '—',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.ink3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      if (steps[i].tooltip != null)
                        Tooltip(
                          message: steps[i].tooltip!,
                          preferBelow: true,
                          waitDuration: Duration.zero,
                          showDuration: const Duration(seconds: 8),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            color: AppColors.white,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                steps[i].label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.ink2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 11,
                                color: AppColors.ink3,
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          steps[i].label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.ink2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER DE CARDS — solo sección App Store Connect
// ─────────────────────────────────────────────────────────────────────────────

class _AppStoreCardsShimmer extends StatelessWidget {
  const _AppStoreCardsShimmer();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = ((constraints.maxWidth) / 250).floor().clamp(1, 5);
          const gap = 18.0;
          final tileWidth = (constraints.maxWidth - gap * (count - 1)) / count;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(
              3,
              (_) => Container(
                width: tileWidth,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFRESH BUTTON — App Store Connect
// ─────────────────────────────────────────────────────────────────────────────

class _AppStoreRefreshButton extends StatefulWidget {
  const _AppStoreRefreshButton();

  @override
  State<_AppStoreRefreshButton> createState() => _AppStoreRefreshButtonState();
}

class _AppStoreRefreshButtonState extends State<_AppStoreRefreshButton> {
  bool _requested = false;

  Future<void> _refresh() async {
    if (_requested) return;
    setState(() => _requested = true);
    try {
      await FirebaseFirestore.instance
          .collection('dashboard_metrics')
          .doc('appstore')
          .collection('refresh_triggers')
          .add({'created_at': FieldValue.serverTimestamp()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualización en curso (~60s)'),
            backgroundColor: AppColors.ink,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _requested = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al solicitar actualización'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStoreMetrics?>(
      stream: AppStoreMetricsService.stream(),
      builder: (context, snap) {
        final status = snap.data?.status ?? '';
        final isLoading = _requested || status == 'partial';
        // Resetear _requested cuando el status vuelve a 'complete'
        if (_requested && status == 'complete') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _requested = false);
          });
        }
        return Tooltip(
          message: 'Actualizar métricas App Store',
          child: InkWell(
            onTap: isLoading ? null : _refresh,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.pink,
                      ),
                    )
                  : const Icon(
                      FluentIcons.arrow_sync_20_regular,
                      size: 18,
                      color: AppColors.pink,
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFRESH BUTTON — RevenueCat
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueCatRefreshButton extends StatefulWidget {
  const _RevenueCatRefreshButton();

  @override
  State<_RevenueCatRefreshButton> createState() =>
      _RevenueCatRefreshButtonState();
}

class _RevenueCatRefreshButtonState extends State<_RevenueCatRefreshButton> {
  bool _requested = false;

  Future<void> _refresh() async {
    if (_requested) return;
    setState(() => _requested = true);
    try {
      await RevenueCatMetricsService.requestRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualización de RevenueCat en curso'),
            backgroundColor: AppColors.ink,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _requested = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al solicitar actualización de RevenueCat'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RevenueCatMetrics?>(
      stream: RevenueCatMetricsService.stream(),
      builder: (context, snap) {
        final status = snap.data?.status ?? '';
        final isLoading = _requested || status == 'partial';
        if (_requested && status == 'complete') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _requested = false);
          });
        }
        return Tooltip(
          message: 'Actualizar métricas RevenueCat',
          child: InkWell(
            onTap: isLoading ? null : _refresh,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.success,
                      ),
                    )
                  : const Icon(
                      FluentIcons.arrow_sync_20_regular,
                      size: 18,
                      color: AppColors.success,
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REFRESH BUTTON — Play Store
// ─────────────────────────────────────────────────────────────────────────────

class _PlayStoreRefreshButton extends StatefulWidget {
  const _PlayStoreRefreshButton();

  @override
  State<_PlayStoreRefreshButton> createState() =>
      _PlayStoreRefreshButtonState();
}

class _PlayStoreRefreshButtonState extends State<_PlayStoreRefreshButton> {
  bool _loading = false;

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await PlayStoreMetricsService.requestRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actualización de Play Store en curso (~60s)'),
            backgroundColor: AppColors.ink,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al solicitar actualización de Play Store'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Actualizar métricas Play Store',
      child: InkWell(
        onTap: _refresh,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.chartGreen,
                  ),
                )
              : const Icon(
                  FluentIcons.arrow_sync_20_regular,
                  size: 18,
                  color: AppColors.chartGreen,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN DISTRIBUTION BAR
// ─────────────────────────────────────────────────────────────────────────────

class PlanDistributionBar extends StatelessWidget {
  const PlanDistributionBar({super.key, required this.proportion});
  final double proportion;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Container(
            width: size.width * (1 - proportion),
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          FractionallySizedBox(
            widthFactor: proportion.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.goldGradStart, AppColors.goldGradEnd],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN ROW
// ─────────────────────────────────────────────────────────────────────────────

class PlanRow extends StatelessWidget {
  const PlanRow({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.percentage,
  });

  final Widget icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String value;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: IconTheme(
            data: IconThemeData(color: iconColor, size: 26),
            child: icon,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null)
                  TextSpan(
                    text: ' · $subtitle',
                    style: const TextStyle(fontSize: 20, color: AppColors.ink3),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 22),
        SizedBox(
          width: 82,
          child: Text(
            percentage,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 20, color: AppColors.ink2),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVENUE BARS PANEL — fl_chart
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueBarsPanel extends StatelessWidget {
  const _RevenueBarsPanel({
    required this.bars,
    required this.revenueLabel,
    required this.periodLabel,
    required this.totalRevenue,
  });

  final List<double> bars;
  final String revenueLabel;
  final String periodLabel;
  final double totalRevenue;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();

    final maxBar = bars.fold<double>(1, (m, v) => v > m ? v : m);

    // Distribuye el revenue total proporcionalmente entre las barras
    final totalWeight = bars.fold<double>(
      0,
      (s, v) => s + (v - 28).clamp(0.0, double.infinity),
    );
    final revenuePerBar = totalWeight > 0 && totalRevenue > 0
        ? bars
              .map(
                (b) =>
                    (b - 28).clamp(0.0, double.infinity) /
                    totalWeight *
                    totalRevenue,
              )
              .toList()
        : List<double>.filled(bars.length, 0);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHeader(title: 'Revenue', trailing: periodLabel),
          const SizedBox(height: 4),
          Text(
            revenueLabel,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxBar * 1.2,
                minY: 0,
                barGroups: List.generate(bars.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: bars[i],
                        gradient: const LinearGradient(
                          colors: [Color(0xFF34C77B), Color(0xFF1FA55C)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 36,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxBar / 3,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFEEEEEC), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: totalRevenue > 0,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= revenuePerBar.length)
                          return const SizedBox.shrink();
                        final v = revenuePerBar[i];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            v > 0 ? '\$${v.toStringAsFixed(0)}' : '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.ink3,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.ink,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final v = groupIndex < revenuePerBar.length
                          ? revenuePerBar[groupIndex]
                          : 0.0;
                      return BarTooltipItem(
                        v > 0 ? '\$${v.toStringAsFixed(2)}' : '—',
                        const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryShimmer extends StatelessWidget {
  const _CountryShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < 3 ? 18 : 0),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Container(
                width: 200,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 18),
              Container(
                width: 42,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
