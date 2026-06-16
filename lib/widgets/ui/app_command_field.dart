import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppCommandField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onActionPressed;
  final IconData leadingIcon;
  final IconData actionIcon;
  final String actionTooltip;
  final bool actionEnabled;

  const AppCommandField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onActionPressed,
    this.leadingIcon = Icons.auto_awesome,
    this.actionIcon = Icons.auto_awesome,
    this.actionTooltip = '智能创建任务',
    this.actionEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Icon(leadingIcon, color: colorScheme.primary, size: 22),
          ),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty || onClear == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: '清空',
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton.filledTonal(
              tooltip: actionTooltip,
              icon: Icon(actionIcon, size: 20),
              onPressed: actionEnabled ? onActionPressed : null,
            ),
          ),
        ],
      ),
    );
  }
}
