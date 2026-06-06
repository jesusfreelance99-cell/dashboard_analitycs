import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/notification_provider.dart';
import 'notification_send_button_widget.dart';
import 'notification_recipients_widget.dart';

class NotificationFormWidget extends StatefulWidget {
  const NotificationFormWidget({
    super.key,
    required this.titleController,
    required this.messageController,
  });

  final TextEditingController titleController;
  final TextEditingController messageController;

  @override
  State<NotificationFormWidget> createState() => _NotificationFormWidgetState();
}

class _NotificationFormWidgetState extends State<NotificationFormWidget> {
  @override
  void initState() {
    super.initState();
    _attachListeners();
  }

  void _attachListeners() {
    try {
      widget.titleController.addListener(_onTitleChanged);
      widget.messageController.addListener(_onMessageChanged);
    } catch (e) {
      debugPrint('❌ Error attaching listeners: $e');
    }
  }

  void _onTitleChanged() {
    try {
      final provider = context.read<NotificationProvider>();
      provider.setNotificationTitle(widget.titleController.text);
    } catch (e) {
      debugPrint('❌ Error updating title: $e');
    }
  }

  void _onMessageChanged() {
    try {
      final provider = context.read<NotificationProvider>();
      provider.setNotificationMessage(widget.messageController.text);
    } catch (e) {
      debugPrint('❌ Error updating message: $e');
    }
  }

  @override
  void dispose() {
    try {
      widget.titleController.removeListener(_onTitleChanged);
      widget.messageController.removeListener(_onMessageChanged);
    } catch (e) {
      debugPrint('❌ Error disposing listeners: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NotificationRecipientsWidget(),
          const SizedBox(height: AppConstants.spacingLg),
          _buildTitleSection(),
          const SizedBox(height: AppConstants.spacingLg),
          _buildMessageSection(),
          const SizedBox(height: AppConstants.spacingLg),
          const NotificationSendButtonWidget(),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormLabel('Título'),
        _TitleInput(controller: widget.titleController),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FormLabel('Mensaje'),
        _MessageInput(controller: widget.messageController),
      ],
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.line2, width: 1),
      ),
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: child,
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    );
  }
}

class _TitleInput extends StatelessWidget {
  const _TitleInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: 40,
      maxLines: 1,
      decoration: InputDecoration(
        hintText: 'Ej: Tu resumen de gastos está listo',
        filled: true,
        fillColor: AppColors.fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingMd,
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  const _MessageInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: 160,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Escribe el mensaje que verán tus usuarios...',
        filled: true,
        fillColor: AppColors.fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingMd,
        ),
      ),
    );
  }
}
