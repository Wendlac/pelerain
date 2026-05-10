import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum SkeuButtonVariant { primary, secondary, ghost, danger }

class SkeuButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final SkeuButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final double? width;

  const SkeuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SkeuButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.width,
  });

  @override
  State<SkeuButton> createState() => _SkeuButtonState();
}

class _SkeuButtonState extends State<SkeuButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _ctrl.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(_) {
    _ctrl.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;

    return GestureDetector(
      onTapDown: disabled ? null : _onTapDown,
      onTapUp: disabled ? null : _onTapUp,
      onTapCancel: disabled ? null : _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: _buildContent(disabled),
      ),
    );
  }

  Widget _buildContent(bool disabled) {
    switch (widget.variant) {
      case SkeuButtonVariant.primary:
        return _PrimaryButton(widget: widget, disabled: disabled);
      case SkeuButtonVariant.secondary:
        return _SecondaryButton(widget: widget, disabled: disabled);
      case SkeuButtonVariant.ghost:
        return _GhostButton(widget: widget, disabled: disabled);
      case SkeuButtonVariant.danger:
        return _DangerButton(widget: widget, disabled: disabled);
    }
  }
}

class _PrimaryButton extends StatelessWidget {
  final SkeuButton widget;
  final bool disabled;
  const _PrimaryButton({required this.widget, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: disabled
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B3FEF), Color(0xFF5A0FA8)],
              ),
        color: disabled ? AppColors.contentDisabled : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                  spreadRadius: -2,
                ),
              ],
      ),
      child: _ButtonContent(widget: widget, color: Colors.white),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final SkeuButton widget;
  final bool disabled;
  const _SecondaryButton({required this.widget, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _ButtonContent(widget: widget, color: AppColors.primary),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final SkeuButton widget;
  final bool disabled;
  const _GhostButton({required this.widget, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: 56,
      child: _ButtonContent(widget: widget, color: AppColors.primary),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final SkeuButton widget;
  final bool disabled;
  const _DangerButton({required this.widget, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: _ButtonContent(widget: widget, color: AppColors.error),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final SkeuButton widget;
  final Color color;
  const _ButtonContent({required this.widget, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: widget.loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: color, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
    );
  }
}
