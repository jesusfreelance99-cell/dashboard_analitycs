import 'dart:math' as math;

import 'package:dashboard_analitycs/core/constants/app_colors.dart';
import 'package:dashboard_analitycs/core/constants/app_constants.dart';
import 'package:dashboard_analitycs/core/constants/dash_colors.dart';

import 'package:dashboard_analitycs/features/screens/dashboard/dashboard_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'models.dart';

class SidebarItem extends StatefulWidget {
  const SidebarItem({
    super.key,
    required this.meta,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final PageMeta meta;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _iconScale = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    if (widget.selected) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(SidebarItem old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _ctrl.forward(from: 0.0);
    } else if (!widget.selected && old.selected) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 14 : 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0x0F140C10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              ScaleTransition(
                scale: _iconScale,
                child: Icon(
                  widget.selected ? widget.meta.iconSelected : widget.meta.icon,
                  size: 30,
                  color: widget.selected ? AppColors.pink : AppColors.ink3,
                ),
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: widget.selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: AppColors.ink2,
                    ),
                    child: Text(widget.meta.navLabel),
                  ),
                ),
                if (widget.selected)
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.pink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class UtilityItem extends StatelessWidget {
  const UtilityItem({
    super.key,
    required this.icon,
    required this.label,
    required this.collapsed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: collapsed ? 8 : 14,
          vertical: 12,
        ),
        child: Row(
          mainAxisAlignment: collapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: AppColors.ink3),
            if (!collapsed) ...[
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(fontSize: 18, color: AppColors.ink2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RangeSegmentedControl extends StatelessWidget {
  const RangeSegmentedControl({
    super.key,
    required this.range,
    required this.onChanged,
  });

  final DateRange range;
  final ValueChanged<DateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (DateRange.d7, '7d'),
      (DateRange.d30, '30d'),
      (DateRange.d90, '90d'),
      (DateRange.all, 'Todo'),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.dc.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items) ...[
            SegmentButton(
              label: item.$2,
              selected: range == item.$1,
              onTap: () => onChanged(item.$1),
            ),
            if (item != items.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class SegmentButton extends StatelessWidget {
  const SegmentButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? context.dc.chipSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.dc.ink.withValues(alpha: selected ? 1 : 0.68),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label, required this.source});

  final String label;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            color: AppColors.ink3,
          ),
        ),
        if (source.isNotEmpty) ...[
          const Spacer(),
          Text(
            source,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.ink3,
            ),
          ),
        ],
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.badgeText,
    this.badgeType = BadgeType.neutral,
    this.helperText,
    this.accent = false,
    this.valueSuffix,
  });

  final String label;
  final String value;
  final String? badgeText;
  final BadgeType badgeType;
  final String? helperText;
  final bool accent;
  final Widget? valueSuffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFFBEEF2) : context.dc.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: context.dc.ink2)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      height: 0.95,
                      letterSpacing: -2.2,
                      color: context.dc.ink,
                    ),
                  ),
                ),
              ),
              if (valueSuffix != null) ...[
                const SizedBox(width: 10),
                valueSuffix!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (badgeText != null)
                DashBadge(text: badgeText!, type: badgeType),
              if (helperText != null)
                Text(
                  helperText!,
                  style: TextStyle(fontSize: 16, color: context.dc.ink3),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashBadge extends StatelessWidget {
  const DashBadge({super.key, required this.text, required this.type});

  final String text;
  final BadgeType type;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    switch (type) {
      case BadgeType.positive:
        background = const Color(0xFFE7F6ED);
        foreground = const Color(0xFF1B9C5B);
        break;
      case BadgeType.negative:
        background = const Color(0xFFFCE7E4);
        foreground = const Color(0xFFD4584F);
        break;
      case BadgeType.neutral:
        background = const Color(0xFFF1F1EF);
        foreground = AppColors.ink2;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.minTileWidth,
    required this.children,
  });

  final double minTileWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = math.max(
          1,
          (constraints.maxWidth / minTileWidth).floor(),
        );
        const gap = 18.0;
        final tileWidth = (constraints.maxWidth - gap * (count - 1)) / count;

        final rows = <List<Widget>>[];
        for (int i = 0; i < children.length; i += count) {
          rows.add(children.sublist(i, math.min(i + count, children.length)));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int c = 0; c < rows[r].length; c++) ...[
                      if (c > 0) const SizedBox(width: gap),
                      SizedBox(width: tileWidth, child: rows[r][c]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class ResponsiveSplit extends StatelessWidget {
  const ResponsiveSplit({super.key, required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1180;
        return Flex(
          direction: stacked ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: stacked ? 0 : 7, child: left),
            SizedBox(width: stacked ? 0 : 18, height: stacked ? 18 : 0),
            Expanded(flex: stacked ? 0 : 5, child: right),
          ],
        );
      },
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.dc.surface,
        borderRadius: BorderRadius.circular(32),
      ),
      child: child,
    );
  }
}

class PanelHeader extends StatelessWidget {
  const PanelHeader({super.key, required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.dc.ink,
          ),
        ),
        const Spacer(),
        Text(trailing, style: TextStyle(fontSize: 16, color: context.dc.ink3)),
      ],
    );
  }
}

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(painter: DotGridPainter()),
            ),
          ),
          Positioned(
            left: 26,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LegendLine(flag: '🇨🇴', label: 'Colombia · ', value: '37'),
                  SizedBox(height: 8),
                  LegendLine(flag: '🇲🇽', label: 'México · ', value: '1'),
                  SizedBox(height: 8),
                  LegendLine(flag: '🇺🇸', label: 'EE.UU. · ', value: '1'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LegendLine extends StatelessWidget {
  const LegendLine({
    super.key,
    required this.flag,
    required this.label,
    required this.value,
  });

  final String flag;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: flag, style: const TextStyle(fontSize: 24)),
          TextSpan(
            text: ' $label',
            style: const TextStyle(fontSize: 20, color: AppColors.ink),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class CountryRow extends StatelessWidget {
  const CountryRow({super.key, required this.data});

  final CountryData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(data.flag, style: const TextStyle(fontSize: 30)),
        ),
        Expanded(
          child: Text(
            data.name,
            style: const TextStyle(
              fontSize: 22,
              height: 1.15,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: data.progress,
              minHeight: 14,
              backgroundColor: AppColors.progressBg,
              valueColor: const AlwaysStoppedAnimation(AppColors.progressFill),
            ),
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 42,
          child: Text(
            '${data.value}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 66,
          child: Text(
            data.percent,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 18, color: AppColors.ink3),
          ),
        ),
      ],
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: context.dc.input,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Icon(FluentIcons.search_20_regular, size: 34, color: context.dc.hint),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Buscar por nombre o correo...',
                hintStyle: TextStyle(fontSize: 20, color: context.dc.hint),
              ),
              style: TextStyle(fontSize: 20, color: context.dc.ink),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }
}

class FilterSegment extends StatelessWidget {
  const FilterSegment({
    super.key,
    required this.items,
    required this.selectedIndex,
  });

  final List<String> items;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: index == selectedIndex
                      ? const Color(0xFFF1F1EF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  items[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink.withValues(
                      alpha: index == selectedIndex ? 1 : 0.72,
                    ),
                  ),
                ),
              ),
            ),
            if (index != items.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class UsersTablePlaceholder extends StatelessWidget {
  const UsersTablePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }
}

class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFCEBF2) : const Color(0xFFF1F1EF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? AppColors.pink : AppColors.ink3,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.pinkDark : AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DisabledSearchTile extends StatelessWidget {
  const DisabledSearchTile({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            FluentIcons.search_20_regular,
            size: 30,
            color: AppColors.ink3,
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class RecipientCount extends StatelessWidget {
  const RecipientCount({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: const [
          Icon(FluentIcons.send_20_regular, size: 28, color: AppColors.pink),
          SizedBox(width: 16),
          Text(
            'Se enviará a ',
            style: TextStyle(fontSize: 18, color: AppColors.ink2),
          ),
          Text(
            '40',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'usuarios',
            style: TextStyle(fontSize: 18, color: AppColors.ink2),
          ),
        ],
      ),
    );
  }
}

class FormLabel extends StatelessWidget {
  const FormLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class TextInput extends StatelessWidget {
  const TextInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.maxLengthLabel,
  });

  final TextEditingController controller;
  final String hintText;
  final String maxLengthLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 18, color: AppColors.ink3),
            fillColor: const Color(0xFFF1F1EF),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 18, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          maxLengthLabel,
          style: const TextStyle(fontSize: 14, color: AppColors.ink3),
        ),
      ],
    );
  }
}

class TextAreaInput extends StatelessWidget {
  const TextAreaInput({
    super.key,
    required this.controller,
    required this.hintText,
    required this.maxLengthLabel,
    this.maxLines = 4,
  });

  final TextEditingController controller;
  final String hintText;
  final String maxLengthLabel;
  final int maxLines;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 18, color: AppColors.ink3),
            fillColor: const Color(0xFFF1F1EF),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 18, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          maxLengthLabel,
          style: const TextStyle(fontSize: 14, color: AppColors.ink3),
        ),
      ],
    );
  }
}

class SendModeControl extends StatelessWidget {
  const SendModeControl({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final PreviewSendMode mode;
  final ValueChanged<PreviewSendMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: MiniSegment(
              label: 'Enviar ahora',
              selected: mode == PreviewSendMode.now,
              onTap: () => onChanged(PreviewSendMode.now),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MiniSegment(
              label: 'Programar',
              selected: mode == PreviewSendMode.scheduled,
              onTap: () => onChanged(PreviewSendMode.scheduled),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniSegment extends StatelessWidget {
  const MiniSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.ink : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}

class PhonePreview extends StatelessWidget {
  const PhonePreview({
    required this.title,
    required this.message,
    required this.sendMode,
  });

  final String title;
  final String message;
  final PreviewSendMode sendMode;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 510),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(72),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF22868), Color(0xFF9A1C43), Color(0xFF25070F)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 154,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(34, 86, 34, 34),
                child: Column(
                  children: [
                    const Text(
                      '9:41',
                      style: TextStyle(
                        fontSize: 84,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -3,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'jueves, 5 de junio',
                      style: TextStyle(fontSize: 24, color: AppColors.white),
                    ),
                    const SizedBox(height: 52),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8DEE7).withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const TrevoMark(size: 30),
                              const SizedBox(width: 12),
                              const Text(
                                'TREVO',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppColors.ink,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                sendMode == PreviewSendMode.now
                                    ? 'ahora'
                                    : 'mañana',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.ink2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.3,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrevoMark extends StatelessWidget {
  const TrevoMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset('assets/img/app_icon.png', width: size, height: size),
    );
  }
}

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFD7D7D2);
    const spacing = 32.0;
    const dotSize = 2.4;

    for (double y = 14; y < size.height; y += spacing) {
      for (double x = 14; x < size.width; x += spacing) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: dotSize,
            height: dotSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
