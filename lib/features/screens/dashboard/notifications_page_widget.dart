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

import 'models.dart';
import 'shared_widgets.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    required this.titleController,
    required this.messageController,
    required this.recipientMode,
    required this.previewSendMode,
    required this.onRecipientModeChanged,
    required this.onPreviewSendModeChanged,
  });

  final TextEditingController titleController;
  final TextEditingController messageController;
  final RecipientMode recipientMode;
  final PreviewSendMode previewSendMode;
  final ValueChanged<RecipientMode> onRecipientModeChanged;
  final ValueChanged<PreviewSendMode> onPreviewSendModeChanged;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Panel(
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
                              child: ChoiceTile(
                                label: 'Todos',
                                icon: FluentIcons.people_20_regular,
                                selected: recipientMode == RecipientMode.all,
                                onTap: () =>
                                    onRecipientModeChanged(RecipientMode.all),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ChoiceTile(
                                label: 'Por segmento',
                                icon: FluentIcons.filter_20_regular,
                                selected:
                                    recipientMode == RecipientMode.segment,
                                onTap: () => onRecipientModeChanged(
                                  RecipientMode.segment,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const DisabledSearchTile(label: 'Específicos'),
                        const SizedBox(height: 18),
                        const RecipientCount(),
                        const SizedBox(height: 30),
                        const FormLabel('Título'),
                        TextInput(
                          controller: titleController,
                          hintText: 'Ej: Tu resumen de gastos está listo',
                          maxLengthLabel: '0/40',
                        ),
                        const SizedBox(height: 24),
                        const FormLabel('Mensaje'),
                        TextAreaInput(
                          controller: messageController,
                          hintText:
                              'Escribe el mensaje que verán tus usuarios...',
                          maxLengthLabel: '0/160',
                        ),
                        const SizedBox(height: 24),
                        SendModeControl(
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
                      PhonePreview(
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

