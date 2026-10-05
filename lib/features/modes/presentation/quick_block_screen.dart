import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/format/time_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/duration_picker.dart';
import '../../../platform/usage_tracking_service.dart';
import '../domain/mode.dart';
import 'app_multi_picker_screen.dart';
import 'mode_actions.dart';

/// Pick apps and a time, confirm once, and those apps stay closed until it runs out.
class QuickBlockScreen extends ConsumerStatefulWidget {
  const QuickBlockScreen({super.key});

  @override
  ConsumerState<QuickBlockScreen> createState() => _QuickBlockScreenState();
}

class _QuickBlockScreenState extends ConsumerState<QuickBlockScreen> {
  static const _presets = [
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 8),
    Duration(hours: 12),
  ];

  List<ModeApp> _apps = [];
  Duration _duration = const Duration(minutes: 5);
  bool _starting = false;

  Future<void> _chooseApps() async {
    final picked = await Navigator.push<List<InstalledApp>>(
      context,
      MaterialPageRoute(
        builder: (_) => AppMultiPickerScreen(selected: {for (final a in _apps) a.packageName}),
      ),
    );
    if (picked == null) return;
    setState(() {
      _apps = [for (final a in picked) ModeApp(packageName: a.packageName, label: a.label)];
    });
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    final now = ref.read(clockProvider).now();
    final started = await startBlockFlow(
      context,
      ref,
      id: '${ActiveMode.quickPrefix}${now.microsecondsSinceEpoch}',
      name: _apps.length == 1 ? _apps.first.label : 'Quick block',
      apps: _apps,
      duration: _duration,
    );
    if (!mounted) return;
    setState(() => _starting = false);
    if (started) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = ref.read(clockProvider).now();
    final until = endTimeLabel(context, now, now.add(_duration));
    return Scaffold(
      appBar: AppBar(title: const Text('Block now')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Which apps?', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (_apps.isNotEmpty) ...[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final a in _apps)
                    Chip(
                      avatar: AppIcon(packageName: a.packageName, size: 20),
                      label: Text(a.label),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            OutlinedButton.icon(
              onPressed: _chooseApps,
              icon: const Icon(Icons.apps),
              label: Text(_apps.isEmpty ? 'Choose apps' : 'Change apps'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('For how long?', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            DurationPicker(
              value: _duration,
              max: const Duration(hours: 12),
              presets: _presets,
              onChanged: (d) => setState(() => _duration = d),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Once you confirm, the chosen apps can\'t be opened until $until, and this can\'t be undone.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _apps.isEmpty || _starting ? null : _start,
                icon: const Icon(Icons.lock_outline),
                label: Text('Block until $until'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
