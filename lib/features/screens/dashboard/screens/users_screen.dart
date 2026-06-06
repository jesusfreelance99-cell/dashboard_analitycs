import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/shared/panel_widget.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppConstants.spacingXl),
            _buildUsersTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usuarios',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Gestiona los usuarios de tu cuenta',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.ink2,
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTable() {
    return PanelWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHeaderWidget(
            title: 'Lista de Usuarios',
            subtitle: '${_mockUsers.length} usuarios registrados',
          ),
          const SizedBox(height: AppConstants.spacingLg),
          _buildTableHeader(),
          const SizedBox(height: AppConstants.spacingSm),
          ..._mockUsers.map((user) => _buildUserRow(user)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            'Nombre',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Email',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            'Estado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserRow(Map<String, String> user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              user['name']!,
              style: const TextStyle(fontSize: 14, color: AppColors.ink),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user['email']!,
              style: const TextStyle(fontSize: 14, color: AppColors.ink2),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              ),
              child: const Text(
                'Activo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static final _mockUsers = [
    {'name': 'Juan Pérez', 'email': 'juan@example.com'},
    {'name': 'María García', 'email': 'maria@example.com'},
    {'name': 'Carlos López', 'email': 'carlos@example.com'},
    {'name': 'Ana Martínez', 'email': 'ana@example.com'},
    {'name': 'David Rodríguez', 'email': 'david@example.com'},
  ];
}
