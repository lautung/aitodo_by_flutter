import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final IconData? icon;
  final Color? color;
  final String? tooltip;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.icon,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = color ?? colorScheme.primary;
    final foreground = selected ? accent : colorScheme.onSurfaceVariant;
    final background = selected
        ? accent.withValues(alpha: 0.12)
        : colorScheme.surfaceContainerLowest;
    final border = selected
        ? accent
        : colorScheme.outlineVariant.withValues(alpha: 0.8);

    final chip = InkWell(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _ChipCount(count: count!, color: accent, selected: selected),
            ],
          ],
        ),
      ),
    );

    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

class AppInfoPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool emphasized;

  const AppInfoPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: emphasized ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipCount extends StatelessWidget {
  final int count;
  final Color color;
  final bool selected;

  const _ChipCount({
    required this.count,
    required this.color,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: 0.18)
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        count.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: selected ? color : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
