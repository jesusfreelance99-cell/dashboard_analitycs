import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

enum ButtonType { primary, secondary, outline, ghost }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;

  const AppButton({
    required this.label,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48,
    super.key,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  void _onTapDown(_) {
    if (!_disabled) _ctrl.forward();
  }

  void _onTapUp(_) {
    if (!_disabled) _ctrl.reverse();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _disabled ? null : widget.onPressed,
        child: AnimatedOpacity(
          opacity: _disabled && !widget.isLoading ? 0.45 : 1.0,
          duration: AppConstants.animationFast,
          child: _buildSurface(context),
        ),
      ),
    );
  }

  Widget _buildSurface(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: _decoration(),
      child: Center(child: _buildContent(context)),
    );
  }

  BoxDecoration _decoration() {
    switch (widget.type) {
      case ButtonType.primary:
        return BoxDecoration(
          color: AppColors.pink,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        );
      case ButtonType.secondary:
        return BoxDecoration(
          color: AppColors.pinkLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        );
      case ButtonType.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: AppColors.pink, width: 1.5),
        );
      case ButtonType.ghost:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        );
    }
  }

  Widget _buildContent(BuildContext context) {
    if (widget.isLoading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_labelColor()),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [widget.icon!, const SizedBox(width: 8), _labelText(context)],
      );
    }

    return _labelText(context);
  }

  Widget _labelText(BuildContext context) {
    return Text(
      widget.label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _labelColor(),
        letterSpacing: 0.1,
      ),
    );
  }

  Color _labelColor() {
    switch (widget.type) {
      case ButtonType.primary:
        return AppColors.white;
      case ButtonType.secondary:
        return AppColors.pink;
      case ButtonType.outline:
        return AppColors.pink;
      case ButtonType.ghost:
        return AppColors.ink2;
    }
  }
}
