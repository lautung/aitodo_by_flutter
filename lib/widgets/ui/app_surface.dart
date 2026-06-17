import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  const AppSurface({
    super.key,
    required this.child,
    this.padding = AppInsets.surface,
    this.margin,
    this.color,
    this.borderColor,
    this.radius = AppRadii.sm,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.surfaceContainerLowest;
    final effectiveBorderColor =
        borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.7);

    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: effectiveBorderColor),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
