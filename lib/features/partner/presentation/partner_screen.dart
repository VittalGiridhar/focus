import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/format/duration_format.dart';
import '../../../core/format/time_format.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/partner.dart';
import '../domain/totp.dart';
import 'partner_widgets.dart';

/// Set up, review, change or remove the person who can unlock blocks.
class PartnerScreen extends ConsumerWidget {
  const PartnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(partnerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Unlock partner')),
      body: SafeArea(
        child: partner.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Couldn\'t load your partner settings.')),
          data: (config) => config == null ? const _PartnerSetup() : _PartnerSummary(config: config),
        ),
      ),
    );
  }
}

class _PartnerSummary extends ConsumerWidget {
  const _PartnerSummary({required this.config});

  final PartnerConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Future<void> protectedClear(String title, String done) async {
      final ok = await askPartnerCode(
        context,
        ref,
        title: title,
        message: 'Ask your partner for the code from their "Focus: Remove block" entry.',
      );
      if (!ok || !context.mounted) return;
      await ref.read(partnerProvider.notifier).clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Center(child: GlowRing(icon: Icons.verified_user_outlined)),
        const SizedBox(height: AppSpacing.lg),
        const Center(child: HudLabel('Partner active')),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            config.maskedPhone,
            style: theme.textTheme.headlineMedium?.copyWith(fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HudLabel('How unlocking works'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'When a block is on, you can send your partner a request. Their '
                  '"Temporary unlock" code opens the app for ${formatDuration(config.unlockWindow)}, '
                  'then it locks again. Their "Remove block" code removes the app\'s block and limit.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton(
          onPressed: () => protectedClear('Change partner?', 'Partner removed. Set up the new one now.'),
          child: const Text('Change partner'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: () => protectedClear('Remove partner?', 'Partner removed.'),
          child: const Text('Remove partner'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Changing or removing your partner needs their "Remove block" code, so it '
          'can\'t be used to get around a block.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _PartnerSetup extends ConsumerStatefulWidget {
  const _PartnerSetup();

  @override
  ConsumerState<_PartnerSetup> createState() => _PartnerSetupState();
}

class _PartnerSetupState extends ConsumerState<_PartnerSetup> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  Duration _window = const Duration(minutes: 15);
  int _step = 0;
  String? _phoneNumber;
  Uint8List? _tempSecret;
  Uint8List? _removeSecret;
  int _tempCounter = -1;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _start() {
    final phone = PartnerConfig.normalizePhone(_phone.text);
    if (phone == null) {
      setState(() => _error = 'Enter your partner\'s number with country code, e.g. +91 98765 43210.');
      return;
    }
    final generate = ref.read(secretGeneratorProvider);
    setState(() {
      _phoneNumber = phone;
      _tempSecret = generate();
      _removeSecret = generate();
      _error = null;
      _step = 1;
    });
  }

  Future<void> _verifyStep() async {
    final now = ref.read(clockProvider).now();
    final secret = _step == 1 ? _tempSecret! : _removeSecret!;
    final counter = Totp.match(secret, _code.text, now);
    if (counter == null) {
      setState(() {
        _error = 'That code doesn\'t match. Check the entry was scanned, then try the newest code.';
        _code.clear();
      });
      return;
    }
    if (_step == 1) {
      setState(() {
        _tempCounter = counter;
        _step = 2;
        _error = null;
        _code.clear();
      });
      return;
    }
    await ref.read(partnerProvider.notifier).save(PartnerConfig(
          phone: _phoneNumber!,
          unlockWindow: _window,
          temporarySecret: Totp.base32Encode(_tempSecret!),
          removeSecret: Totp.base32Encode(_removeSecret!),
          lastTemporaryCounter: _tempCounter,
          lastRemoveCounter: counter,
        ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partner added. Only they can unlock your blocks now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(lockStateProvider);
    final theme = Theme.of(context);
    // Adding a partner mid-block would let someone add themselves and unlock right away.
    if (lock.anyLock) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GlowRing(icon: Icons.lock_clock_outlined),
            const SizedBox(height: AppSpacing.lg),
            Text('Not while something is locked', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You can add a partner after '
              '${endTimeLabel(context, ref.read(clockProvider).now(), lock.anyLockUntil!)}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        HudLabel('Step ${_step + 1} of 3'),
        const SizedBox(height: AppSpacing.sm),
        ...switch (_step) {
          0 => _intro(theme),
          1 => _scan(theme, _tempSecret!, 'Temporary unlock',
              'This code gives you a ${formatDuration(_window)} break.'),
          _ => _scan(theme, _removeSecret!, 'Remove block',
              'This code removes a block completely, and is needed to change the partner.'),
        },
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: const TextStyle(color: AppColors.danger)),
        ],
      ],
    );
  }

  List<Widget> _intro(ThemeData theme) => [
        Text('Choose someone you trust', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'When a block is on, you can ask them for a code. They decide whether you get a '
          'short break or the block is removed. Do this together: they\'ll scan two codes '
          'with Google Authenticator (or any authenticator app) on their phone.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Partner\'s phone number',
            hintText: '+91 98765 43210',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const HudLabel('Break length'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final w in PartnerConfig.windows)
              ChoiceChip(
                label: Text(formatDuration(w)),
                selected: _window == w,
                onSelected: (_) => setState(() => _window = w),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(onPressed: _start, child: const Text('Continue')),
      ];

  List<Widget> _scan(ThemeData theme, Uint8List secret, String account, String purpose) {
    final key = Totp.base32Encode(secret);
    final grouped = [
      for (var i = 0; i < key.length; i += 4) key.substring(i, i + 4 > key.length ? key.length : i + 4),
    ].join(' ');
    return [
      Text('Partner scans "$account"', style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'On their phone: open the authenticator app, tap +, then "Scan a QR code". $purpose',
        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
      const SizedBox(height: AppSpacing.lg),
      Center(
        child: Semantics(
          label: 'QR code for the partner\'s authenticator app',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: QrImageView(
              data: Totp.otpauthUri(secretBase32: key, account: account),
              size: 220,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      const Center(child: HudLabel('Can\'t scan? Setup key')),
      const SizedBox(height: AppSpacing.xs),
      Center(
        child: SelectableText(
          grouped,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 15, letterSpacing: 1.5),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text('Type the 6-digit code their app now shows for "$account"',
          style: theme.textTheme.bodyMedium),
      const SizedBox(height: AppSpacing.sm),
      CodeField(controller: _code, onChanged: (_) => setState(() {})),
      const SizedBox(height: AppSpacing.lg),
      FilledButton(
        onPressed: _code.text.length == 6 ? _verifyStep : null,
        child: Text(_step == 1 ? 'Verify and continue' : 'Verify and finish'),
      ),
    ];
  }
}
