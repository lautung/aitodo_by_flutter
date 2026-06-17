import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final List<Widget> actions;
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const AppPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.actions = const [],
    required this.child,
    this.scrollable = true,
    this.padding = AppInsets.screen,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                title: title,
                subtitle: subtitle,
                leadingIcon: leadingIcon,
                actions: actions,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(child: content),
    );
  }
}

class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final List<Widget> actions;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (canPop) ...[
          IconButton.filledTonal(
            tooltip: '返回',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (leadingIcon != null) ...[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(leadingIcon, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.md),
          Wrap(spacing: AppSpacing.xs, children: actions),
        ],
      ],
    );
  }
}
