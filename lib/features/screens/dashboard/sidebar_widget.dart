import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'shared_widgets.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
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
    final sections = <SidebarSectionData>[
      SidebarSectionData(
        title: 'principal',
        items: const [DashPage.notifications],
      ),
      SidebarSectionData(
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.white,
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
                const TrevoMark(size: 36),
                if (!collapsed || isMobile) ...[
                  const SizedBox(width: 14),
                  const Text(
                    'Trevo',
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
                    SidebarItem(
                      meta: pageMeta(item),
                      selected: selectedPage == item,
                      collapsed: collapsed && !isMobile,
                      onTap: () => onPageSelected(item),
                    ),
                  const SizedBox(height: 6),
                ],
                const Divider(height: 28, color: Color(0x16140C10)),
                UtilityItem(
                  icon: isDarkMode
                      ? FluentIcons.weather_sunny_20_regular
                      : FluentIcons.weather_moon_20_regular,
                  label: 'Modo oscuro',
                  collapsed: collapsed && !isMobile,
                  onTap: onToggleTheme,
                ),
                const SizedBox(height: 8),
                UtilityItem(
                  icon: FluentIcons.sign_out_20_regular,
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
                      color: AppColors.white,
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
