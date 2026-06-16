import 'package:country_flags/country_flags.dart';
import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/dash_colors.dart';
import 'package:dashboard_analitycs/core/services/country_metrics_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GEO DONUT PANEL  — componente compartido entre Usuarios y Vista General
// ─────────────────────────────────────────────────────────────────────────────

const _continentOptions = ['Todos', 'América', 'Europa', 'Asia', 'Otros'];

const _continentColors = {
  'América': AppColors.chartBlue,
  'Europa': AppColors.chartPurple,
  'Asia': AppColors.chartGreen,
  'Otros': AppColors.chartPink,
};

class GeoDonutPanel extends StatefulWidget {
  const GeoDonutPanel({
    super.key,
    required this.allEntries,
    required this.filter,
    required this.onFilterChanged,
  });

  final List<CountryEntry> allEntries;
  final String filter;
  final ValueChanged<String> onFilterChanged;

  @override
  State<GeoDonutPanel> createState() => _GeoDonutPanelState();
}

class _GeoDonutPanelState extends State<GeoDonutPanel> {
  static const _pageSize = 5;
  int _page = 0;
  int? _touchedIndex;

  @override
  void didUpdateWidget(GeoDonutPanel old) {
    super.didUpdateWidget(old);
    if (old.filter != widget.filter) {
      setState(() {
        _page = 0;
        _touchedIndex = null;
      });
    }
  }

  List<CountryEntry> get _filtered {
    if (widget.filter == 'Todos') return widget.allEntries;
    return widget.allEntries.where((e) {
      if (widget.filter == 'Otros') {
        final c = CountryMetricsService.continentOf(e);
        return c != 'América' && c != 'Europa' && c != 'Asia';
      }
      return CountryMetricsService.continentOf(e) == widget.filter;
    }).toList();
  }

  int get _totalPages => ((_filtered.length / _pageSize).ceil()).clamp(1, 9999);

  List<CountryEntry> get _pageSlices {
    final src = _filtered;
    final start = _page * _pageSize;
    if (start >= src.length) return [];
    return src.sublist(start, (start + _pageSize).clamp(0, src.length));
  }

  Color _colorForSlice(int index, CountryEntry entry) {
    if (entry.name == 'Otros') return AppColors.chartPink.withAlpha(120);
    final continent = CountryMetricsService.continentOf(entry);
    final base = _continentColors[continent] ?? AppColors.chartBlue;
    const alphas = [255, 210, 175, 145, 120];
    return base.withAlpha(alphas[index.clamp(0, alphas.length - 1)]);
  }

  @override
  Widget build(BuildContext context) {
    final slices = _pageSlices;
    final total = _filtered.fold(0, (s, e) => s + e.count);
    final isEmpty = _filtered.isEmpty;

    final continentTotals = <String, int>{};
    for (final e in widget.allEntries) {
      final c = CountryMetricsService.continentOf(e);
      continentTotals[c] = (continentTotals[c] ?? 0) + e.count;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 600;
            if (wide) {
              return Row(
                children: [
                  const Expanded(
                    child: _PanelTitle(title: 'Distribución geográfica'),
                  ),
                  _ContinentFilter(
                    selected: widget.filter,
                    onChanged: widget.onFilterChanged,
                    continentTotals: continentTotals,
                    allTotal: widget.allEntries.fold(0, (s, e) => s + e.count),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PanelTitle(title: 'Distribución geográfica'),
                const SizedBox(height: 12),
                _ContinentFilter(
                  selected: widget.filter,
                  onChanged: widget.onFilterChanged,
                  continentTotals: continentTotals,
                  allTotal: widget.allEntries.fold(0, (s, e) => s + e.count),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Sin usuarios en este continente',
                style: TextStyle(fontSize: 15, color: context.dc.ink3),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 620;
              final donut = _DonutChart(
                slices: slices,
                total: total,
                touchedIndex: _touchedIndex,
                colorFor: _colorForSlice,
                onTouch: (i) => setState(() => _touchedIndex = i),
              );
              final ranking = _CountryRanking(
                slices: slices,
                total: total,
                touchedIndex: _touchedIndex,
                colorFor: _colorForSlice,
              );

              if (wide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 260, height: 260, child: donut),
                      const SizedBox(width: 28),
                      Expanded(child: ranking),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  SizedBox(height: 240, child: donut),
                  const SizedBox(height: 20),
                  ranking,
                ],
              );
            },
          ),
        if (!isEmpty && _totalPages > 1) ...[
          const SizedBox(height: 20),
          _GeoPagination(
            page: _page,
            totalPages: _totalPages,
            totalCount: _filtered.length,
            pageSize: _pageSize,
            onPrev: _page > 0
                ? () => setState(() {
                    _page--;
                    _touchedIndex = null;
                  })
                : null,
            onNext: _page < _totalPages - 1
                ? () => setState(() {
                    _page++;
                    _touchedIndex = null;
                  })
                : null,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: context.dc.ink,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.slices,
    required this.total,
    required this.touchedIndex,
    required this.colorFor,
    required this.onTouch,
  });

  final List<CountryEntry> slices;
  final int total;
  final int? touchedIndex;
  final Color Function(int, CountryEntry) colorFor;
  final ValueChanged<int?> onTouch;

  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    for (int i = 0; i < slices.length; i++) {
      final e = slices[i];
      final isTouched = touchedIndex == i;
      final color = colorFor(i, e);
      sections.add(
        PieChartSectionData(
          value: e.count.toDouble(),
          color: color,
          radius: isTouched ? 54 : 46,
          title: '',
          showTitle: false,
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 72,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            if (event is FlTapUpEvent || event is FlLongPressEnd) {
              onTouch(null);
              return;
            }
            final idx = response?.touchedSection?.touchedSectionIndex;
            onTouch(idx);
          },
        ),
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CountryRanking extends StatelessWidget {
  const _CountryRanking({
    required this.slices,
    required this.total,
    required this.touchedIndex,
    required this.colorFor,
  });

  final List<CountryEntry> slices;
  final int total;
  final int? touchedIndex;
  final Color Function(int, CountryEntry) colorFor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < slices.length; i++) ...[
          _RankRow(
            rank: i + 1,
            entry: slices[i],
            total: total,
            color: colorFor(i, slices[i]),
            highlighted: touchedIndex == i,
          ),
          if (i < slices.length - 1)
            Divider(height: 20, thickness: 1, color: context.dc.divider),
        ],
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.entry,
    required this.total,
    required this.color,
    required this.highlighted,
  });

  final int rank;
  final CountryEntry entry;
  final int total;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? entry.count / total : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? color.withAlpha(14) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.dc.ink3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          FlagWidget(isoCode: entry.isoCode, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                color: context.dc.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: context.dc.divider,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text(
              '${entry.count}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.dc.ink,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 44,
            child: Text(
              entry.percent,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: context.dc.ink2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ContinentFilter extends StatelessWidget {
  const _ContinentFilter({
    required this.selected,
    required this.onChanged,
    required this.continentTotals,
    required this.allTotal,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final Map<String, int> continentTotals;
  final int allTotal;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _continentOptions.map((opt) {
        final active = opt == selected;
        final color = opt == 'Todos'
            ? context.dc.ink
            : (_continentColors[opt] ?? AppColors.chartAmber);
        return GestureDetector(
          onTap: () => onChanged(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? (opt == 'Todos' ? context.dc.ink : color.withAlpha(22))
                  : context.dc.elevated,
              borderRadius: BorderRadius.circular(20),
              border: active && opt != 'Todos'
                  ? Border.all(color: color.withAlpha(80), width: 1.5)
                  : Border.all(color: Colors.transparent, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (opt != 'Todos') ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? color : color.withAlpha(140),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  opt,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? (opt == 'Todos' ? context.dc.bg : color)
                        : context.dc.ink2,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GeoPagination extends StatelessWidget {
  const _GeoPagination({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final start = page * pageSize + 1;
    final end = (start + pageSize - 1).clamp(1, totalCount);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
        const SizedBox(width: 12),
        Text(
          '$start–$end de $totalCount',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.dc.ink2,
          ),
        ),
        const SizedBox(width: 12),
        _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? context.dc.elevated
              : context.dc.elevated.withAlpha(80),
          borderRadius: BorderRadius.circular(8),
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

class FlagWidget extends StatelessWidget {
  const FlagWidget({super.key, required this.isoCode, required this.size});

  final String isoCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isoCode.isEmpty) {
      return SizedBox(
        width: size,
        height: size * 0.75,
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
        height: size * 0.75,
        shape: const RoundedRectangle(4),
      ),
    );
  }
}
