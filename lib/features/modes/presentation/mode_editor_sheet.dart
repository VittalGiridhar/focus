import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/duration_picker.dart';
import '../../../platform/usage_tracking_service.dart';
import '../data/modes_repository.dart';
import '../domain/mode.dart';
import 'app_multi_picker_screen.dart';

Future<void> showModeEditor(BuildContext context, {FocusMode? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ModeEditorSheet(existing: existing),
  );
}

class ModeEditorSheet extends ConsumerStatefulWidget {
  const ModeEditorSheet({super.key, this.existing});

  final FocusMode? existing;

  @override
  ConsumerState<ModeEditorSheet> createState() => _ModeEditorSheetState();
}

class _ModeEditorSheetState extends ConsumerState<ModeEditorSheet> {
  static const _presets = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 8),
    Duration(hours: 12),
    Duration(hours: 24),
  ];

  late final TextEditingController _name;
  late Duration _duration;
  late List<ModeApp> _apps;
  String? _error;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = TextEditingController(text: m?.name ?? '');
    _duration = m?.duration ?? const Duration(hours: 1);
    _apps = [...?m?.apps];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || name.length > ModesRepository.maxNameLength) {
      setState(() => _error = 'Enter a name up to ${ModesRepository.maxNameLength} characters.');
      return;
    }
    if (_apps.isEmpty) {
      setState(() => _error = 'Choose at least one app to pause during this mode.');
      return;
    }
    final repo = ref.read(modesRepositoryProvider);
    final existing = widget.existing;
    if (existing == null) {
      await repo.create(name: name, duration: _duration, apps: _apps);
    } else {
      await repo.update(existing.copyWith(name: name, duration: _duration, apps: _apps));
    }
    if (mounted) Navigator.pop(context);
  }

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
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existing == null ? 'New mode' : 'Edit mode',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _name,
              maxLength: ModesRepository.maxNameLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Deep Work',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('How long', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            DurationPicker(
              value: _duration,
              max: ModesRepository.maxDuration,
              presets: _presets,
              onChanged: (d) => _duration = d,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Apps to pause', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            if (_apps.isNotEmpty)
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
            OutlinedButton.icon(
              onPressed: _chooseApps,
              icon: const Icon(Icons.apps),
              label: Text(_apps.isEmpty ? 'Choose apps' : 'Change apps'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
