import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/format/duration_format.dart';
import '../../../core/format/time_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/modes_repository.dart';
import '../domain/mode.dart';
import 'active_mode_banner.dart';
import 'mode_actions.dart';
import 'mode_editor_sheet.dart';

class ModesScreen extends ConsumerWidget {
  const ModesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modes = ref.watch(modesProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModeEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('New mode'),
      ),
      body: modes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Couldn\'t load your modes',
          message: 'Please close and reopen the app. Your data is safe on this device.',
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
          children: [
            const ActiveModeBanner(margin: EdgeInsets.only(bottom: AppSpacing.xs)),
            Card(
              child: ListTile(
                minVerticalPadding: AppSpacing.md,
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Block now'),
                subtitle: const Text('Pick apps and a time. They stay closed until it ends.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/quick-block'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xl),
                child: EmptyState(
                  icon: Icons.spa_outlined,
                  title: 'Create your first mode',
                  message:
                      'Modes save a set of apps and a time, like "Deep Work" or "Sleep", so you can start them in one tap.',
                ),
              )
            else
              for (final mode in items) ...[
                _ModeTile(mode: mode),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

enum _Action { edit, duplicate, delete }

class _ModeTile extends ConsumerWidget {
  const _ModeTile({required this.mode});

  final FocusMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(modesRepositoryProvider);
    final theme = Theme.of(context);
    final running = ref.watch(lockStateProvider).isModeRunning(mode.id);
    final runningBlock = running
        ? (ref.watch(activeModesProvider).valueOrNull ?? const [])
            .where((b) => b.id == mode.id)
            .firstOrNull
        : null;
    final appCount = mode.apps.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(mode.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (running)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Icon(Icons.lock_outline, semanticLabel: 'Locked while running'),
                  )
                else
                  PopupMenuButton<_Action>(
                    tooltip: 'Mode options',
                    onSelected: (a) => _onAction(context, repo, a),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: _Action.edit, child: Text('Edit')),
                      PopupMenuItem(value: _Action.duplicate, child: Text('Duplicate')),
                      PopupMenuItem(value: _Action.delete, child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            Text(
              '${formatDuration(mode.duration)} · $appCount ${appCount == 1 ? 'app' : 'apps'}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (mode.apps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                mode.apps.map((a) => a.label).join(', '),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: running || mode.apps.isEmpty
                      ? null
                      : () => startModeFlow(context, ref, mode),
                  child: Text(running ? 'Running' : 'Start'),
                ),
              ),
            ),
            if (runningBlock != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs, right: AppSpacing.md),
                child: Text(
                  'Can\'t be changed or ended until '
                  '${endTimeLabel(context, ref.read(clockProvider).now(), runningBlock.endsAt)}.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(BuildContext context, ModesRepository repo, _Action action) async {
    switch (action) {
      case _Action.edit:
        await showModeEditor(context, existing: mode);
      case _Action.duplicate:
        await repo.duplicate(mode);
      case _Action.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete "${mode.name}"?'),
            content: const Text('This can\'t be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok == true) await repo.delete(mode.id);
    }
  }
}
