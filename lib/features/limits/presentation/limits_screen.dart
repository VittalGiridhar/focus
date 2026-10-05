import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/format/duration_format.dart';
import '../../../core/format/time_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../platform/usage_tracking_service.dart';
import '../../partner/presentation/unlock_screen.dart';
import '../../permissions/presentation/blocking_setup_card.dart';
import '../../permissions/presentation/usage_access_card.dart';
import '../domain/usage_models.dart';
import 'app_picker_screen.dart';
import 'limit_editor_sheet.dart';

class LimitsScreen extends ConsumerWidget {
  const LimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(usageAccessProvider);
    if (access.isLoading && !access.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (access.valueOrNull != PermissionState.granted) {
      return const UsageAccessCard();
    }

    final limits = ref.watch(limitsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addLimit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add limit'),
      ),
      body: Column(
        children: [
          const BlockingSetupCard(),
          Expanded(
            child: limits.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const EmptyState(
                icon: Icons.error_outline,
                title: 'Couldn\'t load your limits',
                message: 'Please close and reopen the app. Your data is safe on this device.',
              ),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      icon: Icons.timer_outlined,
                      title: 'No limits yet',
                      message:
                          'Pick an app and choose how much time you want to spend in it each day.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => _LimitTile(rule: items[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addLimit(BuildContext context, WidgetRef ref) async {
    final existing = ref.read(limitsProvider).valueOrNull ?? const [];
    final app = await Navigator.push<InstalledApp>(
      context,
      MaterialPageRoute(
        builder: (_) => AppPickerScreen(excluded: {for (final r in existing) r.appId}),
      ),
    );
    if (app == null || !context.mounted) return;
    await showLimitEditor(context, appId: app.packageName, label: app.label);
  }
}

enum _Action { edit, delete }

class _LimitTile extends ConsumerWidget {
  const _LimitTile({required this.rule});

  final LimitRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A limit that is currently holding an app closed cannot be loosened or removed,
    // otherwise deleting it would be an instant way around the block.
    final until = ref.watch(lockStateProvider).appLockedUntil(rule.appId);
    if (until != null) {
      final label = 'Locked until ${endTimeLabel(context, ref.read(clockProvider).now(), until)}';
      return Card(
        child: ListTile(
          minVerticalPadding: AppSpacing.md,
          leading: AppIcon(packageName: rule.appId),
          title: Text(rule.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${formatDuration(rule.dailyLimit)} per day · $label'),
          trailing: const Icon(Icons.lock_outline, semanticLabel: 'Locked'),
          onTap: () {
            if (ref.read(partnerProvider).valueOrNull != null) {
              context.push(
                '/unlock',
                extra: UnlockArgs([rule.appId], labels: {rule.appId: rule.label}),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label. This limit can\'t be changed or removed until then.')),
            );
          },
        ),
      );
    }
    return Card(
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: AppIcon(packageName: rule.appId),
        title: Text(rule.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${formatDuration(rule.dailyLimit)} per day'),
        trailing: PopupMenuButton<_Action>(
          tooltip: 'Limit options',
          onSelected: (a) => _onAction(context, ref, a),
          itemBuilder: (_) => const [
            PopupMenuItem(value: _Action.edit, child: Text('Change limit')),
            PopupMenuItem(value: _Action.delete, child: Text('Remove')),
          ],
        ),
        onTap: () => _edit(context),
      ),
    );
  }

  Future<void> _edit(BuildContext context) => showLimitEditor(
        context,
        appId: rule.appId,
        label: rule.label,
        current: rule.dailyLimit,
      );

  Future<void> _onAction(BuildContext context, WidgetRef ref, _Action action) async {
    switch (action) {
      case _Action.edit:
        await _edit(context);
      case _Action.delete:
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Remove limit for ${rule.label}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await ref.read(limitsRepositoryProvider).delete(rule.appId);
          ref.invalidate(todayUsageProvider);
        }
    }
  }
}
