import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/format/duration_format.dart';
import 'package:focus/core/time/clock.dart';
import 'package:focus/data/db/app_database.dart';
import 'package:focus/features/limits/data/limits_repository.dart';
import 'package:focus/features/limits/domain/usage_models.dart';
import 'package:focus/features/modes/data/modes_repository.dart';
import 'package:focus/features/modes/domain/mode.dart';
import 'package:focus/platform/usage_tracking_service.dart';

import 'support/harness.dart';

FakeUsageTrackingService insightsService() {
  final svc = modeService(FixedClock(noon))
    ..permissions[EnforcementPermission.accessibility] = PermissionState.granted;
  for (final (day, minutes) in [(8, 90), (9, 60), (10, 20)]) {
    svc.sessions.add(UsageSession(
      appId: 'com.yt',
      start: DateTime(2026, 3, day, 9),
      end: DateTime(2026, 3, day, 9).add(Duration(minutes: minutes)),
    ));
  }
  svc.sessions.add(UsageSession(
    appId: 'com.ig',
    start: DateTime(2026, 3, 9, 20),
    end: DateTime(2026, 3, 9, 20, 15),
  ));
  return svc;
}

Future<void> seedMode(AppDatabase db, WidgetTester tester) async {
  await ModesRepository(db, FixedClock(noon)).create(
    name: 'Deep Work',
    duration: const Duration(hours: 1),
    apps: const [ModeApp(packageName: 'com.yt', label: 'YouTube')],
  );
  await tester.pumpAndSettle();
}

void main() {
  appTest('first launch shows onboarding and completes into the app', (tester) async {
    await pump(tester, onboarded: false);
    expect(find.text('Spend your time on purpose'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Permissions, when you need them'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Allow usage access'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  appTest('onboarded users with access land on an empty dashboard', (tester) async {
    final service = FakeUsageTrackingService()
      ..permissions[EnforcementPermission.usageAccess] = PermissionState.granted;
    await pump(tester, onboarded: true, service: service);
    expect(find.text('No usage to show yet'), findsOneWidget);
  });

  appTest('create, duplicate and delete a mode', (tester) async {
    await pump(tester, onboarded: true, service: modeService(FixedClock(noon)));
    await tester.tap(find.text('Modes'));
    await tester.pumpAndSettle();
    expect(find.text('Create your first mode'), findsOneWidget);

    await tester.tap(find.text('New mode'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Deep Work');
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '2 hours'));
    await tester.tap(find.widgetWithText(ChoiceChip, '2 hours'));
    await tester.pump();
    await tester.ensureVisible(find.text('Choose apps'));
    await tester.tap(find.text('Choose apps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YouTube'));
    await tester.pump();
    await tester.tap(find.text('Instagram'));
    await tester.pump();
    await tester.tap(find.text('Done (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Deep Work'), findsOneWidget);
    expect(find.text('2 hours · 2 apps'), findsOneWidget);
    expect(find.text('Instagram, YouTube'), findsOneWidget);

    await tester.tap(find.byTooltip('Mode options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    expect(find.text('Deep Work copy'), findsOneWidget);

    await tester.tap(find.byTooltip('Mode options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Deep Work'), findsNothing);
    expect(find.text('Deep Work copy'), findsOneWidget);
  });

  appTest('limits asks for usage access and opens settings', (tester) async {
    final service = FakeUsageTrackingService()
      ..permissions[EnforcementPermission.usageAccess] = PermissionState.denied;
    await pump(tester, onboarded: true, service: service);
    expect(find.text('Allow usage access'), findsOneWidget);

    await tester.tap(find.text('Limits'));
    await tester.pumpAndSettle();
    expect(find.text('Allow usage access'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(service.settingsOpened, 1);
  });

  FakeUsageTrackingService grantedService() {
    final day = DateTime(2026, 3, 10);
    return FakeUsageTrackingService()
      ..permissions[EnforcementPermission.usageAccess] = PermissionState.granted
      ..apps = const [
        InstalledApp(packageName: 'com.yt', label: 'YouTube'),
        InstalledApp(packageName: 'com.ig', label: 'Instagram'),
      ]
      ..sessions.addAll([
        UsageSession(
          appId: 'com.yt',
          start: day.add(const Duration(hours: 10)),
          end: day.add(const Duration(hours: 10, minutes: 20)),
        ),
        UsageSession(
          appId: 'com.yt',
          start: day.add(const Duration(hours: 11)),
          end: day.add(const Duration(hours: 11, minutes: 40)),
        ),
      ]);
  }

  appTest('add a limit, then Today shows usage reaching the limit', (tester) async {
    await pump(
      tester,
      onboarded: true,
      service: grantedService(),
      clock: FixedClock(DateTime(2026, 3, 10, 12)),
    );
    expect(find.text('No usage to show yet'), findsOneWidget);

    await tester.tap(find.text('Limits'));
    await tester.pumpAndSettle();
    expect(find.text('No limits yet'), findsOneWidget);

    await tester.tap(find.text('Add limit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '1 hour'));
    await tester.tap(find.widgetWithText(ChoiceChip, '1 hour'));
    await tester.tap(find.text('Save limit'));
    await tester.pumpAndSettle();
    // The hour is already used up today, so the new limit is immediately locked.
    expect(find.textContaining('1 hour per day · Locked until'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('1 hour / 1 hour'), findsOneWidget);
    expect(find.text('Daily limit reached'), findsOneWidget);
  });

  appTest('blocking card explains accessibility use before opening settings', (tester) async {
    final service = grantedService()
      ..permissions[EnforcementPermission.accessibility] = PermissionState.denied;
    await pump(tester, onboarded: true, service: service);
    await tester.tap(find.text('Limits'));
    await tester.pumpAndSettle();
    expect(find.text('Blocking is off'), findsOneWidget);

    await tester.tap(find.text('Turn on blocking'));
    await tester.pumpAndSettle();
    expect(find.text('Allow Focus to see which app is open'), findsOneWidget);
    expect(find.textContaining('does not read your screen'), findsOneWidget);
    expect(service.settingsOpened, 0);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(service.settingsOpened, 0);

    await tester.tap(find.text('Turn on blocking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agree and continue'));
    await tester.pumpAndSettle();
    expect(service.lastSettingsOpened, EnforcementPermission.accessibility);
  });

  appTest('blocking card is hidden once accessibility is enabled', (tester) async {
    final service = grantedService()
      ..permissions[EnforcementPermission.accessibility] = PermissionState.granted;
    await pump(tester, onboarded: true, service: service);
    await tester.tap(find.text('Limits'));
    await tester.pumpAndSettle();
    expect(find.text('Blocking is off'), findsNothing);
  });

  appTest('limits are synced to the native layer when they change', (tester) async {
    final service = grantedService();
    await pump(
      tester,
      onboarded: true,
      service: service,
      clock: FixedClock(DateTime(2026, 3, 10, 12)),
    );
    expect(service.syncedLimits, isEmpty);

    await tester.tap(find.text('Limits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add limit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '30 min'));
    await tester.tap(find.text('Save limit'));
    await tester.pumpAndSettle();

    expect(service.syncedLimits.single.appId, 'com.yt');
    expect(service.syncedLimits.single.dailyLimit, const Duration(minutes: 30));
  });

  appTest('limit editor needs no typing: scroll the wheels and the limit is saved', (tester) async {
    final service = grantedService();
    await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await tester.tap(find.text('Limits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add limit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instagram'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);

    // Starts at 30 min; scroll hours up by 2 and minutes up by 1 -> 2h 31m.
    await tester.drag(find.byKey(const Key('wheel-hours')), const Offset(0, -88));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('wheel-minutes')), const Offset(0, -44));
    await tester.pumpAndSettle();
    expect(find.text('2h 31m'), findsOneWidget);

    await tester.tap(find.text('Save limit'));
    await tester.pumpAndSettle();
    expect(service.syncedLimits.single.dailyLimit, const Duration(hours: 2, minutes: 31));
  });

  appTest('mode editor requires at least one app', (tester) async {
    await pump(tester, onboarded: true, service: modeService(FixedClock(noon)));
    await tester.tap(find.text('Modes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New mode'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Study');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Choose at least one app'), findsOneWidget);
  });

  appTest('starting a mode asks to turn on blocking first', (tester) async {
    final service = modeService(FixedClock(noon))
      ..permissions[EnforcementPermission.accessibility] = PermissionState.denied;
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await seedMode(db, tester);
    await tester.tap(find.text('Modes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Turn on blocking first'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Allow Focus to see which app is open'), findsOneWidget);
    expect(service.active, isEmpty);
  });

appTest('starting a mode needs a confirmation, then it cannot be edited or ended', (tester) async {
    final service = modeService(FixedClock(noon))
      ..permissions[EnforcementPermission.accessibility] = PermissionState.granted
      ..permissions[EnforcementPermission.notifications] = PermissionState.notDetermined;
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await seedMode(db, tester);
    await tester.tap(find.text('Modes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lock in until 1:00'), findsOneWidget);
    expect(find.textContaining('end this early'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.active, isEmpty);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lock in'));
    await tester.pumpAndSettle();
    expect(find.text('Get a heads-up when it ends'), findsOneWidget);
    await tester.tap(find.text('Allow notifications'));
    await tester.pumpAndSettle();

    expect(service.permissionRequests, 1);
    expect(service.active.single.name, 'Deep Work');
    expect(service.active.single.packageNames, ['com.yt']);
    expect(find.text('01:00:00'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    // There is no way to end it, and the mode can no longer be edited or deleted.
    expect(find.text('End early'), findsNothing);
    expect(find.byTooltip('Mode options'), findsNothing);
    expect(find.textContaining('Can\'t be changed or ended until 1:00'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Deep Work'), findsOneWidget);
    expect(find.text('01:00:00'), findsOneWidget);
  });

  appTest('an expired block does not cause endless refreshes', (tester) async {
    // The native layer keeps reporting a block whose end is already in the past.
    final service = modeService(FixedClock(noon))
      ..active = [
        ActiveMode(
          id: 'm1',
          name: 'Deep Work',
          packageNames: const ['com.yt'],
          endsAt: noon.subtract(const Duration(minutes: 5)),
        ),
      ];
    await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await tester.tap(find.text('Modes'));
    await tester.pumpAndSettle();
    // The fake drops expired blocks, so nothing is shown and nothing loops.
    expect(find.text('00:00:00'), findsNothing);
  });

  appTest('a block still starts when notifications are declined', (tester) async {
    final service = modeService(FixedClock(noon))
      ..permissions[EnforcementPermission.accessibility] = PermissionState.granted
      ..permissions[EnforcementPermission.notifications] = PermissionState.denied
      ..requestResult = PermissionState.denied;
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await seedMode(db, tester);
    await tester.tap(find.text('Modes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lock in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(service.permissionRequests, 0);
    expect(service.active, isNotEmpty);
  });

  FakeUsageTrackingService readyService() => modeService(FixedClock(noon))
    ..permissions[EnforcementPermission.accessibility] = PermissionState.granted
    ..permissions[EnforcementPermission.notifications] = PermissionState.granted;

  appTest('quick block: pick an app and a time, confirm once, and it is locked in', (tester) async {
    final service = readyService();
    await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));

    await tester.tap(find.text('Block an app now'));
    await tester.pumpAndSettle();
    expect(find.text('For how long?'), findsOneWidget);
    ButtonStyleButton blockButton() => tester.widget<ButtonStyleButton>(find.ancestor(
          of: find.textContaining('Block until'),
          matching: find.bySubtype<ButtonStyleButton>(),
        ));
    expect(blockButton().onPressed, isNull); // no app chosen yet

    await tester.tap(find.text('Choose apps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instagram'));
    await tester.pump();
    await tester.tap(find.text('Done (1)'));
    await tester.pumpAndSettle();
    expect(find.byType(Chip), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '2 min'));
    await tester.pumpAndSettle();
    expect(find.text('Block until 12:02 PM'), findsOneWidget);
    expect(blockButton().onPressed, isNotNull);

    await tester.ensureVisible(find.textContaining('Block until'));
    await tester.tap(find.textContaining('Block until'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lock in until 12:02'), findsOneWidget);
    await tester.tap(find.text('Lock in'));
    await tester.pumpAndSettle();

    final block = service.active.single;
    expect(block.isQuick, isTrue);
    expect(block.name, 'Instagram');
    expect(block.packageNames, ['com.ig']);
    expect(block.endsAt, noon.add(const Duration(minutes: 2)));
    // Back on Today with the countdown running.
    expect(find.text('00:02:00'), findsOneWidget);
  });

  appTest('cancelling the lock-in confirmation starts nothing', (tester) async {
    final service = readyService();
    await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await tester.tap(find.text('Block an app now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose apps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YouTube'));
    await tester.pump();
    await tester.tap(find.text('Done (1)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Block until'));
    await tester.tap(find.textContaining('Block until'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.active, isEmpty);
    expect(find.text('For how long?'), findsOneWidget);
  });

  appTest('a limit that is used up is locked and cannot be removed or loosened', (tester) async {
    final service = grantedService()
      ..permissions[EnforcementPermission.accessibility] = PermissionState.granted;
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    final repo = LimitsRepository(db);
    // YouTube has 1 hour used today, so a 1 hour limit is reached; Instagram is untouched.
    await repo.upsert(LimitRule(appId: 'com.yt', label: 'YouTube', dailyLimit: const Duration(hours: 1)));
    await repo.upsert(LimitRule(appId: 'com.ig', label: 'Instagram', dailyLimit: const Duration(hours: 1)));
    await tester.tap(find.text('Limits'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Locked until tomorrow at 12:00'), findsOneWidget);
    expect(find.byTooltip('Limit options'), findsOneWidget); // only Instagram can be changed

    await tester.tap(find.textContaining('Locked until'));
    await tester.pumpAndSettle();
    expect(find.textContaining('can\'t be changed or removed'), findsOneWidget);
    // A plain query: awaiting a Drift stream would never complete in fake time.
    expect((await db.select(db.limitRules).get()).length, 2);
  });

  appTest('apps in a running block have their limits locked until it ends', (tester) async {
    final service = readyService()
      ..active = [
        ActiveMode(
          id: 'quick-1',
          name: 'YouTube',
          packageNames: const ['com.yt'],
          endsAt: noon.add(const Duration(minutes: 5)),
        ),
      ];
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await LimitsRepository(db)
        .upsert(LimitRule(appId: 'com.yt', label: 'YouTube', dailyLimit: const Duration(hours: 2)));
    await tester.tap(find.text('Limits'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Locked until 12:05'), findsOneWidget);
    expect(find.byTooltip('Limit options'), findsNothing);
  });

  appTest('insights shows the week, top apps and a gentle message', (tester) async {
    await pump(tester, onboarded: true, service: insightsService(), clock: FixedClock(noon));
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('LAST 7 DAYS'), findsOneWidget);
    expect(find.text('20 min'), findsOneWidget); // today
    expect(find.text('MOST USED THIS WEEK'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('3h'), findsNothing);
    expect(find.text('Today is lighter than your usual. Nice.'), findsOneWidget);
    expect(find.text('Not set. Totally optional.'), findsOneWidget);
  });

  appTest('setting a daily goal updates insights and can be removed', (tester) async {
    await pump(tester, onboarded: true, service: insightsService(), clock: FixedClock(noon));
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Daily goal'), 200);
    await tester.tap(find.text('Daily goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 hours'));
    await tester.pumpAndSettle();

    expect(find.text('Dashed line: your goal of 2 hours'), findsOneWidget);
    expect(find.text('You stayed within your goal on 7 of 7 days.'), findsOneWidget);

    await tester.tap(find.text('Daily goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove goal'));
    await tester.pumpAndSettle();
    expect(find.text('Not set. Totally optional.'), findsOneWidget);
  });

  appTest('insights asks for usage access when it is missing', (tester) async {
    final service = FakeUsageTrackingService()
      ..permissions[EnforcementPermission.usageAccess] = PermissionState.denied;
    await pump(tester, onboarded: true, service: service);
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Allow usage access'), findsOneWidget);
  });

  appTest('insights fits a small phone with large text', (tester) async {
    await pump(
      tester,
      onboarded: true,
      service: insightsService(),
      clock: FixedClock(noon),
      size: const Size(320, 568),
      textScale: 2.0,
    );
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('MOST USED THIS WEEK'), 300);
    expect(tester.takeException(), isNull);
  });

  appTest('quiet hours are saved and synced to the native layer', (tester) async {
    final service = modeService(FixedClock(noon));
    await pump(tester, onboarded: true, service: service);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(service.syncedQuietHours.enabled, isFalse);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Quiet hours'));
    await tester.pumpAndSettle();
    expect(service.syncedQuietHours.enabled, isTrue);
    expect(service.syncedQuietHours.startMinute, 22 * 60);
    expect(service.syncedQuietHours.endMinute, 7 * 60);
  });

  appTest('quiet hours cannot be switched off or changed while they are running', (tester) async {
    final late = DateTime(2026, 3, 10, 23);
    final service = FakeUsageTrackingService(FixedClock(late))
      ..permissions[EnforcementPermission.usageAccess] = PermissionState.granted
      ..apps = const [InstalledApp(packageName: 'com.yt', label: 'YouTube')];
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(late));
    await LimitsRepository(db)
        .upsert(LimitRule(appId: 'com.yt', label: 'YouTube', dailyLimit: const Duration(hours: 1)));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    final quiet = find.widgetWithText(SwitchListTile, 'Quiet hours');
    expect(tester.widget<SwitchListTile>(quiet).onChanged, isNotNull);
    await tester.tap(quiet);
    await tester.pumpAndSettle();
    expect(service.syncedQuietHours.enabled, isTrue);

    // 11 PM is inside 10 PM - 7 AM, so it is now locked.
    expect(tester.widget<SwitchListTile>(quiet).onChanged, isNull);
    expect(find.textContaining('Locked until tomorrow at 7:00'), findsWidgets);
    expect(tester.widget<ListTile>(find.widgetWithText(ListTile, 'Starts')).enabled, isFalse);
    expect(tester.widget<ListTile>(find.widgetWithText(ListTile, 'Ends')).enabled, isFalse);
  });

  appTest('delete all data is locked while a block is running', (tester) async {
    final service = modeService(FixedClock(noon))
      ..active = [
        ActiveMode(
          id: 'quick-1',
          name: 'YouTube',
          packageNames: const ['com.yt'],
          endsAt: noon.add(const Duration(hours: 1)),
        ),
      ];
    await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete all my data'), 200);
    final tile = find.widgetWithText(ListTile, 'Delete all my data');
    expect(tester.widget<ListTile>(tile).enabled, isFalse);
    expect(find.textContaining('Locked until 1:00'), findsWidgets);
    await tester.tap(find.text('Delete all my data'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Delete all your data?'), findsNothing);
    expect(service.nativeErased, isFalse);
  });

  appTest('uninstall protection explains itself before asking Android', (tester) async {
    final service = modeService(FixedClock(noon))
      ..permissions[EnforcementPermission.uninstallProtection] = PermissionState.denied;
    await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final toggle = find.widgetWithText(SwitchListTile, 'Uninstall protection');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('Turn on uninstall protection?'), findsOneWidget);
    expect(find.textContaining('cannot lock, wipe or see anything'), findsOneWidget);
    expect(find.textContaining('strong nudge, not a guarantee'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(service.settingsOpened, 0);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agree and continue'));
    await tester.pumpAndSettle();
    expect(service.lastSettingsOpened, EnforcementPermission.uninstallProtection);
  });

  appTest('uninstall protection can be turned off only when nothing is locked', (tester) async {
    final service = modeService(FixedClock(noon))
      ..permissions[EnforcementPermission.uninstallProtection] = PermissionState.granted;
    await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final toggle = find.widgetWithText(SwitchListTile, 'Uninstall protection');
    await tester.ensureVisible(toggle);
    expect(tester.widget<SwitchListTile>(toggle).onChanged, isNotNull);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(service.protectionRemoved, isTrue);
  });

  appTest('uninstall protection stays on while a block is running', (tester) async {
    final service = modeService(FixedClock(noon))
      ..permissions[EnforcementPermission.uninstallProtection] = PermissionState.granted
      ..active = [
        ActiveMode(
          id: 'quick-1',
          name: 'YouTube',
          packageNames: const ['com.yt'],
          endsAt: noon.add(const Duration(minutes: 30)),
        ),
      ];
    await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    final toggle = find.widgetWithText(SwitchListTile, 'Uninstall protection');
    await tester.ensureVisible(toggle);
    expect(tester.widget<SwitchListTile>(toggle).onChanged, isNull);
    expect(find.textContaining('On. Locked until 12:30'), findsOneWidget);
    expect(service.protectionRemoved, isFalse);
  });

  appTest('deleting all data clears native data and returns to the introduction', (tester) async {
    final service = modeService(FixedClock(noon));
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await ModesRepository(db, FixedClock(noon)).create(
      name: 'Study',
      duration: const Duration(hours: 1),
      apps: const [ModeApp(packageName: 'com.yt', label: 'YouTube')],
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete all my data'), 200);
    await tester.tap(find.text('Delete all my data'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all your data?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(service.nativeErased, isTrue);
    expect(await db.select(db.modes).get(), isEmpty);
    expect(find.text('Spend your time on purpose'), findsOneWidget);
  });

  appTest('cancelling delete keeps the data', (tester) async {
    final service = modeService(FixedClock(noon));
    await pump(tester, onboarded: true, service: service);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete all my data'), 200);
    await tester.tap(find.text('Delete all my data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.nativeErased, isFalse);
    expect(find.text('Settings'), findsWidgets);
  });

  appTest('the user is told when saved data could not be read', (tester) async {
    await pump(tester, onboarded: true, recovered: true);
    expect(find.text('Starting fresh'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Starting fresh'), findsNothing);
  });

  test('countdown formatting', () {
    expect(formatCountdown(const Duration(hours: 1, minutes: 24, seconds: 5)), '01:24:05');
    expect(formatCountdown(Duration.zero), '00:00:00');
    expect(formatCountdown(const Duration(seconds: -4)), '00:00:00');
    expect(formatCountdown(const Duration(hours: 24)), '24:00:00');
  });

  appTest('mode editor rejects an empty name', (tester) async {
    await pump(tester, onboarded: true);
    await tester.tap(find.text('Modes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter a name'), findsOneWidget);
  });

  for (final (label, size, scale) in [
    ('small phone, large text', const Size(320, 568), 2.0),
    ('tablet', const Size(800, 1280), 1.0),
  ]) {
    appTest('onboarding has no overflow on $label', (tester) async {
      await pump(tester, onboarded: false, size: size, textScale: scale);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
