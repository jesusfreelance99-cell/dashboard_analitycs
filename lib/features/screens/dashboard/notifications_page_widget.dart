import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/models/user_model.dart';
import 'package:dashboard_analitycs/core/services/user_sync_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

enum _RecipientTab { all, specific }

enum _SendState { idle, sending, done, error }

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.titleController,
    required this.messageController,
  });

  final TextEditingController titleController;
  final TextEditingController messageController;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _RecipientTab _tab = _RecipientTab.all;
  _SendState _sendState = _SendState.idle;

  final _searchController = TextEditingController();

  // cache en-memoria: se carga una vez al iniciar
  List<UserModel> _allUsers = [];
  List<UserModel> _searchResults = [];
  final Set<String> _selectedIds = {};
  bool _loadingUsers = true;

  int _sentCount = 0;
  int _totalCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // carga todos los usuarios una sola vez (SQLite → Firestore como fallback)
  Future<void> _loadUsers() async {
    try {
      var users = await UserSyncService().getAllUsersLocal();
      if (users.isEmpty) {
        // fallback: Firestore directo (funciona en web)
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .limit(5000)
            .get();
        users = snap.docs
            .map((d) => UserModel.fromFirestore(d.id, d.data()))
            .toList();
      }
      if (mounted) setState(() => _allUsers = users);
    } catch (_) {
      // sin usuarios disponibles — la búsqueda quedará vacía
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  // ── búsqueda en-memoria (sin async, instantánea) ──────────────────────────

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = _allUsers
        .where(
          (u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q),
        )
        .take(50)
        .toList();
    setState(() => _searchResults = results);
  }

  void _toggleUser(UserModel user) {
    setState(() {
      if (_selectedIds.contains(user.id)) {
        _selectedIds.remove(user.id);
      } else {
        _selectedIds.add(user.id);
      }
    });
  }

  // ── envío ──────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final title = widget.titleController.text.trim();
    final message = widget.messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      _showSnack('Completa el título y el mensaje.');
      return;
    }

    if (_tab == _RecipientTab.specific && _selectedIds.isEmpty) {
      _showSnack('Selecciona al menos un usuario.');
      return;
    }

    List<String> tokens;

    try {
      if (_tab == _RecipientTab.all) {
        tokens = await UserSyncService().getActiveFcmTokens();
      } else {
        tokens = [];
        for (final id in _selectedIds) {
          final token = await UserSyncService().getUserFcmToken(id);
          if (token != null && token.isNotEmpty) tokens.add(token);
        }
      }

      if (tokens.isEmpty) {
        _showSnack('Ningún usuario tiene token FCM registrado.');
        return;
      }

      setState(() {
        _sendState = _SendState.sending;
        _sentCount = 0;
        _totalCount = tokens.length;
        _errorMessage = null;
      });

      const batchSize = 500;
      final firestore = FirebaseFirestore.instance;

      for (int i = 0; i < tokens.length; i += batchSize) {
        final batch = tokens.sublist(
          i,
          (i + batchSize).clamp(0, tokens.length),
        );

        await firestore.collection('notifications_queue').add({
          'title': title,
          'message': message,
          'fcm_tokens': batch,
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(
            () => _sentCount = (i + batch.length).clamp(0, tokens.length),
          );
        }
      }

      if (mounted) {
        setState(() => _sendState = _SendState.done);
        widget.titleController.clear();
        widget.messageController.clear();
        _selectedIds.clear();
        _searchController.clear();
        _searchResults.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sendState = _SendState.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _resetSendState() => setState(() {
    _sendState = _SendState.idle;
    _errorMessage = null;
  });

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.titleController,
        widget.messageController,
      ]),
      builder: (context, _) {
        final previewTitle = widget.titleController.text.isEmpty
            ? 'Título de la notificación'
            : widget.titleController.text;
        final previewMessage = widget.messageController.text.isEmpty
            ? 'Aquí aparece el mensaje que verán tus usuarios.'
            : widget.messageController.text;

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
                            _RecipientsSection(
                              tab: _tab,
                              onTabChanged: (t) => setState(() {
                                _tab = t;
                                _selectedIds.clear();
                                _searchController.clear();
                                _searchResults.clear();
                              }),
                              searchController: _searchController,
                              onSearchChanged: _onSearchChanged,
                              searchResults: _searchResults,
                              searching: _loadingUsers,
                              selectedIds: _selectedIds,
                              onToggleUser: _toggleUser,
                            ),
                            const SizedBox(height: 30),
                            const FormLabel('Título'),
                            TextInput(
                              controller: widget.titleController,
                              hintText: 'Ej: Tu resumen de gastos está listo',
                              maxLengthLabel: '0/40',
                            ),
                            const SizedBox(height: 24),
                            const FormLabel('Mensaje'),
                            TextAreaInput(
                              controller: widget.messageController,
                              hintText:
                                  'Escribe el mensaje que verán tus usuarios...',
                              maxLengthLabel: '0/160',
                              maxLines: 6,
                            ),
                            const SizedBox(height: 24),
                            _SendSection(
                              sendState: _sendState,
                              sentCount: _sentCount,
                              totalCount: _totalCount,
                              errorMessage: _errorMessage,
                              onSend: _send,
                              onReset: _resetSendState,
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
                            title: previewTitle,
                            message: previewMessage,
                            sendMode: PreviewSendMode.now,
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECCIÓN DESTINATARIOS
// ─────────────────────────────────────────────────────────────────────────────

class _RecipientsSection extends StatelessWidget {
  const _RecipientsSection({
    required this.tab,
    required this.onTabChanged,
    required this.searchController,
    required this.onSearchChanged,
    required this.searchResults,
    required this.searching,
    required this.selectedIds,
    required this.onToggleUser,
  });

  final _RecipientTab tab;
  final ValueChanged<_RecipientTab> onTabChanged;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final List<UserModel> searchResults;
  final bool searching;
  final Set<String> selectedIds;
  final ValueChanged<UserModel> onToggleUser;

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
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: ChoiceTile(
                label: 'Todos',
                icon: FluentIcons.people_20_regular,
                selected: tab == _RecipientTab.all,
                onTap: () => onTabChanged(_RecipientTab.all),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ChoiceTile(
                label: 'Específicos',
                icon: FluentIcons.search_20_regular,
                selected: tab == _RecipientTab.specific,
                onTap: () => onTabChanged(_RecipientTab.specific),
              ),
            ),
          ],
        ),
        if (tab == _RecipientTab.specific) ...[
          const SizedBox(height: 18),
          _UserSearchField(
            controller: searchController,
            onChanged: onSearchChanged,
            searching: searching,
          ),
          if (searchResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SearchResultsList(
              results: searchResults,
              selectedIds: selectedIds,
              onToggle: onToggleUser,
            ),
          ],
          if (selectedIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SelectedChips(
              selectedIds: selectedIds,
              allResults: searchResults,
              onRemove: onToggleUser,
            ),
          ],
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BÚSQUEDA
// ─────────────────────────────────────────────────────────────────────────────

class _UserSearchField extends StatelessWidget {
  const _UserSearchField({
    required this.controller,
    required this.onChanged,
    required this.searching,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool searching;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o email...',
        hintStyle: const TextStyle(fontSize: 16, color: AppColors.ink3),
        fillColor: const Color(0xFFF1F1EF),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.pink, width: 1.5),
        ),
        prefixIcon: const Icon(
          FluentIcons.search_20_regular,
          color: AppColors.ink3,
        ),
        suffixIcon: searching
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.pink,
                  ),
                ),
              )
            : null,
      ),
      style: const TextStyle(fontSize: 16, color: AppColors.ink),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESULTADOS — grid de chips 4 columnas
// ─────────────────────────────────────────────────────────────────────────────

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.results,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<UserModel> results;
  final Set<String> selectedIds;
  final ValueChanged<UserModel> onToggle;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.8,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final user = results[i];
        final selected = selectedIds.contains(user.id);
        final label = user.fullName.isNotEmpty ? user.fullName : user.email;
        return GestureDetector(
          onTap: () => onToggle(user),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.pink : const Color(0xFFF1F1EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: selected
                      ? AppColors.white.withValues(alpha: 0.25)
                      : AppColors.ink3.withValues(alpha: 0.15),
                  child: Text(
                    label.isNotEmpty ? label[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.white : AppColors.ink2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.white : AppColors.ink,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    FluentIcons.checkmark_circle_20_filled,
                    size: 14,
                    color: AppColors.white,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHIPS SELECCIONADOS
// ─────────────────────────────────────────────────────────────────────────────

class _SelectedChips extends StatelessWidget {
  const _SelectedChips({
    required this.selectedIds,
    required this.allResults,
    required this.onRemove,
  });

  final Set<String> selectedIds;
  final List<UserModel> allResults;
  final ValueChanged<UserModel> onRemove;

  @override
  Widget build(BuildContext context) {
    final selected = allResults
        .where((u) => selectedIds.contains(u.id))
        .toList();
    if (selected.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: selected.map((user) {
        final label = user.fullName.isNotEmpty ? user.fullName : user.email;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFCEBF2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.pinkDark,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => onRemove(user),
                child: const Icon(
                  FluentIcons.dismiss_12_regular,
                  size: 14,
                  color: AppColors.pinkDark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECCIÓN DE ENVÍO
// ─────────────────────────────────────────────────────────────────────────────

class _SendSection extends StatelessWidget {
  const _SendSection({
    required this.sendState,
    required this.sentCount,
    required this.totalCount,
    required this.errorMessage,
    required this.onSend,
    required this.onReset,
  });

  final _SendState sendState;
  final int sentCount;
  final int totalCount;
  final String? errorMessage;
  final VoidCallback onSend;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return switch (sendState) {
      _SendState.sending => _SendingBar(
        sentCount: sentCount,
        totalCount: totalCount,
      ),
      _SendState.done => _DoneMessage(onReset: onReset),
      _SendState.error => _ErrorMessage(
        message: errorMessage ?? 'Error desconocido',
        onReset: onReset,
      ),
      _SendState.idle => _SendButton(onSend: onSend),
    };
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onSend});
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onSend,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(82),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        icon: const Icon(FluentIcons.send_20_regular, size: 28),
        label: const Text('Enviar notificación'),
      ),
    );
  }
}

class _SendingBar extends StatelessWidget {
  const _SendingBar({required this.sentCount, required this.totalCount});
  final int sentCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? sentCount / totalCount : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.pink,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Enviando...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Text(
                '$sentCount / $totalCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFDDDDD8),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.pink),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneMessage extends StatelessWidget {
  const _DoneMessage({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7EF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            FluentIcons.checkmark_circle_20_filled,
            color: Color(0xFF1B9C5B),
            size: 28,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              '¡Notificación enviada correctamente!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B9C5B),
              ),
            ),
          ),
          TextButton(onPressed: onReset, child: const Text('Nueva')),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onReset});
  final String message;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEEBEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            FluentIcons.error_circle_20_regular,
            color: AppColors.danger,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 16, color: AppColors.danger),
            ),
          ),
          TextButton(onPressed: onReset, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
