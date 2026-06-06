import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/fcm_send_service.dart';
import '../providers/notification_provider.dart';

class NotificationSendButtonWidget extends StatefulWidget {
  const NotificationSendButtonWidget({super.key});

  @override
  State<NotificationSendButtonWidget> createState() =>
      _NotificationSendButtonWidgetState();
}

class _NotificationSendButtonWidgetState
    extends State<NotificationSendButtonWidget> {
  bool _isSending = false;

  Future<void> _handleSendNotification() async {
    try {
      if (!_validateForm()) return;

      setState(() => _isSending = true);

      final provider = context.read<NotificationProvider>();
      final fcmTokens = await provider.getFcmTokens();

      if (fcmTokens.isEmpty) {
        _showErrorSnackBar('No hay usuarios para enviar la notificación');
        return;
      }

      final success = await FcmSendService().sendNotification(
        title: provider.notificationTitle,
        message: provider.notificationMessage,
        fcmTokens: fcmTokens,
      );

      if (success) {
        _showSuccessSnackBar(
          'Notificación enviada a ${fcmTokens.length} usuario${fcmTokens.length != 1 ? 's' : ''}',
        );
        provider.clearForm();
      } else {
        _showErrorSnackBar('Error al enviar la notificación');
      }
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      _showErrorSnackBar('Error inesperado: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  bool _validateForm() {
    try {
      final provider = context.read<NotificationProvider>();

      if (!provider.isNotificationValid()) {
        _showErrorSnackBar('Completa el título, mensaje y selecciona destinatarios');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error validating form: $e');
      _showErrorSnackBar('Error validando formulario');
      return false;
    }
  }

  void _showSuccessSnackBar(String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing success snackbar: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing error snackbar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isSending ? null : _handleSendNotification,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.pink.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          ),
        ),
        icon: _isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(FluentIcons.send_20_regular, size: 20),
        label: Text(
          _isSending ? 'Enviando...' : 'Enviar notificación',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
