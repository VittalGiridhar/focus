import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/format/duration_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../platform/usage_tracking_service.dart';
import '../../modes/presentation/active_mode_banner.dart';
import '../../permissions/presentation/blocking_setup_card.dart';
import '../../permissions/presentation/usage_access_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(usageAccessProvider);
        ref.invalidate(activeModesProvider);
        ref.invalidate(todayUsageProvider);
        await ref.read(todayUsageProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Running blocks and the quick-block shortcut need neither usage access
          // nor limits, so they are always shown.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                HudLabel(DateFormat('EEE · d MMM').format(ref.read(clockProvider).now())),
                const SizedBox(height: AppSpacing.xs),
                Text('Today', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.lg),
                const ActiveModeBanner(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/quick-block'),
                    icon: const Icon(Icons.bolt_outlined),
                    label: const Text('Block an app now'),
                  ),
                ),
              ]),
            ),
          ),
          ..._content(context, ref),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, WidgetRef ref) {
    Widget fill(Widget child) => SliverFillRemaining(hasScrollBody: false, child: child);

    final access = ref.watch(usageAccessProvider);
    if (access.isLoading && !access.hasValue) {
      return [fill(const Center(child: CircularProgressIndicator()))];
    }
    if (access.valueOrNull != PermissionState.granted) {
      return [fill(const UsageAccessCard())];
    }

    final usage = ref.watch(todayUsageProvider);
    return usage.when(
      loading: () => [fill(const Center(child: CircularProgressIndicator()))],
      error: (_, __) => [
        fill(EmptyState(
          icon: Icons.error_outline,
          title: 'Couldn\'t read today\'s usage',
          message: 'Check that usage access is still turned on, then try again.',
          action: OutlinedButton(
            onPressed: () => ref.invalidate(todayUsageProvider),
            child: const Text('Try again'),
          ),
        )),
      ],
      data: (items) {
        if (items.isEmpty) {
          return [
            fill(EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'No usage to show yet',
              message:
                  'Once you set a limit for an app, today\'s usage and remaining time will appear here.',
              action: FilledButton(
                onPressed: () => context.go('/limits'),
                child: const Text('Set up a limit'),
              ),
            )),
          ];
        }
        final total = items.fold(Duration.zero, (sum, i) => sum + i.status.used);
        final reached = items.where((i) => i.status.isLimitReached).length;
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const BlockingSetupCard(margin: EdgeInsets.only(bottom: AppSpacing.md)),
                _Summary(total: total, reached: reached),
                const SizedBox(height: AppSpacing.md),
                for (final item in items) ...[
                  _UsageRow(item: item),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ]),
            ),
          ),
        ];
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.total, required this.reached});

  final Duration total;
  final int reached;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: _Stat(label: 'Time in limited apps', value: formatDuration(total)),
            ),
            Expanded(
              child: _Stat(label: 'Limits reached', value: '$reached'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudLabel(label),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: theme.textTheme.headlineMedium),
      ],
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.item});

  final AppUsage item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = item.status;
    final progress = status.limit.inSeconds == 0
        ? 0.0
        : (status.used.inSeconds / status.limit.inSeconds).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(packageName: item.rule.appId, size: 36),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(item.rule.label,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text(
                  '${formatDuration(status.used)} / ${formatDuration(status.limit)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                semanticsLabel: '${item.rule.label} usage',
                semanticsValue: '${(progress * 100).round()} percent of daily limit',
                color: status.isLimitReached ? theme.colorScheme.error : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              status.isLimitReached
                  ? 'Daily limit reached'
                  : '${formatDuration(status.remaining)} left today',
              style: theme.textTheme.bodySmall?.copyWith(
                color: status.isLimitReached
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
