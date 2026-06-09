import 'dart:math' as math;

import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/app_constants.dart';
import 'package:dashboard_analitycs/core/providers/theme_provider.dart';
import 'package:dashboard_analitycs/core/routes/app_routes.dart';
import 'package:dashboard_analitycs/core/services/dash_user_service.dart';
import 'package:dashboard_analitycs/core/services/google_auth_service.dart';
import 'package:dashboard_analitycs/core/services/revenuecat_metrics_service.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'headers_widget.dart';
import 'models.dart';
import 'notifications_page_widget.dart';
import 'overview_page_widget.dart';
import 'placeholder_page_widget.dart';
import 'sidebar_widget.dart';
import 'users_page_widget.dart';
import 'funnel_page_widget.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => DashboardShellState();
}

class DashboardShellState extends State<DashboardShell> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RevenueCatMetricsService.autoRefreshOnDashboardEntry();
    });
  }

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
            final currentPageMeta = pageMeta(selectedPage);

            final isDark = themeProvider.isDarkMode;
            return Scaffold(
              backgroundColor: isDark
                  ? AppColors.bgDark
                  : const Color(0xFFF5F5F4),
              drawer: isMobile
                  ? Drawer(
                      elevation: 0,
                      width: math.min(width * 0.82, 312),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      child: DashboardSidebar(
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
                        onLogout: () async {
                          final router = GoRouter.of(context);
                          try {
                            await GoogleAuthService.signOut();
                          } catch (_) {}
                          router.go(AppRoutes.login);
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
                        child: DashboardSidebar(
                          isMobile: false,
                          selectedPage: selectedPage,
                          onPageSelected: dashboard.setPage,
                          onToggleCollapse: dashboard.toggleCollapse,
                          collapsed: dashboard.collapsed,
                          isDarkMode: themeProvider.isDarkMode,
                          onToggleTheme: themeProvider.toggleTheme,
                          onLogout: () async {
                            final router = GoRouter.of(context);
                            try {
                              DashUserService.refresh();
                              await GoogleAuthService.signOut();
                            } catch (_) {}
                            router.go(AppRoutes.login);
                          },
                        ),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          TopHeader(
                            isMobile: isMobile,
                            title: currentPageMeta.title,
                            subtitle: currentPageMeta.subtitle,
                          ),
                          if (selectedPage != DashPage.notifications &&
                              selectedPage != DashPage.overview)
                            DateToolbar(
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
        return OverviewPage(range: DateRange.all, isCompact: isCompact);
      case DashPage.notifications:
        return NotificationsPage(
          titleController: _titleController,
          messageController: _messageController,
        );
      case DashPage.users:
        return UsersPage(searchController: _searchController, range: range);
      case DashPage.funnel:
        return FunnelPage(range: range);
      case DashPage.cac:
        return const PlaceholderPage(
          title: 'CAC / LTV',
          description:
              'Esta sección la rediseñamos en el siguiente paso,\ncon el mismo sistema visual flat que la Vista general.',
        );
      case DashPage.features:
        return const PlaceholderPage(
          title: 'Uso de features',
          description:
              'Esta sección la rediseñamos en el siguiente paso,\ncon el mismo sistema visual flat que la Vista general.',
        );
      case DashPage.retention:
        return const PlaceholderPage(
          title: 'Retención',
          description:
              'Esta sección la rediseñamos en el siguiente paso,\ncon el mismo sistema visual flat que la Vista general.',
        );
    }
  }
}
