import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppListItem extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const AppListItem({
    super.key,
    this.icon,
    this.iconColor,
    this.leading,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = destructive ? colorScheme.error : iconColor;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          leading ??
              (icon == null
                  ? const SizedBox.shrink()
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (accent ?? colorScheme.primary).withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Icon(
                        icon,
                        color: accent ?? colorScheme.primary,
                        size: 20,
                      ),
                    )),
          if (leading != null || icon != null)
            const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      titleStyle ??
                      Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: destructive ? colorScheme.error : null,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(onTap: onTap, child: content);
  }
}
