import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/app/providers.dart';
import 'package:focus/core/time/clock.dart';
import 'package:focus/data/db/app_database.dart';
import 'package:focus/main.dart';
import 'package:focus/platform/usage_tracking_service.dart';

/// Pumps the whole app on an in-memory database with a fake platform layer.
Future<AppDatabase> pump(
  WidgetTester tester, {
  required bool onboarded,
  Size size = const Size(390, 844),
  double textScale = 1.0,
  FakeUsageTrackingService? service,
  Clock? clock,
  bool recovered = false,
  List<Uint8List>? secrets,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final queue = [...?secrets];
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      databaseRecoveredProvider.overrideWithValue(recovered),
      initialOnboardingCompleteProvider.overrideWithValue(onboarded),
      usageServiceProvider.overrideWithValue(service ?? FakeUsageTrackingService()),
      if (clock != null) clockProvider.overrideWithValue(clock),
      // The real ticker would keep pumpAndSettle from ever settling.
      clockTickProvider.overrideWith(
        (ref) => Stream.value((clock ?? const SystemClock()).now()),
      ),
      if (secrets != null) secretGeneratorProvider.overrideWithValue(() => queue.removeAt(0)),
    ],
    child: const FocusApp(),
  ));
  await tester.pumpAndSettle();
  return db;
}

// Drift schedules a zero-duration timer when a query stream is cancelled, so the
// tree must be unmounted and the timer flushed before the test ends.
void appTest(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}

final noon = DateTime(2026, 3, 10, 12);

FakeUsageTrackingService modeService(Clock clock) => FakeUsageTrackingService(clock)
  ..permissions[EnforcementPermission.usageAccess] = PermissionState.granted
  ..apps = const [
    InstalledApp(packageName: 'com.yt', label: 'YouTube'),
    InstalledApp(packageName: 'com.ig', label: 'Instagram'),
  ];
