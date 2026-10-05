import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/duration_format.dart';
import '../../../core/format/time_format.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/partner.dart';
import 'partner_widgets.dart';

class UnlockArgs {
  const UnlockArgs(this.packageNames, {this.labels = const {}});

  final List<String> packageNames;
  final Map<String, String> labels;
}

/// Ask the partner, then enter the code they give. Their code decides the outcome.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key, required this.args});

  final UnlockArgs args;

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _code = TextEditingController();
  late String _package = widget.args.packageNames.first;
  String? _error;
  String? _info;
  bool _busy = false;
  UnlockKind? _result;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _label(String pkg) {
    final known = widget.args.labels[pkg];
    if (known != null) return known;
    final apps = ref.read(installedAppsProvider).valueOrNull ?? const [];
    return apps.where((a) => a.packageName == pkg).map((a) => a.label).firstOrNull ?? pkg;
  }

  Future<void> _ask(PartnerConfig partner, {required bool whatsapp}) async {
    final label = _label(_package);
    final body = 'Focus unlock request: may I open $label? If yes, send me the code from '
        'your authenticator app - "Focus: Temporary unlock" for a '
        '${formatDuration(partner.unlockWindow)} break, or "Focus: Remove block" to remove '
        'the block completely.';
    final sent = await ref
        .read(usageServiceProvider)
        .sendUnlockRequest(number: partner.phone, body: body, whatsapp: whatsapp);
    if (!mounted) return;
    setState(() => _info = sent
        ? 'Request ready to send. Enter their code below when you get it.'
        : 'Couldn\'t open ${whatsapp ? 'WhatsApp' : 'your messages app'}. Try the other option or call them.');
  }

  Future<void> _unlock(PartnerConfig partner) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final outcome = await ref.read(partnerProvider.notifier).verify(_code.text);
    if (!mounted) return;
    if (outcome == null || !outcome.ok) {
      setState(() {
        _busy = false;
        _code.clear();
        _error = outcome?.lockedOutUntil != null
            ? 'Too many tries. Try again at '
                '${endTimeLabel(context, ref.read(clockProvider).now(), outcome!.lockedOutUntil!)}.'
            : 'That code didn\'t work. ${outcome?.attemptsLeft ?? 0} tries left.';
      });
      return;
    }

    final service = ref.read(usageServiceProvider);
    final label = _label(_package);
    if (outcome.kind == UnlockKind.temporary) {
      await service.grantAccess(packageName: _package, label: label, duration: partner.unlockWindow);
      ref.invalidate(activeGrantsProvider);
    } else {
      await ref.read(limitsRepositoryProvider).delete(_package);
      await service.removeFromBlocks(_package);
      ref.invalidate(activeModesProvider);
      ref.invalidate(todayUsageProvider);
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _result = outcome.kind;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(partnerProvider).valueOrNull;
    ref.watch(installedAppsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Request unlock')),
      body: SafeArea(
        child: _result != null
            ? _success(context, partner)
            : partner == null
                ? _noPartner(context)
                : _request(context, partner),
      ),
    );
  }

  Widget _noPartner(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GlowRing(icon: Icons.lock_outline),
          const SizedBox(height: AppSpacing.lg),
          Text('No unlock partner', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Blocks can only be ended early by a partner you trust. You can add one in '
            'Settings when nothing is locked.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _request(BuildContext context, PartnerConfig partner) {
    final theme = Theme.of(context);
    final label = _label(_package);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const HudLabel('Unlock request'),
        const SizedBox(height: AppSpacing.xs),
        Text('Open $label', style: theme.textTheme.headlineMedium),
        if (widget.args.packageNames.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final pkg in widget.args.packageNames)
                ChoiceChip(
                  label: Text(_label(pkg)),
                  selected: pkg == _package,
                  onSelected: (_) => setState(() => _package = pkg),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HudLabel('Step 1 · Ask your partner'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Send a request to ${partner.maskedPhone}. They decide whether you get a '
                  '${formatDuration(partner.unlockWindow)} break or the block is removed.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _ask(partner, whatsapp: false),
                        icon: const Icon(Icons.sms_outlined),
                        label: const Text('SMS'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _ask(partner, whatsapp: true),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
                if (_info != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_info!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HudLabel('Step 2 · Enter their code'),
                const SizedBox(height: AppSpacing.md),
                CodeField(controller: _code, onChanged: (_) => setState(() {})),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _code.text.length == 6 && !_busy ? () => _unlock(partner) : null,
                  child: const Text('Unlock'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _success(BuildContext context, PartnerConfig? partner) {
    final theme = Theme.of(context);
    final label = _label(_package);
    final temporary = _result == UnlockKind.temporary;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GlowRing(
              icon: temporary ? Icons.lock_open_outlined : Icons.check,
              color: temporary ? AppColors.accent : AppColors.violet,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            temporary ? '$label is open' : '$label is unblocked',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            temporary
                ? 'You have ${formatDuration(partner?.unlockWindow ?? Duration.zero)}. '
                    'It locks again automatically.'
                : 'Your partner removed its block and daily limit.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Done')),
        ],
      ),
    );
  }
}
