import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glow_ring.dart';

class _Page {
  const _Page(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _Page(
    Icons.self_improvement,
    'Spend your time on purpose',
    'Focus helps you set daily limits for the apps you want to use less, '
        'and gently steps in when you reach them.',
  ),
  _Page(
    Icons.timer_outlined,
    'How usage is measured',
    'Focus counts the time an app is actually on your screen, using your '
        'phone\'s own usage data. It is not a stopwatch you start and stop.',
  ),
  _Page(
    Icons.lock_outline,
    'How blocking works',
    'When a limit is reached, the app is covered by a calm screen that tells '
        'you when it opens again. Phone calls, emergency services and system '
        'settings are never blocked.',
  ),
  _Page(
    Icons.shield_outlined,
    'Your data stays with you',
    'Usage information is stored only on this device and never sent to a '
        'server. Focus does not read what you do inside other apps.',
  ),
  _Page(
    Icons.tune,
    'Permissions, when you need them',
    'Focus will ask for usage access and notifications only when you set up '
        'your first limit, and will explain each one before asking.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      ref.read(onboardingCompleteProvider.notifier).set(true);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.sizeOf(context).height * 0.5,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GlowRing(icon: page.icon, size: 112),
                              const SizedBox(height: AppSpacing.xl),
                              Text(page.title,
                                  style: theme.textTheme.headlineSmall,
                                  textAlign: TextAlign.center),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                page.body,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(AppSpacing.xs),
                    width: i == _index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(_isLast ? 'Get started' : 'Next'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
