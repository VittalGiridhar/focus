import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../platform/usage_tracking_service.dart';

class UsageAccessCard extends ConsumerWidget {
  const UsageAccessCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyState(
      icon: Icons.lock_open_outlined,
      title: 'Allow usage access',
      message: 'Focus needs usage access to see how long each app is on your screen. '
          'Android will open a settings page: find Focus and turn on '
          '"Allow usage access". This information stays on your device.',
      action: FilledButton(
        onPressed: () => ref
            .read(usageServiceProvider)
            .openPermissionSettings(EnforcementPermission.usageAccess),
        child: const Text('Open settings'),
      ),
    );
  }
}
