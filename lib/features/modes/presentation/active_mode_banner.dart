import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/format/duration_format.dart';
import '../../../core/format/time_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../partner/presentation/unlock_screen.dart';
import '../domain/mode.dart';

/// One card per running block (and per partner-approved break), each with a live countdown.
class ActiveModeBanner extends ConsumerWidget {
  const ActiveModeBanner({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = ref.watch(activeModesProvider).valueOrNull ?? const [];
    final grants = ref.watch(activeGrantsProvider).valueOrNull ?? const [];
    if (blocks.isEmpty && grants.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: margin,
      child: Column(
        children: [
          for (final grant in grants) _CountdownCard(key: ValueKey(grant.id), entry: grant, isGrant: true),
          for (final block in blocks) _CountdownCard(key: ValueKey(block.id), entry: block, isGrant: false),
        ],
      ),
    );
  }
}

class _CountdownCard extends ConsumerStatefulWidget {
  const _CountdownCard({super.key, required this.entry, required this.isGrant});

  final ActiveMode entry;
  final bool isGrant;

  @override
  ConsumerState<_CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends ConsumerState<_CountdownCard> {
  // Ask the native layer to re-check once per end time, not once per frame, so a
  // mismatch between clocks can never cause a refresh loop.
  DateTime? _refreshedFor;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final now = ref.watch(clockTickProvider).valueOrNull ?? ref.read(clockProvider).now();
    final remaining = entry.remaining(now);
    if (remaining == Duration.zero && _refreshedFor != entry.endsAt) {
      _refreshedFor = entry.endsAt;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.invalidate(widget.isGrant ? activeGrantsProvider : activeModesProvider);
      });
    }

    final theme = Theme.of(context);
    final color = widget.isGrant ? AppColors.violet : AppColors.accent;
    final hasPartner = ref.watch(partnerProvider).valueOrNull != null;
    final title = widget.isGrant ? '${entry.name} unlocked' : entry.name;
    final status = widget.isGrant
        ? 'Break · locks again ${endTimeLabel(context, now, entry.endsAt)}'
        : 'Locked · until ${endTimeLabel(context, now, entry.endsAt)}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 24)],
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: '$title, ${formatDuration(remaining)} remaining',
            excludeSemantics: true,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HudLabel(status, color: color),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        formatCountdown(remaining),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: color,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          shadows: AppText.glow(color),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(widget.isGrant ? Icons.lock_open_outlined : Icons.lock_outline, color: color),
                ),
              ],
            ),
          ),
          if (!widget.isGrant && hasPartner)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/unlock', extra: UnlockArgs(entry.packageNames)),
                icon: const Icon(Icons.key_outlined, size: 18),
                label: const Text('Ask partner'),
              ),
            )
          else
            const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
