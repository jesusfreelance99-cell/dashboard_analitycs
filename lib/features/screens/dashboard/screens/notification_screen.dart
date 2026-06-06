import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_form_widget.dart';
import '../widgets/notification_preview_widget.dart';
import '../widgets/notification_recipients_widget.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _messageController = TextEditingController();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    try {
      if (!mounted) return;
      final provider = context.read<NotificationProvider>();
      await provider.initialize();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error inicializando notificaciones: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationProvider(),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppConstants.spacingXl),
                _buildContent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 1180;

        return Flex(
          direction: isStacked ? Axis.vertical : Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: NotificationFormWidget(
                titleController: _titleController,
                messageController: _messageController,
              ),
            ),
            SizedBox(
              width: isStacked ? 0 : 34,
              height: isStacked ? 28 : 0,
            ),
            Expanded(
              flex: 5,
              child: NotificationPreviewWidget(
                titleController: _titleController,
                messageController: _messageController,
              ),
            ),
          ],
        );
      },
    );
  }
}
