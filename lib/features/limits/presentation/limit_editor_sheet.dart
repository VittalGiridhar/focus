import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/duration_picker.dart';
import '../domain/usage_models.dart';

Future<void> showLimitEditor(
  BuildContext context, {
  required String appId,
  required String label,
  Duration? current,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => LimitEditorSheet(appId: appId, label: label, current: current),
  );
}

class LimitEditorSheet extends ConsumerStatefulWidget {
  const LimitEditorSheet({
    super.key,
    required this.appId,
    required this.label,
    this.current,
  });

  final String appId;
  final String label;
  final Duration? current;

  @override
  ConsumerState<LimitEditorSheet> createState() => _LimitEditorSheetState();
}

class _LimitEditorSheetState extends ConsumerState<LimitEditorSheet> {
  static const _presets = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(hours: 1),
    Duration(hours: 1, minutes: 30),
    Duration(hours: 2),
    Duration(hours: 3),
    Duration(hours: 4),
    Duration(hours: 6),
    Duration(hours: 8),
    Duration(hours: 12),
  ];

  late Duration _duration = widget.current ?? const Duration(minutes: 30);

  Future<void> _save() async {
    await ref.read(limitsRepositoryProvider).upsert(
          LimitRule(appId: widget.appId, label: widget.label, dailyLimit: _duration),
        );
    ref.invalidate(todayUsageProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Daily limit for ${widget.label}', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          DurationPicker(
            value: _duration,
            max: kMaxDailyLimit,
            min: kMinDailyLimit,
            presets: _presets,
            onChanged: (d) => _duration = d,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _save, child: const Text('Save limit')),
          ),
        ],
      ),
    );
  }
}
