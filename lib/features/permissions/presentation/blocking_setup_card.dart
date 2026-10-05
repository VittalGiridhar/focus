import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../platform/usage_tracking_service.dart';

/// Shown while limits exist but the Accessibility service that enforces them is off.
class BlockingSetupCard extends ConsumerWidget {
  const BlockingSetupCard({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
  });

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accessibilityProvider).valueOrNull;
    if (state == null || state == PermissionState.granted || state == PermissionState.unsupported) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Blocking is off', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your limits are tracked, but apps won\'t be covered when you reach them.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => showAccessibilityDisclosure(context, ref),
                child: const Text('Turn on blocking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prominent disclosure shown before sending the user to Accessibility settings.
Future<void> showAccessibilityDisclosure(BuildContext context, WidgetRef ref) async {
  final proceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Allow Focus to see which app is open'),
      content: const SingleChildScrollView(
        child: Text(
          'To cover an app when you reach its limit, Focus uses Android\'s '
          'Accessibility service to detect which app is currently open.\n\n'
          '• It only sees the name of the app that is open.\n'
          '• It does not read your screen, messages, passwords or anything you type.\n'
          '• Nothing is sent off your device.\n\n'
          'On the next screen, choose "Focus app limits" and turn it on. You can '
          'turn it off at any time.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Agree and continue'),
        ),
      ],
    ),
  );
  if (proceed == true) {
    await ref
        .read(usageServiceProvider)
        .openPermissionSettings(EnforcementPermission.accessibility);
  }
}
