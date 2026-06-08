import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_flags/country_flags.dart';
import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/dash_colors.dart';
import 'package:dashboard_analitycs/core/models/user_model.dart';
import 'package:dashboard_analitycs/core/services/country_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/user_metrics_service.dart';
import 'package:dashboard_analitycs/core/services/user_sync_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'empty_tables_component.dart';
import 'models.dart';
import 'shared_widgets.dart';
import 'user_detail_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.searchController});

  final TextEditingController searchController;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  static const _pageSize = 20;

  List<UserModel> _allUsers = [];
  bool _loading = true;

  String _statusFilter = 'Todos';
  String _planFilter = 'Todos';
  String _continentFilter = 'Todos';
  int _page = 0;

  // ── computed ────────────────────────────────────────────────────────────────

  List<UserModel> get _filtered {
    var list = _allUsers;

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

    switch (_statusFilter) {
      case 'Activos':
        list = list.where((u) => u.status).toList();
      case 'Inactivos':
        list = list.where((u) => !u.status).toList();
    }

    switch (_planFilter) {
      case 'Pro':
        list = list.where((u) => u.plan == 'pro').toList();
      case 'Gratuito':
        list = list.where((u) => u.plan != 'pro').toList();
    }

    list = [...list]..sort((a, b) {
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
    } catch (_) {
      // lista vacía si falla
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          'Usuarios',
          style: TextStyle(
            fontSize: 44,
            height: 1.03,
            fontWeight: FontWeight.w700,
            letterSpacing: -2,
            color: context.dc.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Todos los usuarios registrados en Trevo.',
          style: TextStyle(fontSize: 18, color: context.dc.ink2),
        ),
        const SizedBox(height: 28),

        // ── MÉTRICAS ─────────────────────────────────────────────────────────
        FutureBuilder<UserCounts>(
          future: UserMetricsService.future,
          builder: (_, snap) {
            final u = snap.data ?? UserCounts.empty;
            return ResponsiveGrid(
              minTileWidth: 220,
              children: [
                MetricCard(
                  label: 'Total registrados',
                  value: u.total > 0 ? '${u.total}' : '—',
                  badgeText: u.newToday > 0 ? '↑ ${u.newToday} hoy' : null,
                  badgeType: BadgeType.positive,
                  helperText: 'usuarios',
                ),
                MetricCard(
                  label: 'Plan Pro',
                  value: '${u.pro}',
                  accent: true,
                  valueSuffix: const FaIcon(
                    FontAwesomeIcons.crown,
                    color: AppColors.goldDark,
                    size: 24,
                  ),
                  badgeText: '${u.proPercent} del total',
                  badgeType: BadgeType.neutral,
                ),
                MetricCard(
                  label: 'Plan Gratuito',
                  value: '${u.free}',
                  badgeText: '${u.freePercent} del total',
                  badgeType: BadgeType.neutral,
                ),
                MetricCard(
                  label: 'Activos',
                  value: '${u.active}',
                  badgeText: '↑ ${u.activePercent}',
                  badgeType: BadgeType.positive,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),

        // ── PAÍSES ───────────────────────────────────────────────────────────
        const SectionHeader(label: 'DISTRIBUCIÓN GEOGRÁFICA', source: ''),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: PanelHeader(
                      title: 'Registros por país',
                      trailing: '',
                    ),
                  ),
                  _ContinentChips(
                    selected: _continentFilter,
                    onChanged: (v) => setState(() => _continentFilter = v),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FutureBuilder<List<CountryEntry>>(
                future: CountryMetricsService.allFuture,
                builder: (_, snap) {
                  final all = snap.data;
                  if (all == null) return const _CountryShimmerList();

                  final filtered = _continentFilter == 'Todos'
                      ? all
                      : all.where((e) {
                          if (_continentFilter == 'Otros') {
                            final c = CountryMetricsService.continentOf(e);
                            return c != 'América' && c != 'Europa';
                          }
                          return CountryMetricsService.continentOf(e) ==
                              _continentFilter;
                        }).toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Sin usuarios en este continente',
                          style: TextStyle(fontSize: 16, color: AppColors.ink3),
                        ),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (_, constraints) {
                      final wide = constraints.maxWidth > 700;
                      return wide
                          ? _CountryGrid(entries: filtered)
                          : _CountryList(entries: filtered);
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── LISTA DE USUARIOS ─────────────────────────────────────────────────
        const SectionHeader(label: 'LISTA DE USUARIOS', source: ''),
        const SizedBox(height: 14),

        // Filtros
        LayoutBuilder(
          builder: (_, constraints) {
            final wide = constraints.maxWidth > 800;
            final total = _loading ? null : _allUsers.length;
            final active = _loading
                ? null
                : _allUsers.where((u) => u.status).length;
            final inactive = _loading
                ? null
                : _allUsers.where((u) => !u.status).length;
            final pro = _loading
                ? null
                : _allUsers.where((u) => u.plan == 'pro').length;
            final free = _loading
                ? null
                : _allUsers.where((u) => u.plan != 'pro').length;

            final statusItems = [
              (label: 'Todos', count: total),
              (label: 'Activos', count: active),
              (label: 'Inactivos', count: inactive),
            ];
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
                      items: statusItems,
                      selected: _statusFilter,
                      onChanged: (v) => setState(() {
                        _statusFilter = v;
                        _page = 0;
                      }),
                    ),
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
                  items: statusItems,
                  selected: _statusFilter,
                  onChanged: (v) => setState(() {
                    _statusFilter = v;
                    _page = 0;
                  }),
                ),
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
// CONTINENT CHIPS
// ─────────────────────────────────────────────────────────────────────────────

class _ContinentChips extends StatelessWidget {
  const _ContinentChips({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const _options = ['Todos', 'América', 'Europa', 'Otros'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final active = opt == selected;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? context.dc.ink : context.dc.elevated,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? context.dc.bg : context.dc.ink2,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAÍSES — GRID Y LISTA
// ─────────────────────────────────────────────────────────────────────────────

class _CountryGrid extends StatelessWidget {
  const _CountryGrid({required this.entries});

  final List<CountryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: entries.map((e) => _CountryChip(entry: e)).toList(),
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({required this.entry});

  final CountryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.dc.elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FlagWidget(isoCode: entry.isoCode, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.dc.ink,
                ),
              ),
              Text(
                '${entry.count} · ${entry.percent}',
                style: TextStyle(fontSize: 13, color: context.dc.ink2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountryList extends StatelessWidget {
  const _CountryList({required this.entries});

  final List<CountryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          _CountryRowEntry(entry: entries[i]),
          if (i < entries.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _FlagWidget extends StatelessWidget {
  const _FlagWidget({required this.isoCode, required this.size});

  final String isoCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isoCode.isEmpty) {
      return SizedBox(
        width: size,
        height: size * 0.7,
        child: Icon(
          FluentIcons.globe_20_regular,
          size: size * 0.8,
          color: context.dc.ink3,
        ),
      );
    }
    return CountryFlag.fromCountryCode(
      isoCode,
      theme: ImageTheme(
        width: size,
        height: size * 0.7,
        shape: const RoundedRectangle(4),
      ),
    );
  }
}

class _CountryRowEntry extends StatelessWidget {
  const _CountryRowEntry({required this.entry});

  final CountryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: _FlagWidget(isoCode: entry.isoCode, size: 32),
        ),
        Expanded(
          child: Text(
            entry.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.dc.ink,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: entry.fraction,
              minHeight: 10,
              backgroundColor: context.dc.progressBg,
              valueColor: AlwaysStoppedAnimation(context.dc.progressFill),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          child: Text(
            '${entry.count}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.dc.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text(
            entry.percent,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 14, color: context.dc.ink2),
          ),
        ),
      ],
    );
  }
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
          SizedBox(width: 52),
          Expanded(flex: 4, child: _HeaderCell('Usuario')),
          Expanded(flex: 2, child: _HeaderCell('País')),
          SizedBox(width: 90, child: _HeaderCell('Plan', center: true)),
          SizedBox(width: 100, child: _HeaderCell('Estado', center: true)),
          SizedBox(width: 100, child: _HeaderCell('Registro', center: true)),
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
    required this.wide,
    required this.isLast,
    required this.onTap,
  });

  final UserModel user;
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
          child: wide ? _WideRow(user: user) : _NarrowCard(user: user),
        ),
      ],
    );
  }
}

class _WideRow extends StatelessWidget {
  const _WideRow({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _UserAvatar(user: user),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : '—',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.dc.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 13, color: context.dc.ink2),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.country.isNotEmpty ? user.country : '—',
              style: TextStyle(fontSize: 14, color: context.dc.ink2),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 90,
            child: Center(child: _PlanBadge(plan: user.plan)),
          ),
          SizedBox(
            width: 90,
            child: Center(child: _StatusDot(active: user.status)),
          ),
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                _fmtDate(user.createdAt),
                style: const TextStyle(fontSize: 13, color: AppColors.ink2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NarrowCard extends StatelessWidget {
  const _NarrowCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserAvatar(user: user),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : '—',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.dc.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 13, color: context.dc.ink2),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (user.country.isNotEmpty)
                      Text(
                        user.country,
                        style: TextStyle(fontSize: 13, color: context.dc.ink2),
                      ),
                    _PlanBadge(plan: user.plan),
                    _StatusDot(active: user.status),
                    Text(
                      _fmtDate(user.createdAt),
                      style: TextStyle(fontSize: 12, color: context.dc.ink3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return '—';
  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTES PEQUEÑOS
// ─────────────────────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final UserModel user;

  String get _initials {
    final parts = user.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.dc.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.dc.ink2,
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.plan});

  final String plan;

  @override
  Widget build(BuildContext context) {
    final isPro = plan == 'pro';
    if (isPro) {
      return Container(
        width: 32,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.goldLight,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: FaIcon(
            FontAwesomeIcons.crown,
            size: 13,
            color: AppColors.goldDark,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.dc.elevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Free',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.dc.ink2,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Activo' : 'Inactivo',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.success : AppColors.danger,
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
