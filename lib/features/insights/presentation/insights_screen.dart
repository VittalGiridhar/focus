import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../core/format/duration_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../platform/usage_tracking_service.dart';
import '../../permissions/presentation/usage_access_card.dart';
import '../domain/usage_aggregator.dart';
import 'goal_sheet.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(usageAccessProvider);
    if (access.isLoading && !access.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    if (access.valueOrNull != PermissionState.granted) {
      return const UsageAccessCard();
    }

    final weekly = ref.watch(weeklyUsageProvider);
    final goal = ref.watch(dailyGoalProvider).valueOrNull;
    return weekly.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => EmptyState(
        icon: Icons.error_outline,
        title: 'Couldn\'t read your usage',
        message: 'Check that usage access is still turned on, then try again.',
        action: OutlinedButton(
          onPressed: () => ref.invalidate(weeklyUsageProvider),
          child: const Text('Try again'),
        ),
      ),
      data: (usage) {
        if (usage == null) return const UsageAccessCard();
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(weeklyUsageProvider);
            await ref.read(weeklyUsageProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
            children: [
              const HudLabel('Your week'),
              const SizedBox(height: AppSpacing.xs),
              Text('Insights', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.lg),
              _SummaryCard(usage: usage, goal: goal),
              const SizedBox(height: AppSpacing.md),
              _ChartCard(usage: usage, goal: goal),
              const SizedBox(height: AppSpacing.sm),
              _GoalTile(goal: goal),
              if (usage.topApps.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _TopApps(apps: usage.topApps),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                'Based on the apps you can launch. Phone calls and system screens are not counted. '
                'Android keeps about a week of history, so older days may be empty.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.usage, required this.goal});

  final WeeklyUsage usage;
  final Duration? goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _Stat(label: 'Today', value: formatDuration(usage.today.total))),
                Expanded(
                  child: _Stat(label: 'Daily average', value: formatDuration(usage.averagePerDay)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(gentleMessage(usage, goal), style: theme.textTheme.bodyMedium),
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.usage, required this.goal});

  final WeeklyUsage usage;
  final Duration? goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekday = DateFormat.E();
    double hours(Duration d) => d.inSeconds / 3600;
    final maxHours = usage.days.map((d) => hours(d.total)).fold<double>(0, math.max);
    final goalHours = goal == null ? 0.0 : hours(goal!);
    final maxY = math.max(1.0, math.max(maxHours, goalHours)) * 1.2;
    final summary = 'Screen time per day: ${[
      for (final d in usage.days) '${weekday.format(d.day)} ${formatDuration(d.total)}',
    ].join(', ')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HudLabel('Last 7 days'),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: summary,
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      minY: 0,
                      barTouchData: BarTouchData(enabled: false),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= usage.days.length) return const SizedBox.shrink();
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  weekday.format(usage.days[i].day).substring(0, 1),
                                  style: theme.textTheme.labelSmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          if (goal != null)
                            HorizontalLine(
                              y: goalHours,
                              color: theme.colorScheme.tertiary,
                              strokeWidth: 1.5,
                              dashArray: [6, 4],
                            ),
                        ],
                      ),
                      barGroups: [
                        for (var i = 0; i < usage.days.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: hours(usage.days[i].total),
                                width: 14,
                                borderRadius: BorderRadius.circular(7),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: i == usage.days.length - 1
                                      ? [AppColors.accentDim, AppColors.accent]
                                      : [
                                          AppColors.surfaceHighest,
                                          AppColors.accent.withValues(alpha: 0.35),
                                        ],
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxY,
                                  color: AppColors.surfaceRaised,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (goal != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Dashed line: your goal of ${formatDuration(goal!)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.goal});

  final Duration? goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: const Icon(Icons.flag_outlined),
        title: const Text('Daily goal'),
        subtitle: Text(goal == null ? 'Not set. Totally optional.' : formatDuration(goal!)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showGoalSheet(context, current: goal),
      ),
    );
  }
}

class _TopApps extends StatelessWidget {
  const _TopApps({required this.apps});

  final List<AppTotal> apps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: HudLabel('Most used this week'),
            ),
            for (final a in apps)
              ListTile(
                leading: AppIcon(packageName: a.appId),
                title: Text(a.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(formatDuration(a.total)),
              ),
          ],
        ),
      ),
    );
  }
}
