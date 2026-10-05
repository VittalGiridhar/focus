import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/time_format.dart';
import '../../../platform/usage_tracking_service.dart';
import '../../permissions/presentation/blocking_setup_card.dart';
import '../domain/mode.dart';

Future<bool> startModeFlow(BuildContext context, WidgetRef ref, FocusMode mode) =>
    startBlockFlow(
      context,
      ref,
      id: mode.id,
      name: mode.name,
      apps: mode.apps,
      duration: mode.duration,
    );

String _appsPhrase(List<ModeApp> apps) {
  if (apps.length == 1) return apps.first.label;
  if (apps.length <= 3) return apps.map((a) => a.label).join(', ');
  return '${apps.length} apps';
}

/// Starts a block that keeps [apps] closed for [duration]. Returns whether it started.
/// Once started it cannot be ended early; that is why the user must confirm first.
Future<bool> startBlockFlow(
  BuildContext context,
  WidgetRef ref, {
  required String id,
  required String name,
  required List<ModeApp> apps,
  required Duration duration,
}) async {
  final service = ref.read(usageServiceProvider);
  final messenger = ScaffoldMessenger.of(context);

  final blocking = await service.permissionState(EnforcementPermission.accessibility);
  if (blocking != PermissionState.granted) {
    if (!context.mounted) return false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn on blocking first'),
        content: Text(
          '$name keeps apps closed by covering them. That needs the Focus '
          'accessibility service to be on.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    if (proceed == true && context.mounted) await showAccessibilityDisclosure(context, ref);
    return false;
  }

  if (!context.mounted) return false;
  final now = ref.read(clockProvider).now();
  final until = endTimeLabel(context, now, now.add(duration));
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Lock in until $until?'),
      content: Text(
        '${_appsPhrase(apps)} will stay closed until $until. You won\'t be able to '
        'end this early, so only continue if you\'re sure.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lock in')),
      ],
    ),
  );
  if (confirmed != true) return false;

  final notifications = await service.permissionState(EnforcementPermission.notifications);
  if (notifications != PermissionState.granted && notifications != PermissionState.unsupported) {
    if (!context.mounted) return false;
    final allow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Get a heads-up when it ends'),
        content: const Text(
          'Focus can show a countdown while this runs and tell you when it has '
          'finished. It works either way.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow notifications'),
          ),
        ],
      ),
    );
    if (allow == true) await service.requestPermission(EnforcementPermission.notifications);
  }

  try {
    await service.startMode(
      id: id,
      name: name,
      packageNames: [for (final a in apps) a.packageName],
      duration: duration,
    );
    ref.invalidate(activeModesProvider);
    messenger.showSnackBar(SnackBar(content: Text('$name is locked in')));
    return true;
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Couldn\'t start it. Please try again.')),
    );
    return false;
  }
}
