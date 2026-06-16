import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/dash_colors.dart';
import 'package:dashboard_analitycs/core/models/revenuecat_metrics_model.dart';
import 'package:dashboard_analitycs/core/models/user_model.dart';
import 'package:dashboard_analitycs/core/services/country_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/revenuecat_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/user_sync_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'dashboard_provider.dart';
import 'empty_tables_component.dart';
import 'geo_donut_panel.dart';
import 'models.dart';
import 'shared_widgets.dart';
import 'user_detail_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PLAN SUMMARY — lightweight plan data for the list view
// ─────────────────────────────────────────────────────────────────────────────

class _PlanSummary {
  final String planName;
  final String typePlan;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  const _PlanSummary({
    required this.planName,
    required this.typePlan,
    required this.status,
    this.startDate,
    this.endDate,
  });

  factory _PlanSummary.fromMap(Map<String, dynamic> d) => _PlanSummary(
    planName: d['plan_name'] as String? ?? '',
    typePlan: (d['type_plan'] as String? ?? '').toLowerCase(),
    status: (d['status'] as String? ?? '').toLowerCase(),
    startDate: _parseTs(d['start_date']),
    endDate: _parseTs(d['end_date']),
  );

  bool get willNotRenew =>
      status == 'cancelled' ||
      status == 'will_not_renew' ||
      status == 'revoked' ||
      status == 'expired';
}

DateTime? _parseTs(dynamic val) {
  if (val == null) return null;
  if (val is Timestamp) return val.toDate();
  if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class UsersPage extends StatefulWidget {
  const UsersPage({
    super.key,
    required this.searchController,
    required this.range,
  });

  final TextEditingController searchController;
  final DateRange range;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  static const _pageSize = 20;

  List<UserModel> _allUsers = [];
  Map<String, _PlanSummary?> _planData = {};
  bool _loading = true;

  String _planFilter = 'Todos';
  String _continentFilter = 'Todos';
  int _page = 0;

  // ── lifecycle ────────────────────────────────────────────────────────────────

  @override
  void didUpdateWidget(UsersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) setState(() {});
  }

  // ── computed ────────────────────────────────────────────────────────────────

  List<UserModel> get _dateFiltered {
    final start = DashboardProvider.rangeStart(widget.range);
    if (start == null) return _allUsers;
    return _allUsers.where((u) {
      final d = DateTime.tryParse(u.createdAt);
      return d != null && d.isAfter(start);
    }).toList();
  }

  List<UserModel> get _filtered {
    var list = _dateFiltered;

    final q = widget.searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (u) =>
                u.fullName.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q),
          )
          .toList();
    }

    switch (_planFilter) {
      case 'Pro':
        list = list.where((u) => u.plan == 'pro').toList();
      case 'Gratuito':
        list = list.where((u) => u.plan != 'pro').toList();
    }

    list = [...list]
      ..sort((a, b) {
        final da = DateTime.tryParse(a.createdAt) ?? DateTime(0);
        final db = DateTime.tryParse(b.createdAt) ?? DateTime(0);
        return db.compareTo(da);
      });

    return list;
  }

  int get _pageCount => ((_filtered.length / _pageSize).ceil()).clamp(1, 9999);

  List<UserModel> get _pageUsers {
    final f = _filtered;
    final start = _page * _pageSize;
    if (start >= f.length) return [];
    return f.sublist(start, (start + _pageSize).clamp(0, f.length));
  }

  // ── lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadUsers();
    widget.searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearch);
    super.dispose();
  }

  void _onSearch() => setState(() => _page = 0);

  Future<void> _loadUsers() async {
    try {
      var users = await UserSyncService().getAllUsersLocal();
      if (users.isEmpty || users.every((u) => u.country.isEmpty)) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .limit(10000)
            .get();
        users = snap.docs
            .map((d) => UserModel.fromFirestore(d.id, d.data()))
            .toList();
      }
      if (mounted) setState(() => _allUsers = users);
      _loadPlanData(users);
    } catch (_) {
      // lista vacía si falla
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPlanData(List<UserModel> users) async {
    try {
      final results = await Future.wait(users.map(_fetchPlanForUser));
      final map = Map<String, _PlanSummary?>.fromEntries(results);
      if (mounted) setState(() => _planData = map);
    } catch (_) {}
  }

  Future<MapEntry<String, _PlanSummary?>> _fetchPlanForUser(
    UserModel user,
  ) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('plan_user')
          .limit(1)
          .get();
      final plan = snap.docs.isNotEmpty
          ? _PlanSummary.fromMap(snap.docs.first.data())
          : null;
      return MapEntry(user.id, plan);
    } catch (_) {
      return MapEntry(user.id, null);
    }
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),

        // ── MÉTRICAS ─────────────────────────────────────────────────────────
        StreamBuilder<RevenueCatMetrics?>(
          stream: RevenueCatMetricsService.stream(),
          builder: (context, rcSnap) {
            final rc = rcSnap.data;
            final u = _loading
                ? UserCounts.empty
                : UserCounts.fromUsers(_dateFiltered);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveGrid(
                  minTileWidth: 200,
                  children: [
                    MetricCard(
                      label: 'Usuarios activos',
                      value: _loading ? '—' : '${u.active}',
                      badgeText: u.activePercent,
                      badgeType: BadgeType.positive,
                    ),
                    MetricCard(
                      label: 'Usuarios gratuitos',
                      value: _loading ? '—' : '${u.free}',
                      badgeText: '${u.freePercent} del total',
                      badgeType: BadgeType.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SubGroupLabel(label: 'FREE TRIAL'),
                const SizedBox(height: 10),
                ResponsiveGrid(
                  minTileWidth: 200,
                  children: [
                    MetricCard(
                      label: 'Free trial activo',
                      value: rc != null ? '${rc.overview.activeTrials}' : '—',
                      badgeText: 'RevenueCat',
                      badgeType: BadgeType.neutral,
                    ),
                    MetricCard(
                      label: 'Free trial cancelado',
                      value: '—',
                      badgeType: BadgeType.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SubGroupLabel(label: 'PLAN ACTIVO'),
                const SizedBox(height: 10),
                ResponsiveGrid(
                  minTileWidth: 200,
                  children: [
                    MetricCard(
                      label: 'Mensual',
                      value: rc != null
                          ? '${rc.overview.monthlySubscriptions}'
                          : '—',
                      badgeType: BadgeType.neutral,
                    ),
                    MetricCard(
                      label: 'Anual',
                      value: rc != null
                          ? '${rc.overview.annualSubscriptions}'
                          : '—',
                      badgeType: BadgeType.neutral,
                    ),
                    MetricCard(
                      label: 'No renovarán',
                      value: '—',
                      badgeType: BadgeType.neutral,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),

        // ── PAÍSES ───────────────────────────────────────────────────────────
        const SectionHeader(label: 'DISTRIBUCIÓN GEOGRÁFICA', source: ''),
        const SizedBox(height: 14),
        Builder(
          builder: (context) {
            if (_loading) {
              return Panel(child: const _CountryShimmerList());
            }

            final countMap = <String, int>{};
            for (final u in _dateFiltered) {
              final name = u.country.trim();
              countMap[name] = (countMap[name] ?? 0) + 1;
            }
            final all = CountryMetricsService.fromCounts(countMap);

            return Panel(
              child: GeoDonutPanel(
                allEntries: all,
                filter: _continentFilter,
                onFilterChanged: (v) => setState(() => _continentFilter = v),
              ),
            );
          },
        ),
        const SizedBox(height: 28),

        // ── LISTA DE USUARIOS ─────────────────────────────────────────────────
        const SectionHeader(label: 'LISTA DE USUARIOS', source: ''),
        const SizedBox(height: 14),

        // Filtros
        LayoutBuilder(
          builder: (_, constraints) {
            final wide = constraints.maxWidth > 800;
            final total = _loading ? null : _dateFiltered.length;
            final pro = _loading
                ? null
                : _dateFiltered.where((u) => u.plan == 'pro').length;
            final free = _loading
                ? null
                : _dateFiltered.where((u) => u.plan != 'pro').length;

            final planItems = [
              (label: 'Todos', count: total),
              (label: 'Pro', count: pro),
              (label: 'Gratuito', count: free),
            ];

            if (wide) {
              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: SearchField(controller: widget.searchController),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _FilterBar(
                      items: planItems,
                      selected: _planFilter,
                      onChanged: (v) => setState(() {
                        _planFilter = v;
                        _page = 0;
                      }),
                    ),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchField(controller: widget.searchController),
                const SizedBox(height: 12),
                _FilterBar(
                  items: planItems,
                  selected: _planFilter,
                  onChanged: (v) => setState(() {
                    _planFilter = v;
                    _page = 0;
                  }),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),

        // Tabla / lista
        Panel(
          child: _loading
              ? const _UsersShimmer()
              : _allUsers.isEmpty
              ? const _EmptyUsers()
              : _pageUsers.isEmpty
              ? const _EmptyFilter()
              : LayoutBuilder(
                  builder: (_, constraints) {
                    final wide = constraints.maxWidth > 700;
                    return Column(
                      children: [
                        if (wide) const _TableHeader(),
                        ...List.generate(_pageUsers.length, (i) {
                          final user = _pageUsers[i];
                          return _UserRow(
                            user: user,
                            plan: _planData[user.id],
                            wide: wide,
                            isLast: i == _pageUsers.length - 1,
                            onTap: () => showUserDetail(context, user),
                          );
                        }),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: 14),

        // Paginación
        if (!_loading && _allUsers.isNotEmpty)
          _PaginationBar(
            page: _page,
            pageCount: _pageCount,
            total: _filtered.length,
            onPrev: _page > 0 ? () => setState(() => _page--) : null,
            onNext: _page < _pageCount - 1
                ? () => setState(() => _page++)
                : null,
          ),
        const SizedBox(height: 48),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTROS
// ─────────────────────────────────────────────────────────────────────────────

class _SubGroupLabel extends StatelessWidget {
  const _SubGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: context.dc.ink3,
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<({String label, int? count})> items;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.dc.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(items[i].label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: items[i].label == selected
                        ? context.dc.chipSelected
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        items[i].label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: items[i].label == selected
                              ? context.dc.ink
                              : context.dc.ink2,
                        ),
                      ),
                      if (items[i].count != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _compactNum(items[i].count!),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: items[i].label == selected
                                ? context.dc.ink2
                                : context.dc.ink3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (i < items.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

String _compactNum(int n) {
  if (n >= 1000000) {
    final v = n / 1000000;
    return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    final v = n / 1000;
    return '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}k';
  }
  return '$n';
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLA DE USUARIOS
// ─────────────────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: const [
          SizedBox(width: 48, child: _HeaderCell('País', center: true)),
          Expanded(flex: 3, child: _HeaderCell('Correo')),
          SizedBox(width: 84, child: _HeaderCell('Producto', center: true)),
          SizedBox(width: 84, child: _HeaderCell('Comprado', center: true)),
          SizedBox(width: 84, child: _HeaderCell('Expira', center: true)),
          SizedBox(width: 64, child: _HeaderCell('Revenue', center: true)),
          SizedBox(width: 110, child: _HeaderCell('Tipo', center: true)),
          Expanded(flex: 2, child: _HeaderCell('Renovación')),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: context.dc.ink3,
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.plan,
    required this.wide,
    required this.isLast,
    required this.onTap,
  });

  final UserModel user;
  final _PlanSummary? plan;
  final bool wide;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: wide
              ? _WideRow(user: user, plan: plan)
              : _NarrowCard(user: user, plan: plan),
        ),
      ],
    );
  }
}

class _WideRow extends StatelessWidget {
  const _WideRow({required this.user, required this.plan});

  final UserModel user;
  final _PlanSummary? plan;

  @override
  Widget build(BuildContext context) {
    final isTrial = plan != null && plan!.typePlan.contains('trial');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Center(
              child: FlagWidget(
                isoCode: CountryMetricsService.isoFor(user.country),
                size: 26,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              user.email.isNotEmpty ? user.email : '—',
              style: TextStyle(fontSize: 13, color: context.dc.ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 84,
            child: Center(
              child: Text(
                plan != null && plan!.planName.isNotEmpty
                    ? plan!.planName
                    : (user.plan == 'pro' ? 'Pro' : 'Free'),
                style: TextStyle(fontSize: 13, color: context.dc.ink2),
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Center(
              child: Text(
                _relativeFrom(plan?.startDate),
                style: TextStyle(fontSize: 12, color: context.dc.ink2),
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _relativeTo(plan?.endDate),
                    style: TextStyle(fontSize: 12, color: context.dc.ink2),
                  ),
                  if (isTrial)
                    Text(
                      '(prueba)',
                      style: TextStyle(fontSize: 10, color: context.dc.ink3),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 64,
            child: Center(
              child: Text(
                '—',
                style: TextStyle(fontSize: 13, color: context.dc.ink3),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Center(child: _TypePill(plan: plan, userPlan: user.plan)),
          ),
          Expanded(
            flex: 2,
            child: (plan?.willNotRenew ?? false)
                ? const _RenovacionPill()
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _NarrowCard extends StatelessWidget {
  const _NarrowCard({required this.user, required this.plan});

  final UserModel user;
  final _PlanSummary? plan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.email.isNotEmpty ? user.email : '—',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.dc.ink,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FlagWidget(
                isoCode: CountryMetricsService.isoFor(user.country),
                size: 22,
              ),
              _TypePill(plan: plan, userPlan: user.plan),
              if (plan?.willNotRenew ?? false) const _RenovacionPill(),
              if (plan?.startDate != null)
                Text(
                  _relativeFrom(plan!.startDate),
                  style: TextStyle(fontSize: 12, color: context.dc.ink3),
                ),
              if (plan?.endDate != null)
                Text(
                  _relativeTo(plan!.endDate),
                  style: TextStyle(fontSize: 12, color: context.dc.ink3),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTES PEQUEÑOS
// ─────────────────────────────────────────────────────────────────────────────

String _relativeFrom(DateTime? dt) {
  if (dt == null) return '—';
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 365) {
    final y = (diff.inDays / 365).floor();
    return 'hace $y año${y == 1 ? '' : 's'}';
  }
  if (diff.inDays > 30) {
    final m = (diff.inDays / 30).floor();
    return 'hace $m mes${m == 1 ? '' : 'es'}';
  }
  if (diff.inDays > 0) return 'hace ${diff.inDays} día${diff.inDays == 1 ? '' : 's'}';
  if (diff.inHours > 0) return 'hace ${diff.inHours} hora${diff.inHours == 1 ? '' : 's'}';
  if (diff.inMinutes > 0) return 'hace ${diff.inMinutes} min';
  return 'ahora';
}

String _relativeTo(DateTime? dt) {
  if (dt == null) return '—';
  final diff = dt.difference(DateTime.now());
  if (diff.isNegative) return 'Vencido';
  if (diff.inDays > 365) {
    final y = (diff.inDays / 365).floor();
    return 'en $y año${y == 1 ? '' : 's'}';
  }
  if (diff.inDays > 30) {
    final m = (diff.inDays / 30).floor();
    return 'en $m mes${m == 1 ? '' : 'es'}';
  }
  if (diff.inDays > 0) return 'en ${diff.inDays} día${diff.inDays == 1 ? '' : 's'}';
  if (diff.inHours > 0) return 'en ${diff.inHours} hora${diff.inHours == 1 ? '' : 's'}';
  return 'hoy';
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.plan, required this.userPlan});

  final _PlanSummary? plan;
  final String userPlan;

  @override
  Widget build(BuildContext context) {
    if (plan == null || plan!.typePlan.isEmpty) {
      if (userPlan == 'pro') {
        return _pill(context, 'NEW SUB', AppColors.goldLight, AppColors.goldDark);
      }
      return _pill(context, 'FREE', context.dc.elevated, context.dc.ink2);
    }

    final tp = plan!.typePlan;
    final cancelled = plan!.status.contains('cancel') ||
        plan!.status.contains('revok') ||
        tp.contains('cancel');

    if (tp.contains('trial')) {
      if (cancelled) {
        return _pill(
          context,
          'TRIAL CANCELADO',
          AppColors.danger.withValues(alpha: 0.12),
          AppColors.danger,
        );
      }
      return _pill(
        context,
        'TRIAL',
        AppColors.chartBlue.withValues(alpha: 0.12),
        AppColors.chartBlue,
      );
    }
    if (tp.contains('new')) {
      return _pill(context, 'NEW SUB', AppColors.goldLight, AppColors.goldDark);
    }
    if (tp.contains('renew')) {
      return _pill(context, 'RENOVACIÓN', AppColors.goldLight, AppColors.goldDark);
    }
    if (userPlan == 'pro') {
      return _pill(context, 'NEW SUB', AppColors.goldLight, AppColors.goldDark);
    }
    return _pill(context, 'FREE', context.dc.elevated, context.dc.ink2);
  }

  Widget _pill(BuildContext context, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _RenovacionPill extends StatelessWidget {
  const _RenovacionPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'CANCELÓ FUTURAS SUSCRIPCIONES',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.danger,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGINACIÓN
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.pageCount,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int pageCount;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$total usuario${total == 1 ? '' : 's'}',
          style: TextStyle(fontSize: 14, color: context.dc.ink2),
        ),
        const Spacer(),
        Text(
          'Página ${page + 1} de $pageCount',
          style: TextStyle(fontSize: 14, color: context.dc.ink2),
        ),
        const SizedBox(width: 12),
        _PageBtn(icon: FluentIcons.chevron_left_20_regular, onTap: onPrev),
        const SizedBox(width: 8),
        _PageBtn(icon: FluentIcons.chevron_right_20_regular, onTap: onNext),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? context.dc.surface : context.dc.elevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? context.dc.ink : context.dc.ink3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ESTADOS VACÍOS Y SHIMMERS
// ─────────────────────────────────────────────────────────────────────────────

class _UsersShimmer extends StatelessWidget {
  const _UsersShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        6,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < 5 ? 14 : 0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.dc.shimmerBase,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: context.dc.shimmerBase,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: context.dc.shimmerLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryShimmerList extends StatelessWidget {
  const _CountryShimmerList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i < 3 ? 14 : 0),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.dc.shimmerBase,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: context.dc.shimmerBase,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 160,
                height: 10,
                decoration: BoxDecoration(
                  color: context.dc.shimmerBase,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyUsers extends StatelessWidget {
  const _EmptyUsers();

  @override
  Widget build(BuildContext context) => const EmptyTablesComponent(
    title: 'Sin usuarios aún',
    description: 'Los usuarios aparecerán aquí una vez que se registren.',
  );
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter();

  @override
  Widget build(BuildContext context) => const EmptyTablesComponent(
    title: 'Sin resultados',
    description: 'Intenta con otro filtro o búsqueda.',
  );
}
