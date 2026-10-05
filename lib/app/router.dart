import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/home/home_shell.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/limits/presentation/limits_screen.dart';
import '../features/modes/presentation/modes_screen.dart';
import '../features/modes/presentation/quick_block_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/partner/presentation/partner_screen.dart';
import '../features/partner/presentation/unlock_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(onboardingCompleteProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final done = ref.read(onboardingCompleteProvider);
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!done && !atOnboarding) return '/onboarding';
      if (done && atOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/quick-block', builder: (_, __) => const QuickBlockScreen()),
      GoRoute(path: '/partner', builder: (_, __) => const PartnerScreen()),
      GoRoute(
        path: '/unlock',
        builder: (_, state) => UnlockScreen(args: state.extra! as UnlockArgs),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/limits', builder: (_, __) => const LimitsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/modes', builder: (_, __) => const ModesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/insights', builder: (_, __) => const InsightsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
