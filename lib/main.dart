import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'core/theme/app_theme.dart';
import 'data/db/database_recovery.dart';
import 'features/settings/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  final opened = await openDatabaseWithRecovery(File(p.join(dir.path, 'focus.sqlite')));
  final onboardingDone = await SettingsRepository(opened.db).isOnboardingComplete();
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(opened.db),
      databaseRecoveredProvider.overrideWithValue(opened.recovered),
      initialOnboardingCompleteProvider.overrideWithValue(onboardingDone),
    ],
    child: const FocusApp(),
  ));
}

class FocusApp extends ConsumerWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(limitsSyncProvider);
    ref.watch(quietHoursSyncProvider);
    ref.watch(partnerSyncProvider);
    return MaterialApp.router(
      title: 'Focus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
