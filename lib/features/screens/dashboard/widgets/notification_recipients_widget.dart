import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/notification_provider.dart';

class NotificationRecipientsWidget extends StatelessWidget {
  const NotificationRecipientsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: AppConstants.spacingMd),
        _buildRecipientTabs(context),
        const SizedBox(height: AppConstants.spacingMd),
        _buildRecipientCount(context),
      ],
    );
  }

  Widget _buildRecipientTabs(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            Expanded(
              child: _RecipientTile(
                label: 'Todos',
                icon: FluentIcons.people_20_regular,
                isSelected: provider.sendToAll,
                onTap: () => provider.toggleSendToAll(true),
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Expanded(
              child: _RecipientTile(
                label: 'Específicos',
                icon: FluentIcons.search_20_regular,
                isSelected: !provider.sendToAll,
                onTap: () => provider.toggleSendToAll(false),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecipientCount(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: AppColors.fieldBg,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(FluentIcons.info_20_regular, color: AppColors.ink2),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                'Se enviarán a ${provider.recipientCount} usuario${provider.recipientCount != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.ink2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingMd,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pink : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.pink : AppColors.line2,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.ink,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
