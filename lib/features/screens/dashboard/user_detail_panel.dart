import 'dart:math' show min;

import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/dash_colors.dart';
import 'package:dashboard_analitycs/core/models/user_detail_model.dart';
import 'package:dashboard_analitycs/core/models/user_model.dart';
import 'package:dashboard_analitycs/core/services/user_detail_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showUserDetail(BuildContext context, UserModel user) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: AppColors.ink.withValues(alpha: 0.22),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, _) => _UserDetailSheet(user: user),
    transitionBuilder: (ctx, animation, _, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _UserDetailSheet extends StatefulWidget {
  const _UserDetailSheet({required this.user});
  final UserModel user;

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  UserDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await UserDetailService.fetch(widget.user);
      if (mounted) setState(() { _detail = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = min(520.0, MediaQuery.of(context).size.width.toDouble());
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: context.dc.elevated,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: SafeArea(
            child: _loading
                ? _SheetShimmer(onClose: () => Navigator.of(context).pop())
                : _detail == null
                    ? _SheetError(onClose: () => Navigator.of(context).pop())
                    : _SheetContent(
                        detail: _detail!,
                        onClose: () => Navigator.of(context).pop(),
                      ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _SheetContent extends StatelessWidget {
  const _SheetContent({required this.detail, required this.onClose});

  final UserDetail detail;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(detail: detail, onClose: onClose),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _InfoSection(detail: detail),
                _divider(context),
                _DeviceSection(detail: detail),
                _divider(context),
                _PermissionsSection(detail: detail),
                if (detail.planUser != null) ...[
                  _divider(context),
                  _PlanSection(plan: detail.planUser!),
                ],
                if (detail.subscriptions.isNotEmpty) ...[
                  _divider(context),
                  _SubscriptionsSection(subs: detail.subscriptions),
                ],
                if (detail.budgets.isNotEmpty) ...[
                  _divider(context),
                  _BudgetsSection(budgets: detail.budgets),
                ],
                if (detail.recentExpenses.isNotEmpty) ...[
                  _divider(context),
                  _ExpensesSection(expenses: detail.recentExpenses),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Divider(height: 1, thickness: 1, color: context.dc.divider),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.detail, required this.onClose});

  final UserDetail detail;
  final VoidCallback onClose;

  static const _palette = [
    AppColors.chartBlue,
    AppColors.chartGreen,
    AppColors.chartPurple,
    AppColors.chartPink,
    AppColors.chartAmber,
    AppColors.chartOlive,
  ];

  @override
  Widget build(BuildContext context) {
    final initial = detail.fullName.isNotEmpty
        ? detail.fullName[0].toUpperCase()
        : detail.email.isNotEmpty
            ? detail.email[0].toUpperCase()
            : '?';
    final color = _palette[detail.id.hashCode.abs() % _palette.length];
    final isPro = detail.plan == 'pro';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 24),
      color: context.dc.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.fullName.isNotEmpty ? detail.fullName : '—',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: context.dc.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.dc.ink2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _PlanChip(isPro: isPro),
                        _StatusChip(active: detail.status),
                        if (detail.typeRegister.isNotEmpty)
                          _RegisterChip(type: detail.typeRegister),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.dc.elevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FluentIcons.dismiss_20_regular,
                    size: 18,
                    color: context.dc.ink2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECCIONES
// ─────────────────────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.detail});
  final UserDetail detail;

  @override
  Widget build(BuildContext context) {
    final reg = DateTime.tryParse(detail.createdAt);
    return _Section(
      label: 'INFORMACIÓN',
      icon: FluentIcons.person_20_regular,
      children: [
        if (detail.country.isNotEmpty)
          _InfoRow(
            icon: FluentIcons.globe_20_regular,
            label: 'País',
            value: detail.country,
          ),
        if (detail.city.isNotEmpty)
          _InfoRow(
            icon: FluentIcons.location_20_regular,
            label: 'Ciudad',
            value: detail.city,
          ),
        _InfoRow(
          icon: FluentIcons.calendar_20_regular,
          label: 'Registro',
          value: reg != null ? _fmtDate(reg) : '—',
        ),
        if (detail.typeCurrency.isNotEmpty)
          _InfoRow(
            icon: FluentIcons.money_20_regular,
            label: 'Divisa',
            value: detail.typeCurrency,
          ),
        if (detail.updatedAt != null)
          _InfoRow(
            icon: FluentIcons.clock_20_regular,
            label: 'Actualizado',
            value: _fmtDate(detail.updatedAt!),
          ),
      ],
    );
  }
}

class _DeviceSection extends StatelessWidget {
  const _DeviceSection({required this.detail});
  final UserDetail detail;

  Widget _osIcon(BuildContext context, String branch) {
    final lower = branch.toLowerCase();
    if (lower.contains('ios') || lower.contains('apple')) {
      return FaIcon(FontAwesomeIcons.apple, size: 14, color: context.dc.ink3);
    } else if (lower.contains('android')) {
      return FaIcon(FontAwesomeIcons.android, size: 14, color: context.dc.ink3);
    }
    return Icon(FluentIcons.phone_20_regular, size: 16, color: context.dc.ink3);
  }

  @override
  Widget build(BuildContext context) {
    final hasDevice = detail.deviceBranch.isNotEmpty ||
        detail.deviceModel.isNotEmpty ||
        detail.appVersion.isNotEmpty;

    if (!hasDevice) return const SizedBox.shrink();

    return _Section(
      label: 'DISPOSITIVO',
      icon: FluentIcons.phone_20_regular,
      children: [
        if (detail.deviceBranch.isNotEmpty)
          _InfoRow(
            icon: FluentIcons.phone_20_regular,
            leadingWidget: _osIcon(context, detail.deviceBranch),
            label: 'Sistema',
            value: detail.deviceBranch,
          ),
        if (detail.deviceModel.isNotEmpty)
          _InfoRow(
            icon: FluentIcons.phone_laptop_20_regular,
            label: 'Modelo',
            value: detail.deviceModel,
          ),
        if (detail.appVersion.isNotEmpty)
          _InfoRow(
            icon: FluentIcons.app_recent_20_regular,
            label: 'App',
            value: 'v${detail.appVersion}',
          ),
        if (detail.deviceVersion.isNotEmpty)
          _InfoRow(
            icon: FluentIcons.code_20_regular,
            leadingWidget: _osIcon(context, detail.deviceBranch),
            label: 'Versión del sistema',
            value: detail.deviceVersion,
          ),
        if (detail.language.isNotEmpty)
          _InfoRow(
            icon: FluentIcons.translate_20_regular,
            label: 'Idioma',
            value: _langLabel(detail.language),
          ),
      ],
    );
  }
}

class _PermissionsSection extends StatelessWidget {
  const _PermissionsSection({required this.detail});
  final UserDetail detail;

  @override
  Widget build(BuildContext context) {
    final hasAny = detail.permCamera ||
        detail.permLocation ||
        detail.permNotifications ||
        detail.permVoice;
    // show section even if all denied
    final _ = hasAny;

    return _Section(
      label: 'PERMISOS',
      icon: FluentIcons.shield_20_regular,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _PermChip(label: 'Cámara', granted: detail.permCamera),
            _PermChip(label: 'Ubicación', granted: detail.permLocation),
            _PermChip(label: 'Notificaciones', granted: detail.permNotifications),
            _PermChip(label: 'Voz', granted: detail.permVoice),
          ],
        ),
      ],
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection({required this.plan});
  final UserPlanDetail plan;

  @override
  Widget build(BuildContext context) {
    final isActive = plan.status == 'active';
    final typeLabel = plan.typePlan == 'yearly' ? 'Anual' : 'Mensual';

    return _Section(
      label: 'PLAN',
      icon: FluentIcons.crown_20_regular,
      children: [
        _InfoRow(
          icon: FluentIcons.star_20_regular,
          label: 'Nombre',
          value: plan.planName.toUpperCase(),
        ),
        _InfoRow(
          icon: FluentIcons.arrow_repeat_all_20_regular,
          label: 'Tipo',
          value: typeLabel,
        ),
        _InfoRow(
          icon: FluentIcons.checkmark_circle_20_regular,
          label: 'Estado',
          valueWidget: _pill(
            isActive ? 'Activo' : 'Inactivo',
            isActive ? AppColors.success : AppColors.danger,
          ),
        ),
        if (plan.startDate != null)
          _InfoRow(
            icon: FluentIcons.calendar_20_regular,
            label: 'Inicio',
            value: _fmtDate(plan.startDate!),
          ),
        if (plan.endDate != null)
          _InfoRow(
            icon: FluentIcons.calendar_20_regular,
            label: 'Vence',
            value: _fmtDate(plan.endDate!),
          ),
        if (plan.subscriptionId.isNotEmpty)
          _InfoRow(
            icon: FluentIcons.tag_20_regular,
            label: 'ID suscripción',
            value: _subIdLabel(plan.subscriptionId),
          ),
      ],
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _SubscriptionsSection extends StatelessWidget {
  const _SubscriptionsSection({required this.subs});
  final List<PlatformSubscription> subs;

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: 'SUSCRIPCIONES',
      icon: FluentIcons.apps_list_20_regular,
      children: subs.map((s) => _SubItem(sub: s)).toList(),
    );
  }
}

class _SubItem extends StatelessWidget {
  const _SubItem({required this.sub});
  final PlatformSubscription sub;

  @override
  Widget build(BuildContext context) {
    final freqLabel = _fmtFrequency(sub.frequency);
    final amount = _fmtAmount(sub.price, sub.typeCurrency);
    final nextPay = sub.nextPaymentDate != null
        ? _fmtDate(sub.nextPaymentDate!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.dc.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(sub.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.dc.ink,
                  ),
                ),
                if (sub.categorieName.isNotEmpty)
                  Text(
                    sub.categorieName,
                    style: TextStyle(fontSize: 12, color: context.dc.ink3),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.dc.ink,
                ),
              ),
              Text(
                freqLabel,
                style: TextStyle(fontSize: 12, color: context.dc.ink2),
              ),
              if (nextPay != null)
                Text(
                  'Próximo: $nextPay',
                  style: TextStyle(fontSize: 11, color: context.dc.ink3),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetsSection extends StatelessWidget {
  const _BudgetsSection({required this.budgets});
  final List<BudgetEntry> budgets;

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: 'PRESUPUESTOS',
      icon: FluentIcons.wallet_20_regular,
      children: budgets.map((b) => _BudgetItem(budget: b)).toList(),
    );
  }
}

class _BudgetItem extends StatelessWidget {
  const _BudgetItem({required this.budget});
  final BudgetEntry budget;

  @override
  Widget build(BuildContext context) {
    final color = _parseHexColor(budget.colorHex);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.dc.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              budget.nameCategory,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.dc.ink,
              ),
            ),
          ),
          Text(
            _fmtAmount(budget.valueBudget, ''),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.dc.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesSection extends StatelessWidget {
  const _ExpensesSection({required this.expenses});
  final List<ExpenseEntry> expenses;

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: 'TRANSACCIONES RECIENTES',
      icon: FluentIcons.receipt_20_regular,
      children: expenses.map((e) => _ExpenseItem(entry: e)).toList(),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  const _ExpenseItem({required this.entry});
  final ExpenseEntry entry;

  @override
  Widget build(BuildContext context) {
    final isExpense = entry.isExpense;
    final sign = isExpense ? '-' : '+';
    final color = isExpense ? AppColors.danger : AppColors.success;
    final date =
        entry.dateExpenses != null ? _fmtDate(entry.dateExpenses!) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.dc.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            entry.emoji.isNotEmpty ? entry.emoji : (isExpense ? '📤' : '📥'),
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description.isNotEmpty
                      ? entry.description
                      : entry.categorieName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.dc.ink,
                  ),
                ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: context.dc.ink3),
                  ),
              ],
            ),
          ),
          Text(
            '$sign${_fmtAmount(entry.price, entry.typeCurrency)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PEQUEÑOS COMPONENTES
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.icon,
    required this.children,
  });

  final String label;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: context.dc.ink3),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: context.dc.ink3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.leadingWidget,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Widget? leadingWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: leadingWidget ?? Icon(icon, size: 16, color: context.dc.ink3),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: context.dc.ink2),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: valueWidget ??
                  Text(
                    value ?? '—',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.dc.ink,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermChip extends StatelessWidget {
  const _PermChip({
    required this.label,
    required this.granted,
  });

  final String label;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: granted
            ? AppColors.success.withValues(alpha: 0.10)
            : AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted
                ? FluentIcons.checkmark_circle_20_filled
                : FluentIcons.dismiss_circle_20_filled,
            size: 14,
            color: granted ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: granted ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.isPro});
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPro ? AppColors.goldLight : AppColors.fieldBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPro) ...[
            const FaIcon(FontAwesomeIcons.crown,
                size: 10, color: AppColors.goldDark),
            const SizedBox(width: 5),
          ],
          Text(
            isPro ? 'Pro' : 'Free',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isPro ? AppColors.goldDark : AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }
}

class _RegisterChip extends StatelessWidget {
  const _RegisterChip({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isGoogle = type.toLowerCase() == 'google';
    final isApple = type.toLowerCase() == 'apple';

    final Widget iconWidget = isGoogle
        ? const FaIcon(FontAwesomeIcons.google, size: 11, color: AppColors.ink2)
        : isApple
            ? const FaIcon(FontAwesomeIcons.apple, size: 11, color: AppColors.ink2)
            : const Icon(FluentIcons.mail_20_regular, size: 14, color: AppColors.ink2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(width: 5),
          Text(
            type[0].toUpperCase() + type.substring(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class _SheetShimmer extends StatelessWidget {
  const _SheetShimmer({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 20, 24),
          color: context.dc.surface,
          child: Row(
            children: [
              _box(context, 64, 64, radius: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(context, 140, 20),
                    const SizedBox(height: 8),
                    _box(context, 200, 14),
                    const SizedBox(height: 12),
                    _box(context, 100, 24, radius: 999),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.dc.elevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(FluentIcons.dismiss_20_regular,
                      size: 18, color: context.dc.ink2),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                6,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _box(context, double.infinity, 48, radius: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _box(BuildContext context, double w, double h, {double radius = 8}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: context.dc.shimmerBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR
// ─────────────────────────────────────────────────────────────────────────────

class _SheetError extends StatelessWidget {
  const _SheetError({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.dc.elevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(FluentIcons.dismiss_20_regular,
                    size: 18, color: context.dc.ink2),
              ),
            ),
          ),
        ),
        const Spacer(),
        Icon(FluentIcons.warning_20_regular, size: 48, color: context.dc.ink3),
        const SizedBox(height: 12),
        Text(
          'No se pudo cargar la información',
          style: TextStyle(fontSize: 16, color: context.dc.ink2),
        ),
        const Spacer(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) {
  const months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  final period = d.hour < 12 ? 'a.m.' : 'p.m.';
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final min = d.minute.toString().padLeft(2, '0');
  return '${d.day} de ${months[d.month - 1]} ${d.year} $h12:$min $period';
}

String _langLabel(String code) {
  final parts = code.toLowerCase().split(RegExp(r'[-_]'));
  final lang = parts.first;
  final region = parts.length > 1 ? parts[1] : '';
  const latinRegions = {
    'co', 'mx', 'ar', 'cl', 'pe', 've', 'bo', 'ec',
    'uy', 'py', 'cr', 'pa', 'hn', 'sv', 'ni', 'do',
    'cu', 'pr', 'gt', '419',
  };
  switch (lang) {
    case 'es':
      if (region == 'es') return 'Español (España)';
      if (region.isEmpty || latinRegions.contains(region)) return 'Español (Latinoamérica)';
      return 'Español';
    case 'en':
      if (region == 'us') return 'Inglés (EE.UU.)';
      if (region == 'gb') return 'Inglés (Reino Unido)';
      return 'Inglés';
    case 'pt':
      if (region == 'br') return 'Portugués (Brasil)';
      if (region == 'pt') return 'Portugués (Portugal)';
      return 'Portugués';
    case 'fr': return 'Francés';
    case 'de': return 'Alemán';
    case 'it': return 'Italiano';
    case 'ja': return 'Japonés';
    case 'zh': return 'Chino';
    case 'ko': return 'Coreano';
    case 'ru': return 'Ruso';
    default: return code;
  }
}

String _subIdLabel(String id) {
  final lower = id.toLowerCase();
  if (lower.contains('yearly') || lower.contains('annual')) return 'Suscripción anual';
  if (lower.contains('monthly')) return 'Suscripción mensual';
  return id;
}

String _fmtFrequency(String freq) {
  switch (freq.toLowerCase()) {
    case 'monthly':
      return 'Mensual';
    case 'yearly':
      return 'Anual';
    case 'weekly':
      return 'Semanal';
    default:
      return freq;
  }
}

String _fmtAmount(double amount, String currency) {
  final rounded = amount.toStringAsFixed(0);
  final formatted = rounded.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  final cur = currency.isNotEmpty ? ' $currency' : '';
  return '\$$formatted$cur';
}

Color _parseHexColor(String hex) {
  try {
    final cleaned = hex.toLowerCase().replaceFirst('0xff', '').replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  } catch (_) {
    return AppColors.ink3;
  }
}
