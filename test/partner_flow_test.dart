import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/app/providers.dart';
import 'package:focus/core/time/clock.dart';
import 'package:focus/data/db/app_database.dart';
import 'package:focus/features/limits/data/limits_repository.dart';
import 'package:focus/features/limits/domain/usage_models.dart';
import 'package:focus/features/modes/domain/mode.dart';
import 'package:focus/features/partner/data/partner_repository.dart';
import 'package:focus/features/partner/domain/partner.dart';
import 'package:focus/features/partner/domain/totp.dart';
import 'package:focus/platform/usage_tracking_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/harness.dart';

final tempSecret = Uint8List.fromList(List<int>.generate(20, (i) => i + 1));
final removeSecret = Uint8List.fromList(List<int>.generate(20, (i) => 100 + i));
final otherSecret = Uint8List.fromList(List<int>.generate(20, (i) => 200 + i));

String codeFor(Uint8List secret, [DateTime? at]) => Totp.codeAt(secret, Totp.counterAt(at ?? noon));

FakeUsageTrackingService readyService() => modeService(FixedClock(noon))
  ..permissions[EnforcementPermission.accessibility] = PermissionState.granted
  ..permissions[EnforcementPermission.notifications] = PermissionState.granted;

Future<void> seedPartner(WidgetTester tester, AppDatabase db) async {
  await PartnerRepository(db).save(PartnerConfig(
    phone: '+919876543210',
    unlockWindow: const Duration(minutes: 15),
    temporarySecret: Totp.base32Encode(tempSecret),
    removeSecret: Totp.base32Encode(removeSecret),
  ));
  ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first)).invalidate(partnerProvider);
  await tester.pumpAndSettle();
}

ActiveMode youtubeBlock() => ActiveMode(
      id: 'quick-1',
      name: 'YouTube',
      packageNames: const ['com.yt'],
      endsAt: noon.add(const Duration(minutes: 30)),
    );

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  // Lazily built lists only create items once they are scrolled near the screen.
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  appTest('partner setup: number, then both authenticator entries are verified', (tester) async {
    final service = readyService();
    await pump(
      tester,
      onboarded: true,
      service: service,
      clock: FixedClock(noon),
      secrets: [tempSecret, removeSecret],
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock partner'));
    await tester.pumpAndSettle();
    expect(find.text('Choose someone you trust'), findsOneWidget);

    await tapVisible(tester, find.text('Continue'));
    expect(find.textContaining('country code'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '+91 98765 43210');
    await tapVisible(tester, find.widgetWithText(ChoiceChip, '10 min'));
    await tapVisible(tester, find.text('Continue'));

    expect(find.text('Partner scans "Temporary unlock"'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);

    // A code from some other authenticator entry is refused.
    await tester.enterText(find.byType(TextField), codeFor(otherSecret));
    await tapVisible(tester, find.text('Verify and continue'));
    expect(find.textContaining('doesn\'t match'), findsOneWidget);

    await tester.enterText(find.byType(TextField), codeFor(tempSecret));
    await tapVisible(tester, find.text('Verify and continue'));
    expect(find.text('Partner scans "Remove block"'), findsOneWidget);

    await tester.enterText(find.byType(TextField), codeFor(removeSecret));
    await tapVisible(tester, find.text('Verify and finish'));

    expect(find.text('•••• 3210'), findsOneWidget);
    expect(find.text('Change partner'), findsOneWidget);
    expect(service.partnerConfigured, isTrue);
  });

  appTest('a partner cannot be added while something is locked', (tester) async {
    final service = readyService()..active = [youtubeBlock()];
    await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock partner'));
    await tester.pumpAndSettle();
    expect(find.text('Not while something is locked'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  appTest('temporary code: ask by SMS, enter code, app opens for the break', (tester) async {
    final service = readyService()..active = [youtubeBlock()];
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await seedPartner(tester, db);

    await tester.tap(find.text('Ask partner'));
    await tester.pumpAndSettle();
    expect(find.text('Open YouTube'), findsOneWidget);

    await tester.tap(find.text('SMS'));
    await tester.pumpAndSettle();
    final sent = service.sentRequests.single;
    expect(sent.number, '+919876543210');
    expect(sent.whatsapp, isFalse);
    expect(sent.body, contains('YouTube'));
    expect(sent.body, contains('Temporary unlock'));

    await tester.enterText(find.byType(TextField), codeFor(tempSecret));
    await tapVisible(tester, find.text('Unlock'));
    expect(find.text('YouTube is open'), findsOneWidget);
    expect(service.grants.single.packageNames, ['com.yt']);
    expect(service.grants.single.endsAt, noon.add(const Duration(minutes: 15)));
    // The block itself keeps running; the break only overrides it for 15 minutes.
    expect(service.active, isNotEmpty);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('YouTube unlocked'), findsOneWidget);
    expect(find.text('00:15:00'), findsOneWidget);
  });

  appTest('remove code: the app\'s block and limit are removed', (tester) async {
    final service = readyService()
      ..active = [youtubeBlock()]
      ..sessions.add(UsageSession(
        appId: 'com.yt',
        start: DateTime(2026, 3, 10, 10),
        end: DateTime(2026, 3, 10, 11),
      ));
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await LimitsRepository(db)
        .upsert(LimitRule(appId: 'com.yt', label: 'YouTube', dailyLimit: const Duration(hours: 1)));
    await seedPartner(tester, db);

    await tester.tap(find.text('Limits'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Locked until'));
    await tester.pumpAndSettle();
    expect(find.text('Open YouTube'), findsOneWidget);

    await tester.enterText(find.byType(TextField), codeFor(removeSecret));
    await tapVisible(tester, find.text('Unlock'));
    expect(find.text('YouTube is unblocked'), findsOneWidget);
    expect(service.removedFromBlocks, ['com.yt']);
    expect(await db.select(db.limitRules).get(), isEmpty);
    expect(service.grants, isEmpty);
  });

  appTest('five wrong codes lock out further attempts', (tester) async {
    final service = readyService()..active = [youtubeBlock()];
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await seedPartner(tester, db);
    await tester.tap(find.text('Ask partner'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await tester.enterText(find.byType(TextField), codeFor(otherSecret));
      await tapVisible(tester, find.text('Unlock'));
      expect(find.textContaining('${4 - i} tries left'), findsOneWidget);
    }
    await tester.enterText(find.byType(TextField), codeFor(otherSecret));
    await tapVisible(tester, find.text('Unlock'));
    expect(find.textContaining('Too many tries. Try again at 12:10'), findsOneWidget);

    // Even the right code is refused during the lockout.
    await tester.enterText(find.byType(TextField), codeFor(tempSecret));
    await tapVisible(tester, find.text('Unlock'));
    expect(find.textContaining('Too many tries'), findsOneWidget);
    expect(service.grants, isEmpty);
  });

  appTest('changing the partner needs their Remove block code', (tester) async {
    final service = readyService();
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await seedPartner(tester, db);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock partner'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Change partner'));
    // The weaker "Temporary unlock" code is not enough.
    await tester.enterText(find.byType(TextField), codeFor(tempSecret));
    await tapVisible(tester, find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.textContaining('didn\'t work'), findsOneWidget);
    expect(await PartnerRepository(db).load(), isNotNull);

    await tester.enterText(find.byType(TextField), codeFor(removeSecret));
    await tapVisible(tester, find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Choose someone you trust'), findsOneWidget);
    expect(await PartnerRepository(db).load(), isNull);
    expect(service.partnerConfigured, isFalse);
  });

  appTest('deleting all data needs the partner\'s code', (tester) async {
    final service = readyService();
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await seedPartner(tester, db);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Delete all my data'));
    expect(find.text('Partner approval needed'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.nativeErased, isFalse);

    await tapVisible(tester, find.text('Delete all my data'));
    await tester.enterText(find.byType(TextField), codeFor(removeSecret));
    await tapVisible(tester, find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(service.nativeErased, isTrue);
    expect(find.text('Spend your time on purpose'), findsOneWidget);
  });

  appTest('"Ask partner to unlock" on the block screen opens the request', (tester) async {
    final service = readyService()..active = [youtubeBlock()];
    final db = await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    await seedPartner(tester, db);

    service.pendingUnlock = const InstalledApp(packageName: 'com.ig', label: 'Instagram');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Open Instagram'), findsOneWidget);
    expect(service.pendingUnlock, isNull);
  });

  appTest('without a partner, blocks cannot be unlocked early', (tester) async {
    final service = readyService()..active = [youtubeBlock()];
    await pump(tester, onboarded: true, service: service, clock: FixedClock(noon));
    expect(find.text('Ask partner'), findsNothing);

    service.pendingUnlock = const InstalledApp(packageName: 'com.yt', label: 'YouTube');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('No unlock partner'), findsOneWidget);
  });
}
