import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'dashboard_shell_widget.dart';

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
  });

  final DashboardPage currentPage;
  final ValueChanged<DashboardPage> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.line2, width: 1),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Row(
              children: [
                const Text(
                  'Trevo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pink,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.line2, height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
              child: Column(
                children: [
                  _SidebarItem(
                    icon: FluentIcons.home_20_regular,
                    label: 'Vista General',
                    isActive: currentPage == DashboardPage.overview,
                    onTap: () => onPageChanged(DashboardPage.overview),
                  ),
                  _SidebarItem(
                    icon: FluentIcons.people_20_regular,
                    label: 'Usuarios',
                    isActive: currentPage == DashboardPage.users,
                    onTap: () => onPageChanged(DashboardPage.users),
                  ),
                  _SidebarItem(
                    icon: FluentIcons.mail_20_regular,
                    label: 'Notificaciones',
                    isActive: currentPage == DashboardPage.notifications,
                    onTap: () => onPageChanged(DashboardPage.notifications),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.fieldBg,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Versión 1.0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Dashboard Analytics',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.ink3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.pink.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.pink : AppColors.ink3,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppColors.pink : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
