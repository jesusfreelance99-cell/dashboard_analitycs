import 'dart:math' as math;

import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/app_constants.dart';
import 'package:dashboard_analitycs/core/providers/theme_provider.dart';
import 'package:dashboard_analitycs/core/routes/app_routes.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class DashboardResumeScreen extends StatelessWidget {
  const DashboardResumeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider(),
      child: const _DashboardShell(),
    );
  }
}

class _DashboardShell extends StatefulWidget {
  const _DashboardShell();

  @override
  State<_DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<_DashboardShell> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  _RecipientMode _recipientMode = _RecipientMode.all;
  _PreviewSendMode _previewSendMode = _PreviewSendMode.now;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DashboardProvider, ThemeProvider>(
      builder: (context, dashboard, themeProvider, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 900;
            final isCompact = width < 1180;
            final sidebarWidth = dashboard.collapsed ? 84.0 : 256.0;
            final selectedPage = dashboard.page;
            final pageMeta = _pageMeta(selectedPage);

            return Scaffold(
              backgroundColor: const Color(0xFFF5F5F4),
              drawer: isMobile
                  ? Drawer(
                      elevation: 0,
                      width: math.min(width * 0.82, 312),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      child: _Sidebar(
                        isMobile: true,
                        selectedPage: selectedPage,
                        onPageSelected: (page) {
                          dashboard.setPage(page);
                          Navigator.of(context).maybePop();
                        },
                        onToggleCollapse: dashboard.toggleCollapse,
                        collapsed: false,
                        isDarkMode: themeProvider.isDarkMode,
                        onToggleTheme: themeProvider.toggleTheme,
                        onLogout: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (route) => false,
                          );
                        },
                      ),
                    )
                  : null,
              body: SafeArea(
                child: Row(
                  children: [
                    if (!isMobile)
                      AnimatedContainer(
                        duration: AppConstants.animationMedium,
                        curve: Curves.easeOutCubic,
                        width: sidebarWidth,
                        child: _Sidebar(
                          isMobile: false,
                          selectedPage: selectedPage,
                          onPageSelected: dashboard.setPage,
                          onToggleCollapse: dashboard.toggleCollapse,
                          collapsed: dashboard.collapsed,
                          isDarkMode: themeProvider.isDarkMode,
                          onToggleTheme: themeProvider.toggleTheme,
                          onLogout: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            );
                          },
                        ),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          _TopHeader(
                            isMobile: isMobile,
                            title: pageMeta.title,
                            subtitle: pageMeta.subtitle,
                          ),
                          _DateToolbar(
                            range: dashboard.range,
                            isCompact: isCompact,
                            onRangeChanged: dashboard.setRange,
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                isMobile ? 16 : 26,
                                20,
                                isMobile ? 16 : 26,
                                30,
                              ),
                              child: AnimatedSwitcher(
                                duration: AppConstants.animationMedium,
                                child: KeyedSubtree(
                                  key: ValueKey(selectedPage),
                                  child: _buildPage(
                                    context,
                                    page: selectedPage,
                                    range: dashboard.range,
                                    isCompact: isCompact,
                                    isMobile: isMobile,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required DashPage page,
    required DateRange range,
    required bool isCompact,
    required bool isMobile,
  }) {
    switch (page) {
      case DashPage.overview:
        return _OverviewPage(range: range, isCompact: isCompact);
      case DashPage.notifications:
        return _NotificationsPage(
          titleController: _titleController,
          messageController: _messageController,
          recipientMode: _recipientMode,
          previewSendMode: _previewSendMode,
          onRecipientModeChanged: (mode) {
            setState(() => _recipientMode = mode);
          },
          onPreviewSendModeChanged: (mode) {
            setState(() => _previewSendMode = mode);
          },
        );
      case DashPage.users:
        return _UsersPage(searchController: _searchController);
      case DashPage.funnel:
        return const _PlaceholderPage(
          title: 'Embudo de onboarding',
          description:
              'Esta sección la rediseñamos en el siguiente paso,\ncon el mismo sistema visual flat que la Vista general.',
        );
      case DashPage.cac:
        return const _PlaceholderPage(
          title: 'CAC / LTV',
          description:
              'Esta sección la rediseñamos en el siguiente paso,\ncon el mismo sistema visual flat que la Vista general.',
        );
      case DashPage.features:
        return const _PlaceholderPage(
          title: 'Uso de features',
          description:
              'Esta sección la rediseñamos en el siguiente paso,\ncon el mismo sistema visual flat que la Vista general.',
        );
      case DashPage.retention:
        return const _PlaceholderPage(
          title: 'Retención',
          description:
              'Esta sección la rediseñamos en el siguiente paso,\ncon el mismo sistema visual flat que la Vista general.',
        );
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.isMobile,
    required this.selectedPage,
    required this.onPageSelected,
    required this.onToggleCollapse,
    required this.collapsed,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
  });

  final bool isMobile;
  final DashPage selectedPage;
  final ValueChanged<DashPage> onPageSelected;
  final VoidCallback onToggleCollapse;
  final bool collapsed;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final sections = <_SidebarSectionData>[
      _SidebarSectionData(
        title: 'principal',
        items: const [DashPage.notifications],
      ),
      _SidebarSectionData(
        title: 'menú',
        items: const [
          DashPage.overview,
          DashPage.funnel,
          DashPage.cac,
          DashPage.features,
          DashPage.retention,
          DashPage.users,
        ],
      ),
    ];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              collapsed && !isMobile ? 16 : 20,
              18,
              collapsed && !isMobile ? 16 : 18,
              12,
            ),
            child: Row(
              children: [
                const _TrevoMark(size: 36),
                if (!collapsed || isMobile) ...[
                  const SizedBox(width: 14),
                  const Text(
                    'trevo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.9,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  if (!isMobile)
                    IconButton(
                      onPressed: onToggleCollapse,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.ink3,
                      ),
                      icon: const Icon(
                        FluentIcons.panel_left_contract_20_regular,
                        size: 26,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x16140C10)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
              children: [
                for (final section in sections) ...[
                  if (!collapsed || isMobile)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                      child: Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink3,
                        ),
                      ),
                    ),
                  for (final item in section.items)
                    _SidebarItem(
                      meta: _pageMeta(item),
                      selected: selectedPage == item,
                      collapsed: collapsed && !isMobile,
                      onTap: () => onPageSelected(item),
                    ),
                  const SizedBox(height: 6),
                ],
                const Divider(height: 28, color: Color(0x16140C10)),
                _UtilityItem(
                  icon: isDarkMode
                      ? FluentIcons.weather_sunny_20_regular
                      : FluentIcons.weather_moon_20_regular,
                  label: 'Modo oscuro',
                  collapsed: collapsed && !isMobile,
                  onTap: onToggleTheme,
                ),
                const SizedBox(height: 8),
                _UtilityItem(
                  icon: FluentIcons.color_20_regular,
                  label: 'Cerrar sesión',
                  collapsed: collapsed && !isMobile,
                  onTap: onLogout,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x16140C10)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed && !isMobile ? 12 : 18,
              vertical: 18,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.ink,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'JD',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (!collapsed || isMobile) ...[
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jesús David',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Plan Pro · trial',
                          style: TextStyle(fontSize: 12, color: AppColors.ink3),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    FluentIcons.chevron_up_down_20_regular,
                    color: AppColors.ink3,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.isMobile,
    required this.title,
    required this.subtitle,
  });

  final bool isMobile;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 26,
        8,
        isMobile ? 16 : 26,
        0,
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(FluentIcons.navigation_20_regular),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 15, color: AppColors.ink2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateToolbar extends StatelessWidget {
  const _DateToolbar({
    required this.range,
    required this.isCompact,
    required this.onRangeChanged,
  });

  final DateRange range;
  final bool isCompact;
  final ValueChanged<DateRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final rangeInfo = _rangePresentation(range);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 26,
        18,
        isCompact ? 16 : 26,
        0,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 14,
        spacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FluentIcons.calendar_ltr_20_regular,
                size: 22,
                color: AppColors.ink3,
              ),
              const SizedBox(width: 12),
              const Text(
                'Periodo: ',
                style: TextStyle(fontSize: 16, color: AppColors.ink2),
              ),
              Text(
                rangeInfo.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                ' · ${rangeInfo.dates}',
                style: const TextStyle(fontSize: 16, color: AppColors.ink3),
              ),
            ],
          ),
          _RangeSegmentedControl(range: range, onChanged: onRangeChanged),
        ],
      ),
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({required this.range, required this.isCompact});

  final DateRange range;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final data = _overviewRangeData(range);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buenas noches, Jesús 👋',
          style: TextStyle(
            fontSize: 44,
            height: 1.03,
            fontWeight: FontWeight.w700,
            letterSpacing: -2,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Esto es lo que está pasando en Trevo hoy.',
          style: TextStyle(fontSize: 18, color: AppColors.ink2),
        ),
        const SizedBox(height: 36),
        const _SectionHeader(label: 'APP STORE CONNECT', source: 'iOS'),
        const SizedBox(height: 14),
        _ResponsiveGrid(
          minTileWidth: 250,
          children: [
            _MetricCard(
              label: 'Impresiones',
              value: data.impressions,
              badgeText: '↑ 18%',
              badgeType: _BadgeType.positive,
              helperText: 'vs. anterior',
            ),
            _MetricCard(
              label: 'Descargas',
              value: data.downloads,
              badgeText: '↑ 23%',
              badgeType: _BadgeType.positive,
              helperText: 'vs. anterior',
            ),
            _MetricCard(
              label: 'Conversión tienda',
              value: data.storeConversion,
              badgeText: '↓ 0.4pp',
              badgeType: _BadgeType.negative,
              helperText: 'vs. anterior',
            ),
            const _MetricCard(
              label: 'Rating',
              value: '4.6',
              valueSuffix: Icon(
                Icons.star_rounded,
                color: Color(0xFFF5A524),
                size: 26,
              ),
              badgeText: '38 reseñas',
              badgeType: _BadgeType.neutral,
            ),
          ],
        ),
        const SizedBox(height: 42),
        const _SectionHeader(label: 'REVENUE', source: 'RevenueCat'),
        const SizedBox(height: 14),
        _ResponsiveGrid(
          minTileWidth: 250,
          children: [
            _MetricCard(
              label: 'MRR',
              value: '\$142',
              accent: true,
              badgeText: '↑ \$31',
              badgeType: _BadgeType.positive,
              helperText: 'esta semana',
            ),
            _MetricCard(
              label: 'Revenue total',
              value: data.revenue,
              helperText: 'en el período',
            ),
            _MetricCard(
              label: 'Suscriptores',
              value: data.subscribers,
              badgeText: '↑ 3',
              badgeType: _BadgeType.positive,
              helperText: 'nuevos',
            ),
            _MetricCard(
              label: 'Trials activos',
              value: data.trials,
              badgeText: '↑ 8',
              badgeType: _BadgeType.positive,
              helperText: 'hoy',
            ),
            _MetricCard(
              label: 'Churn',
              value: data.churn,
              badgeText: 'este mes',
              badgeType: _BadgeType.neutral,
            ),
          ],
        ),
        const SizedBox(height: 42),
        const _SectionHeader(label: 'USUARIOS', source: 'Firebase'),
        const SizedBox(height: 14),
        _ResponsiveGrid(
          minTileWidth: 250,
          children: [
            _MetricCard(
              label: 'Registrados',
              value: data.users,
              badgeText: '↑ 3',
              badgeType: _BadgeType.positive,
              helperText: 'hoy',
            ),
            _MetricCard(
              label: 'Plan Pro',
              value: '${data.proUsers}',
              accent: true,
              valueSuffix: FaIcon(
                FontAwesomeIcons.crown,
                color: Color(0xFFF0AB21),
                size: 24,
              ),
              badgeText:
                  '${(data.proUsers / 40 * 100).toStringAsFixed(1)}% del total',
              badgeType: _BadgeType.neutral,
            ),
            _MetricCard(
              label: 'Plan Gratuito',
              value: '${40 - data.proUsers}',
              badgeText:
                  '${(((40 - data.proUsers) / 40) * 100).toStringAsFixed(1)}% del total',
              badgeType: _BadgeType.neutral,
            ),
            _MetricCard(
              label: 'Activos',
              value: data.activeUsers,
              badgeText: '↑ 92.5%',
              badgeType: _BadgeType.positive,
            ),
          ],
        ),
        const SizedBox(height: 34),
        const _SectionHeader(label: 'TENDENCIAS', source: ''),
        const SizedBox(height: 14),
        _ResponsiveSplit(
          left: _TrendMetricPanel(
            title: 'Descargas',
            value: data.downloads,
            delta: '↑ 23%',
            deltaType: _BadgeType.positive,
            barColor: const Color(0xFFEF2F71),
            bars: data.downloadBars,
          ),
          right: _TrendMetricPanel(
            title: 'Revenue',
            value: data.revenue,
            delta: '↑ 18%',
            deltaType: _BadgeType.positive,
            barColor: const Color(0xFF20BB68),
            bars: data.revenueBars,
          ),
        ),
        const SizedBox(height: 40),
        const _SectionHeader(label: 'DISTRIBUCIÓN', source: ''),
        const SizedBox(height: 14),
        _ResponsiveSplit(
          left: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeader(
                  title: 'Descargas por país',
                  trailing: 'Top 4',
                ),
                const SizedBox(height: 18),
                for (final country in data.downloadCountries) ...[
                  _CountryRow(data: country),
                  if (country != data.downloadCountries.last)
                    const SizedBox(height: 18),
                ],
              ],
            ),
          ),
          right: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeader(
                  title: 'Distribución por plan',
                  trailing: '40 usuarios',
                ),
                const SizedBox(height: 28),
                _PlanDistributionBar(proportion: data.proUsers / 40),
                const SizedBox(height: 28),
                _PlanRow(
                  icon: const FaIcon(FontAwesomeIcons.crown, size: 24),
                  iconBackground: const Color(0xFFFFD760),
                  iconColor: const Color(0xFF8A6300),
                  title: 'Plan Pro',
                  subtitle: 'de pago',
                  value: '${data.proUsers}',
                  percentage:
                      '${(data.proUsers / 40 * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 26),
                _PlanRow(
                  icon: const Icon(FluentIcons.gift_20_regular, size: 24),
                  iconBackground: const Color(0xFFF1F1EF),
                  iconColor: AppColors.ink3,
                  title: 'Plan Gratuito',
                  value: '${40 - data.proUsers}',
                  percentage:
                      '${(((40 - data.proUsers) / 40) * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

class _TrendMetricPanel extends StatelessWidget {
  const _TrendMetricPanel({
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaType,
    required this.barColor,
    required this.bars,
  });

  final String title;
  final String value;
  final String delta;
  final _BadgeType deltaType;
  final Color barColor;
  final List<double> bars;

  @override
  Widget build(BuildContext context) {
    const labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Hoy'];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.ink2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.8,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              _Badge(text: delta, type: deltaType),
            ],
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < bars.length; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: bars[i],
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: barColor.withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          labels[i],
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != bars.length - 1) const SizedBox(width: 18),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanDistributionBar extends StatelessWidget {
  const _PlanDistributionBar({required this.proportion});

  final double proportion;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: FractionallySizedBox(
        widthFactor: proportion.clamp(0, 1),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFC61F), Color(0xFFF3B100)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
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

_RangePresentation _rangePresentation(DateRange range) {
  switch (range) {
    case DateRange.d7:
      return const _RangePresentation(
        'últimos 7 días',
        '29 may 2026 – 5 jun 2026',
      );
    case DateRange.d30:
      return const _RangePresentation(
        'últimos 30 días',
        '6 may 2026 – 5 jun 2026',
      );
    case DateRange.d90:
      return const _RangePresentation(
        'últimos 90 días',
        '7 mar 2026 – 5 jun 2026',
      );
    case DateRange.all:
      return const _RangePresentation('todo', '1 ene 2026 – 5 jun 2026');
  }
}

_OverviewRangeData _overviewRangeData(DateRange range) {
  switch (range) {
    case DateRange.d7:
      return const _OverviewRangeData(
        impressions: '3,100',
        downloads: '61',
        storeConversion: '1.9%',
        revenue: '\$48',
        subscribers: '3',
        trials: '8',
        churn: '0%',
        users: '40',
        activeUsers: '37',
        proUsers: 11,
        downloadBars: [78, 132, 138, 174, 28],
        revenueBars: [66, 124, 148, 102, 34],
        downloadCountries: [
          _CountryData('Colombia', '🇨🇴', 56, '91.8%', 0.92),
          _CountryData('México', '🇲🇽', 2, '3.3%', 0.10),
          _CountryData('Estados Unidos', '🇺🇸', 2, '3.3%', 0.10),
          _CountryData('Otros', '🌐', 1, '1.6%', 0.06),
        ],
      );
    case DateRange.d30:
      return const _OverviewRangeData(
        impressions: '12,400',
        downloads: '284',
        storeConversion: '2.3%',
        revenue: '\$198',
        subscribers: '11',
        trials: '23',
        churn: '9%',
        users: '40',
        activeUsers: '37',
        proUsers: 11,
        downloadBars: [84, 132, 138, 168, 26],
        revenueBars: [58, 126, 148, 110, 28],
        downloadCountries: [
          _CountryData('Colombia', '🇨🇴', 261, '91.9%', 0.92),
          _CountryData('México', '🇲🇽', 11, '3.9%', 0.12),
          _CountryData('Estados Unidos', '🇺🇸', 7, '2.5%', 0.09),
          _CountryData('Otros', '🌐', 5, '1.8%', 0.07),
        ],
      );
    case DateRange.d90:
      return const _OverviewRangeData(
        impressions: '28,000',
        downloads: '610',
        storeConversion: '2.2%',
        revenue: '\$420',
        subscribers: '11',
        trials: '31',
        churn: '12%',
        users: '40',
        activeUsers: '37',
        proUsers: 11,
        downloadBars: [92, 138, 154, 178, 40],
        revenueBars: [74, 144, 166, 124, 38],
        downloadCountries: [
          _CountryData('Colombia', '🇨🇴', 560, '91.8%', 0.92),
          _CountryData('México', '🇲🇽', 24, '3.9%', 0.12),
          _CountryData('Estados Unidos', '🇺🇸', 15, '2.5%', 0.09),
          _CountryData('Otros', '🌐', 11, '1.8%', 0.07),
        ],
      );
    case DateRange.all:
      return const _OverviewRangeData(
        impressions: '28,000',
        downloads: '610',
        storeConversion: '2.2%',
        revenue: '\$420',
        subscribers: '11',
        trials: '31',
        churn: '12%',
        users: '40',
        activeUsers: '37',
        proUsers: 11,
        downloadBars: [92, 138, 154, 178, 40],
        revenueBars: [74, 144, 166, 124, 38],
        downloadCountries: [
          _CountryData('Colombia', '🇨🇴', 560, '91.8%', 0.92),
          _CountryData('México', '🇲🇽', 24, '3.9%', 0.12),
          _CountryData('Estados Unidos', '🇺🇸', 15, '2.5%', 0.09),
          _CountryData('Otros', '🌐', 11, '1.8%', 0.07),
        ],
      );
  }
}

class _RangePresentation {
  const _RangePresentation(this.label, this.dates);

  final String label;
  final String dates;
}

class _OverviewRangeData {
  const _OverviewRangeData({
    required this.impressions,
    required this.downloads,
    required this.storeConversion,
    required this.revenue,
    required this.subscribers,
    required this.trials,
    required this.churn,
    required this.users,
    required this.activeUsers,
    required this.proUsers,
    required this.downloadBars,
    required this.revenueBars,
    required this.downloadCountries,
  });

  final String impressions;
  final String downloads;
  final String storeConversion;
  final String revenue;
  final String subscribers;
  final String trials;
  final String churn;
  final String users;
  final String activeUsers;
  final int proUsers;
  final List<double> downloadBars;
  final List<double> revenueBars;
  final List<_CountryData> downloadCountries;
}

class _UsersPage extends StatelessWidget {
  const _UsersPage({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    const countries = [
      _CountryData('Colombia', '🇨🇴', 37, '92.5%', 0.93),
      _CountryData('México', '🇲🇽', 1, '2.5%', 0.08),
      _CountryData('Estados Unidos', '🇺🇸', 1, '2.5%', 0.08),
      _CountryData('Otros', '🌐', 1, '2.5%', 0.08),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Text(
          'Usuarios',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.6,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Todos los usuarios registrados en Trevo.',
          style: TextStyle(fontSize: 18, color: AppColors.ink2),
        ),
        const SizedBox(height: 36),
        _ResponsiveGrid(
          minTileWidth: 220,
          children: const [
            _MetricCard(
              label: 'Total registrados',
              value: '40',
              badgeText: '↑ 3',
              badgeType: _BadgeType.positive,
              helperText: 'hoy',
            ),
            _MetricCard(
              label: 'Plan Pro',
              value: '11',
              accent: true,
              valueSuffix: FaIcon(
                FontAwesomeIcons.crown,
                color: Color(0xFFF0AB21),
                size: 24,
              ),
              badgeText: '27.5% del total',
              badgeType: _BadgeType.neutral,
            ),
            _MetricCard(
              label: 'Plan Gratuito',
              value: '29',
              badgeText: '72.5% del total',
              badgeType: _BadgeType.neutral,
            ),
            _MetricCard(
              label: 'Activos',
              value: '37',
              badgeText: '↑ 92.5%',
              badgeType: _BadgeType.positive,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ResponsiveSplit(
          left: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _PanelHeader(
                  title: 'Usuarios por ubicación',
                  trailing: 'Américas',
                ),
                SizedBox(height: 18),
                _MapPlaceholder(),
              ],
            ),
          ),
          right: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelHeader(title: 'Por país', trailing: 'Top 4'),
                const SizedBox(height: 14),
                for (final country in countries) ...[
                  _CountryRow(data: country),
                  if (country != countries.last) const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1040;
            return Flex(
              direction: stacked ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: stacked ? 0 : 5,
                  child: _SearchField(controller: searchController),
                ),
                SizedBox(width: stacked ? 0 : 18, height: stacked ? 18 : 0),
                Expanded(
                  flex: stacked ? 0 : 3,
                  child: _FilterSegment(
                    items: const ['Todos', 'Activos', 'Inactivos'],
                    selectedIndex: 0,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const _UsersTablePlaceholder(),
      ],
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage({
    required this.titleController,
    required this.messageController,
    required this.recipientMode,
    required this.previewSendMode,
    required this.onRecipientModeChanged,
    required this.onPreviewSendModeChanged,
  });

  final TextEditingController titleController;
  final TextEditingController messageController;
  final _RecipientMode recipientMode;
  final _PreviewSendMode previewSendMode;
  final ValueChanged<_RecipientMode> onRecipientModeChanged;
  final ValueChanged<_PreviewSendMode> onPreviewSendModeChanged;

  @override
  Widget build(BuildContext context) {
    final title = titleController.text.isEmpty
        ? 'Título de la notificación'
        : titleController.text;
    final message = messageController.text.isEmpty
        ? 'Aquí aparece el mensaje que verán tus usuarios.'
        : messageController.text;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1180;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            const Text(
              'Enviar notificación',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.6,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Redacta un mensaje push y elige a quién se lo envías.',
              style: TextStyle(fontSize: 18, color: AppColors.ink2),
            ),
            const SizedBox(height: 28),
            Flex(
              direction: stacked ? Axis.vertical : Axis.horizontal,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Destinatarios',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _ChoiceTile(
                                label: 'Todos',
                                icon: FluentIcons.people_20_regular,
                                selected: recipientMode == _RecipientMode.all,
                                onTap: () =>
                                    onRecipientModeChanged(_RecipientMode.all),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _ChoiceTile(
                                label: 'Por segmento',
                                icon: FluentIcons.filter_20_regular,
                                selected:
                                    recipientMode == _RecipientMode.segment,
                                onTap: () => onRecipientModeChanged(
                                  _RecipientMode.segment,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const _DisabledSearchTile(label: 'Específicos'),
                        const SizedBox(height: 18),
                        const _RecipientCount(),
                        const SizedBox(height: 30),
                        const _FormLabel('Título'),
                        _TextInput(
                          controller: titleController,
                          hintText: 'Ej: Tu resumen de gastos está listo',
                          maxLengthLabel: '0/40',
                        ),
                        const SizedBox(height: 24),
                        const _FormLabel('Mensaje'),
                        _TextAreaInput(
                          controller: messageController,
                          hintText:
                              'Escribe el mensaje que verán tus usuarios...',
                          maxLengthLabel: '0/160',
                        ),
                        const SizedBox(height: 24),
                        _SendModeControl(
                          mode: previewSendMode,
                          onChanged: onPreviewSendModeChanged,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.pink,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(82),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            icon: const Icon(
                              FluentIcons.send_20_regular,
                              size: 28,
                            ),
                            label: const Text('Enviar notificación'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: stacked ? 0 : 34, height: stacked ? 28 : 0),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'VISTA PREVIA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: AppColors.ink3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _PhonePreview(
                        title: title,
                        message: message,
                        sendMode: previewSendMode,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 720,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TrevoMark(size: 76),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.2,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                height: 1.45,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'EN EL SIGUIENTE PASO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: AppColors.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.meta,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final _PageMeta meta;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0x0F140C10) : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 14 : 18,
            vertical: 16,
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                meta.icon,
                size: 30,
                color: selected ? AppColors.pink : AppColors.ink3,
              ),
              if (!collapsed) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    meta.navLabel,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.ink2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UtilityItem extends StatelessWidget {
  const _UtilityItem({
    required this.icon,
    required this.label,
    required this.collapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 8 : 14,
          vertical: 12,
        ),
        child: Row(
          mainAxisAlignment: collapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: AppColors.ink3),
            if (!collapsed) ...[
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(fontSize: 18, color: AppColors.ink2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RangeSegmentedControl extends StatelessWidget {
  const _RangeSegmentedControl({required this.range, required this.onChanged});

  final DateRange range;
  final ValueChanged<DateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (DateRange.d7, '7d'),
      (DateRange.d30, '30d'),
      (DateRange.d90, '90d'),
      (DateRange.all, 'Todo'),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items) ...[
            _SegmentButton(
              label: item.$2,
              selected: range == item.$1,
              onTap: () => onChanged(item.$1),
            ),
            if (item != items.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F1EF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink.withValues(alpha: selected ? 1 : 0.68),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.source});

  final String label;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            color: AppColors.ink3,
          ),
        ),
        if (source.isNotEmpty) ...[
          const Spacer(),
          Text(
            source,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.ink3,
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.badgeText,
    this.badgeType = _BadgeType.neutral,
    this.helperText,
    this.accent = false,
    this.valueSuffix,
  });

  final String label;
  final String value;
  final String? badgeText;
  final _BadgeType badgeType;
  final String? helperText;
  final bool accent;
  final Widget? valueSuffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFFBEEF2) : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppColors.ink2),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  height: 0.95,
                  letterSpacing: -2.2,
                  color: AppColors.ink,
                ),
              ),
              if (valueSuffix != null) ...[
                const SizedBox(width: 10),
                valueSuffix!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (badgeText != null) _Badge(text: badgeText!, type: badgeType),
              if (helperText != null)
                Text(
                  helperText!,
                  style: const TextStyle(fontSize: 16, color: AppColors.ink3),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.type});

  final String text;
  final _BadgeType type;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    switch (type) {
      case _BadgeType.positive:
        background = const Color(0xFFE7F6ED);
        foreground = const Color(0xFF1B9C5B);
        break;
      case _BadgeType.negative:
        background = const Color(0xFFFCE7E4);
        foreground = const Color(0xFFD4584F);
        break;
      case _BadgeType.neutral:
        background = const Color(0xFFF1F1EF);
        foreground = AppColors.ink2;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.minTileWidth, required this.children});

  final double minTileWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = math.max(
          1,
          (constraints.maxWidth / minTileWidth).floor(),
        );
        return GridView.builder(
          itemCount: children.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            mainAxisExtent: 206,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class _ResponsiveSplit extends StatelessWidget {
  const _ResponsiveSplit({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1180;
        return Flex(
          direction: stacked ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: stacked ? 0 : 7, child: left),
            SizedBox(width: stacked ? 0 : 18, height: stacked ? 18 : 0),
            Expanded(flex: stacked ? 0 : 5, child: right),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: child,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const Spacer(),
        Text(
          trailing,
          style: const TextStyle(fontSize: 16, color: AppColors.ink3),
        ),
      ],
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(painter: _DotGridPainter()),
            ),
          ),
          Positioned(
            left: 26,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendLine(flag: '🇨🇴', label: 'Colombia · ', value: '37'),
                  SizedBox(height: 8),
                  _LegendLine(flag: '🇲🇽', label: 'México · ', value: '1'),
                  SizedBox(height: 8),
                  _LegendLine(flag: '🇺🇸', label: 'EE.UU. · ', value: '1'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({
    required this.flag,
    required this.label,
    required this.value,
  });

  final String flag;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: flag, style: const TextStyle(fontSize: 24)),
          TextSpan(
            text: ' $label',
            style: const TextStyle(fontSize: 20, color: AppColors.ink),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({required this.data});

  final _CountryData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(data.flag, style: const TextStyle(fontSize: 30)),
        ),
        Expanded(
          child: Text(
            data.name,
            style: const TextStyle(
              fontSize: 22,
              height: 1.15,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: data.progress,
              minHeight: 14,
              backgroundColor: const Color(0xFFF1F1EF),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFBEBDB6)),
            ),
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 42,
          child: Text(
            '${data.value}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 66,
          child: Text(
            data.percent,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 18, color: AppColors.ink3),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const Icon(
            FluentIcons.search_20_regular,
            size: 34,
            color: AppColors.ink3,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Buscar por nombre o correo...',
                hintStyle: TextStyle(fontSize: 20, color: AppColors.ink3),
              ),
              style: const TextStyle(fontSize: 20, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }
}

class _FilterSegment extends StatelessWidget {
  const _FilterSegment({required this.items, required this.selectedIndex});

  final List<String> items;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: index == selectedIndex
                      ? const Color(0xFFF1F1EF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  items[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink.withValues(
                      alpha: index == selectedIndex ? 1 : 0.72,
                    ),
                  ),
                ),
              ),
            ),
            if (index != items.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _UsersTablePlaceholder extends StatelessWidget {
  const _UsersTablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFCEBF2) : const Color(0xFFF1F1EF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? AppColors.pink : AppColors.ink3,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.pinkDark : AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisabledSearchTile extends StatelessWidget {
  const _DisabledSearchTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            FluentIcons.search_20_regular,
            size: 30,
            color: AppColors.ink3,
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientCount extends StatelessWidget {
  const _RecipientCount();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: const [
          Icon(FluentIcons.send_20_regular, size: 28, color: AppColors.pink),
          SizedBox(width: 16),
          Text(
            'Se enviará a ',
            style: TextStyle(fontSize: 18, color: AppColors.ink2),
          ),
          Text(
            '40',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'usuarios',
            style: TextStyle(fontSize: 18, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hintText,
    required this.maxLengthLabel,
  });

  final TextEditingController controller;
  final String hintText;
  final String maxLengthLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 18, color: AppColors.ink3),
            fillColor: const Color(0xFFF1F1EF),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 18, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          maxLengthLabel,
          style: const TextStyle(fontSize: 14, color: AppColors.ink3),
        ),
      ],
    );
  }
}

class _TextAreaInput extends StatelessWidget {
  const _TextAreaInput({
    required this.controller,
    required this.hintText,
    required this.maxLengthLabel,
  });

  final TextEditingController controller;
  final String hintText;
  final String maxLengthLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 18, color: AppColors.ink3),
            fillColor: const Color(0xFFF1F1EF),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 18, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          maxLengthLabel,
          style: const TextStyle(fontSize: 14, color: AppColors.ink3),
        ),
      ],
    );
  }
}

class _SendModeControl extends StatelessWidget {
  const _SendModeControl({required this.mode, required this.onChanged});

  final _PreviewSendMode mode;
  final ValueChanged<_PreviewSendMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniSegment(
              label: 'Enviar ahora',
              selected: mode == _PreviewSendMode.now,
              onTap: () => onChanged(_PreviewSendMode.now),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MiniSegment(
              label: 'Programar',
              selected: mode == _PreviewSendMode.scheduled,
              onTap: () => onChanged(_PreviewSendMode.scheduled),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSegment extends StatelessWidget {
  const _MiniSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.ink : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}

class _PhonePreview extends StatelessWidget {
  const _PhonePreview({
    required this.title,
    required this.message,
    required this.sendMode,
  });

  final String title;
  final String message;
  final _PreviewSendMode sendMode;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 510),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(72),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF22868), Color(0xFF9A1C43), Color(0xFF25070F)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 154,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(34, 86, 34, 34),
                child: Column(
                  children: [
                    const Text(
                      '9:41',
                      style: TextStyle(
                        fontSize: 84,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'jueves, 5 de junio',
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 52),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8DEE7).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const _TrevoMark(size: 30),
                              const SizedBox(width: 12),
                              const Text(
                                'TREVO',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppColors.ink,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                sendMode == _PreviewSendMode.now
                                    ? 'ahora'
                                    : 'mañana',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.ink2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.3,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrevoMark extends StatelessWidget {
  const _TrevoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.pink,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: CustomPaint(painter: _FlowerPainter(color: AppColors.pink)),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  const _FlowerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = size.width * 0.22;
    final orbit = size.width * 0.18;
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 8; i++) {
      final angle = (math.pi * 2 / 8) * i;
      final offset = Offset(math.cos(angle) * orbit, math.sin(angle) * orbit);
      canvas.drawCircle(center + offset, radius, paint);
    }
    canvas.drawCircle(center, radius * 1.02, paint);
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFD7D7D2);
    const spacing = 32.0;
    const dotSize = 2.4;

    for (double y = 14; y < size.height; y += spacing) {
      for (double x = 14; x < size.width; x += spacing) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: dotSize,
            height: dotSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PageMeta {
  const _PageMeta({
    required this.title,
    required this.subtitle,
    required this.navLabel,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String navLabel;
  final IconData icon;
}

_PageMeta _pageMeta(DashPage page) {
  switch (page) {
    case DashPage.overview:
      return const _PageMeta(
        title: 'Vista general',
        subtitle: 'Resumen ejecutivo del crecimiento de Trevo',
        navLabel: 'Vista general',
        icon: FluentIcons.grid_20_regular,
      );
    case DashPage.funnel:
      return const _PageMeta(
        title: 'Embudo de onboarding',
        subtitle: 'Del primer open hasta la suscripción',
        navLabel: 'Embudo',
        icon: FluentIcons.filter_20_regular,
      );
    case DashPage.cac:
      return const _PageMeta(
        title: 'CAC / LTV',
        subtitle: 'Costo de adquisición y valor por cliente',
        navLabel: 'CAC / LTV',
        icon: FluentIcons.money_20_regular,
      );
    case DashPage.features:
      return const _PageMeta(
        title: 'Uso de features',
        subtitle: 'Qué funciones usan tus usuarios',
        navLabel: 'Features',
        icon: FluentIcons.flash_20_regular,
      );
    case DashPage.retention:
      return const _PageMeta(
        title: 'Retención',
        subtitle: 'Cuántos usuarios vuelven a abrir la app',
        navLabel: 'Retención',
        icon: FluentIcons.arrow_trending_lines_20_regular,
      );
    case DashPage.users:
      return const _PageMeta(
        title: 'Usuarios',
        subtitle: 'Tabla completa de usuarios registrados',
        navLabel: 'Usuarios',
        icon: FluentIcons.people_20_regular,
      );
    case DashPage.notifications:
      return const _PageMeta(
        title: 'Notificaciones',
        subtitle: 'Envía mensajes push a tus usuarios',
        navLabel: 'Notificaciones',
        icon: FluentIcons.alert_20_regular,
      );
  }
}

enum _BadgeType { positive, negative, neutral }

enum _RecipientMode { all, segment }

enum _PreviewSendMode { now, scheduled }

class _CountryData {
  const _CountryData(
    this.name,
    this.flag,
    this.value,
    this.percent,
    this.progress,
  );

  final String name;
  final String flag;
  final int value;
  final String percent;
  final double progress;
}

class _SidebarSectionData {
  const _SidebarSectionData({required this.title, required this.items});

  final String title;
  final List<DashPage> items;
}
