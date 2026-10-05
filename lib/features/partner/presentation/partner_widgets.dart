import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/format/time_format.dart';
import '../../../core/theme/app_theme.dart';

export '../../../core/widgets/glow_ring.dart';

/// Six-digit code entry, spaced out like an authenticator display.
class CodeField extends StatelessWidget {
  const CodeField({super.key, required this.controller, this.onChanged, this.autofocus = false});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 28,
        letterSpacing: 10,
        color: AppColors.text,
      ),
      decoration: const InputDecoration(
        counterText: '',
        hintText: '000000',
        hintStyle: TextStyle(color: AppColors.outlineStrong, letterSpacing: 10),
        semanticCounterText: '',
        labelText: '6-digit code',
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
    );
  }
}

/// Asks for the partner's "Remove block" code before a protected change.
/// Returns true only when the code was right.
Future<bool> askPartnerCode(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => _PartnerCodeDialog(title: title, message: message),
      ) ==
      true;
}

class _PartnerCodeDialog extends ConsumerStatefulWidget {
  const _PartnerCodeDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  ConsumerState<_PartnerCodeDialog> createState() => _PartnerCodeDialogState();
}

class _PartnerCodeDialogState extends ConsumerState<_PartnerCodeDialog> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final outcome = await ref.read(partnerProvider.notifier).verify(_code.text, removeOnly: true);
    if (!mounted) return;
    if (outcome != null && outcome.ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _code.clear();
      _error = outcome?.lockedOutUntil != null
          ? 'Too many tries. Try again at '
              '${endTimeLabel(context, ref.read(clockProvider).now(), outcome!.lockedOutUntil!)}.'
          : 'That code didn\'t work. ${outcome?.attemptsLeft ?? 0} tries left.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            const SizedBox(height: AppSpacing.md),
            CodeField(controller: _code, autofocus: true, onChanged: (_) => setState(() {})),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _code.text.length == 6 && !_busy ? _confirm : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
