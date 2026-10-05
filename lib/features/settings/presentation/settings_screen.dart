import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/format/time_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../platform/usage_tracking_service.dart';
import '../../partner/presentation/partner_widgets.dart';
import '../domain/quiet_hours.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lock = ref.watch(lockStateProvider);
    final until = lock.anyLockUntil;
    final lockedLabel = until == null
        ? null
        : 'Locked until ${endTimeLabel(context, ref.read(clockProvider).now(), until)}';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Settings', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        const _PartnerCard(),
        const SizedBox(height: AppSpacing.md),
        const _QuietHoursCard(),
        const SizedBox(height: AppSpacing.md),
        const _UninstallProtectionCard(),
        const SizedBox(height: AppSpacing.md),
        const _PrivacyCard(),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          minVerticalPadding: AppSpacing.md,
          leading: const Icon(Icons.replay),
          title: const Text('Replay introduction'),
          onTap: () => ref.read(onboardingCompleteProvider.notifier).set(false),
        ),
        ListTile(
          enabled: !lock.anyLock,
          minVerticalPadding: AppSpacing.md,
          leading: Icon(
            lock.anyLock ? Icons.lock_outline : Icons.delete_outline,
            color: lock.anyLock ? null : theme.colorScheme.error,
          ),
          title: Text(
            'Delete all my data',
            style: lock.anyLock ? null : TextStyle(color: theme.colorScheme.error),
          ),
          subtitle: Text(
            lockedLabel ?? 'Removes limits, modes, goals and settings from this device',
          ),
          onTap: lock.anyLock ? null : () => _confirmErase(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmErase(BuildContext context, WidgetRef ref) async {
    // With a partner, wiping everything would also remove them, so they must agree.
    if (ref.read(partnerProvider).valueOrNull != null) {
      final allowed = await askPartnerCode(
        context,
        ref,
        title: 'Partner approval needed',
        message: 'Deleting your data also removes your unlock partner. Ask them for the '
            'code from their "Focus: Remove block" entry.',
      );
      if (!allowed || !context.mounted) return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all your data?'),
        content: const Text(
          'This removes your limits, modes, goals and settings. It can\'t be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await eraseAllData(ref);
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your data is locked while a block is active.')),
        );
      }
    }
  }
}

class _PartnerCard extends ConsumerWidget {
  const _PartnerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(partnerProvider).valueOrNull;
    return Card(
      child: ListTile(
        minVerticalPadding: AppSpacing.md,
        leading: Icon(
          partner == null ? Icons.person_add_alt_outlined : Icons.verified_user_outlined,
          color: partner == null ? null : AppColors.accent,
        ),
        title: const Text('Unlock partner'),
        subtitle: Text(
          partner == null
              ? 'Someone you trust who can approve a break or remove a block'
              : 'Active · ${partner.maskedPhone}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/partner'),
      ),
    );
  }
}

class _QuietHoursCard extends ConsumerWidget {
  const _QuietHoursCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quiet = ref.watch(quietHoursProvider).valueOrNull ?? QuietHours.off;
    final lock = ref.watch(lockStateProvider);
    final loc = MaterialLocalizations.of(context);
    String fmt(int minute) =>
        loc.formatTimeOfDay(TimeOfDay(hour: minute ~/ 60, minute: minute % 60));
    // While the window is running it cannot be switched off or shortened.
    final locked = lock.isQuietActive;

    Future<void> save(QuietHours next) async {
      if (!next.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start and end times must be different.')),
        );
        return;
      }
      await ref.read(quietHoursProvider.notifier).save(next);
    }

    Future<void> pick(bool start) async {
      final minute = start ? quiet.startMinute : quiet.endMinute;
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
      );
      if (picked == null) return;
      final value = picked.hour * 60 + picked.minute;
      await save(start ? quiet.copyWith(startMinute: value) : quiet.copyWith(endMinute: value));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Quiet hours'),
              subtitle: Text(
                locked
                    ? 'Locked until ${endTimeLabel(context, ref.read(clockProvider).now(), lock.quietUntil!)}'
                    : 'Apps you\'ve set limits for rest while you wind down',
              ),
              value: quiet.enabled,
              onChanged: locked ? null : (v) => save(quiet.copyWith(enabled: v)),
            ),
            ListTile(
              enabled: !locked,
              title: const Text('Starts'),
              trailing: Text(fmt(quiet.startMinute), style: theme.textTheme.titleMedium),
              onTap: locked ? null : () => pick(true),
            ),
            ListTile(
              enabled: !locked,
              title: const Text('Ends'),
              trailing: Text(fmt(quiet.endMinute), style: theme.textTheme.titleMedium),
              onTap: locked ? null : () => pick(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _UninstallProtectionCard extends ConsumerWidget {
  const _UninstallProtectionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uninstallProtectionProvider).valueOrNull;
    if (state == null || state == PermissionState.unsupported) return const SizedBox.shrink();
    final lock = ref.watch(lockStateProvider);
    final on = state == PermissionState.granted;
    // It can always be turned on, but not off while something is locked.
    final canToggle = !on || !lock.anyLock;
    return Card(
      child: SwitchListTile(
        title: const Text('Uninstall protection'),
        subtitle: Text(
          on
              ? (lock.anyLock
                  ? 'On. Locked until ${endTimeLabel(context, ref.read(clockProvider).now(), lock.anyLockUntil!)}'
                  : 'On. Focus can\'t be removed while a block is running.')
              : 'Make Focus harder to remove while a block is running',
        ),
        value: on,
        onChanged: canToggle ? (v) => v ? _enable(context, ref) : _disable(context, ref) : null,
      ),
    );
  }

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn on uninstall protection?'),
        content: const SingleChildScrollView(
          child: Text(
            'Android will ask you to make Focus a device administrator. This gives Focus '
            'no other powers: it cannot lock, wipe or see anything on your phone.\n\n'
            '• While a block, quiet hours or a reached limit is active, Focus also covers '
            'the screens that would uninstall it or switch this off.\n'
            '• When nothing is locked you can turn this off here, or uninstall as usual.\n'
            '• Phone, emergency calls and the rest of Settings always stay available.\n\n'
            'It can still be bypassed by disabling the Focus accessibility service, so it '
            'is a strong nudge, not a guarantee.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
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
          .openPermissionSettings(EnforcementPermission.uninstallProtection);
    }
  }

  Future<void> _disable(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(usageServiceProvider).removeUninstallProtection();
      ref.invalidate(uninstallProtectionProvider);
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('It can\'t be turned off while something is locked.')),
        );
      }
    }
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(String title, String body) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data and privacy', style: theme.textTheme.titleMedium),
            item(
              'What Focus uses',
              'How long each app is on your screen, the names of apps you choose, and your '
                  'limits, modes, goal and quiet hours.',
            ),
            item(
              'Why',
              'To show your usage and to cover apps when you reach a limit or start a mode.',
            ),
            item(
              'Where it lives',
              'Only on this device. Nothing is sent to a server, and it is excluded from '
                  'Android backups. Focus does not read what you do inside other apps.',
            ),
          ],
        ),
      ),
    );
  }
}
