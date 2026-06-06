import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'dashboard_shell_widget.dart';

class TopHeaderWidget extends StatelessWidget {
  const TopHeaderWidget({
    super.key,
    required this.isMobileLayout,
    required this.currentPage,
    required this.onPageChanged,
  });

  final bool isMobileLayout;
  final DashboardPage currentPage;
  final ValueChanged<DashboardPage> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.line2, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLg,
        vertical: AppConstants.spacingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isMobileLayout)
            Expanded(
              child: _buildMobileNavigation(),
            )
          else
            const SizedBox.shrink(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSearchBar(),
                const SizedBox(width: AppConstants.spacingMd),
                _buildUserMenu(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavigation() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MobileNavItem(
            label: 'Vista General',
            isActive: currentPage == DashboardPage.overview,
            onTap: () => onPageChanged(DashboardPage.overview),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          _MobileNavItem(
            label: 'Usuarios',
            isActive: currentPage == DashboardPage.users,
            onTap: () => onPageChanged(DashboardPage.users),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          _MobileNavItem(
            label: 'Notificaciones',
            isActive: currentPage == DashboardPage.notifications,
            onTap: () => onPageChanged(DashboardPage.notifications),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 200,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar...',
          hintStyle: const TextStyle(color: AppColors.ink3, fontSize: 14),
          filled: true,
          fillColor: AppColors.fieldBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          prefixIcon: const Icon(
            FluentIcons.search_20_regular,
            color: AppColors.ink3,
            size: 18,
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildUserMenu() {
    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Text('Perfil'),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Text('Configuración'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Text('Cerrar sesión'),
        ),
      ],
      onSelected: (value) {
        // Handle menu selection
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.fieldBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: const Icon(
          FluentIcons.person_20_regular,
          color: AppColors.ink,
          size: 20,
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.pink : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
