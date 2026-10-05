import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/duration_format.dart';
import '../../../core/theme/app_theme.dart';

Future<void> showGoalSheet(BuildContext context, {Duration? current}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _GoalSheet(current: current),
  );
}

class _GoalSheet extends ConsumerWidget {
  const _GoalSheet({this.current});

  final Duration? current;

  static const _presets = [1, 2, 3, 4, 6];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Future<void> choose(Duration? goal) async {
      await ref.read(dailyGoalProvider.notifier).save(goal);
      if (context.mounted) Navigator.pop(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Daily goal', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A gentle target for your total screen time. Missing it is fine; it is only a guide.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final h in _presets)
                ChoiceChip(
                  label: Text(formatDuration(Duration(hours: h))),
                  selected: current == Duration(hours: h),
                  onSelected: (_) => choose(Duration(hours: h)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (current != null)
            TextButton(onPressed: () => choose(null), child: const Text('Remove goal')),
        ],
      ),
    );
  }
}
