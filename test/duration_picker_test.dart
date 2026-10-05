import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/widgets/duration_picker.dart';

void main() {
  Future<List<Duration>> pumpPicker(
    WidgetTester tester, {
    Duration value = const Duration(minutes: 30),
    Duration min = const Duration(minutes: 1),
    Duration max = const Duration(hours: 12),
    List<Duration> presets = const [
      Duration(minutes: 10),
      Duration(hours: 1),
      Duration(hours: 4),
    ],
    double textScale = 1.0,
  }) async {
    final changes = <Duration>[];
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DurationPicker(
            value: value,
            min: min,
            max: max,
            presets: presets,
            onChanged: changes.add,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return changes;
  }

  testWidgets('shows the start value and offers no text input', (tester) async {
    await pumpPicker(tester);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('presets run from small to big and set the value', (tester) async {
    final changes = await pumpPicker(tester);
    final labels = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .map((c) => (c.label as Text).data)
        .toList();
    expect(labels, ['10 min', '1 hour', '4 hours']);

    await tester.tap(find.widgetWithText(ChoiceChip, '1 hour'));
    await tester.pumpAndSettle();
    expect(changes.last, const Duration(hours: 1));
    expect(find.text('1 hour'), findsWidgets);
  });

  testWidgets('scrolling the hours wheel changes the value', (tester) async {
    final changes = await pumpPicker(tester);
    await tester.drag(find.byKey(const Key('wheel-hours')), const Offset(0, -88));
    await tester.pumpAndSettle();
    expect(changes.last, const Duration(hours: 2, minutes: 30));
    expect(find.text('2h 30m'), findsOneWidget);
  });

  testWidgets('scrolling the minutes wheel changes the value', (tester) async {
    final changes = await pumpPicker(tester);
    await tester.drag(find.byKey(const Key('wheel-minutes')), const Offset(0, 44 * 5));
    await tester.pumpAndSettle();
    expect(changes.last, const Duration(minutes: 25));
  });

  testWidgets('the wheels follow a preset', (tester) async {
    await pumpPicker(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '4 hours'));
    await tester.pumpAndSettle();
    // Scrolling one minute from there proves the wheels moved to 4h 00m.
    await tester.drag(find.byKey(const Key('wheel-minutes')), const Offset(0, -44));
    await tester.pumpAndSettle();
    expect(find.text('4h 1m'), findsOneWidget);
  });

  testWidgets('cannot go above the maximum; the wheel snaps back', (tester) async {
    final changes = await pumpPicker(
      tester,
      value: const Duration(hours: 2),
      max: const Duration(hours: 2),
      presets: const [Duration(hours: 1), Duration(hours: 2), Duration(hours: 4)],
    );
    expect(find.widgetWithText(ChoiceChip, '4 hours'), findsNothing); // out of range
    await tester.drag(find.byKey(const Key('wheel-minutes')), const Offset(0, -44 * 3));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(find.text('2 hours'), findsWidgets);
    // Hours wheel cannot go past the maximum either.
    await tester.drag(find.byKey(const Key('wheel-hours')), const Offset(0, -44 * 4));
    await tester.pumpAndSettle();
    expect(changes.where((d) => d > const Duration(hours: 2)), isEmpty);
  });

  testWidgets('cannot go below the minimum; zero snaps to one minute', (tester) async {
    final changes = await pumpPicker(tester, value: const Duration(minutes: 3));
    await tester.drag(find.byKey(const Key('wheel-minutes')), const Offset(0, 44 * 5));
    await tester.pumpAndSettle();
    expect(changes.every((d) => d >= const Duration(minutes: 1)), isTrue);
    expect(find.text('1 min'), findsWidgets);
  });

  testWidgets('screen readers can adjust each wheel', (tester) async {
    final handle = tester.ensureSemantics();
    final changes = await pumpPicker(tester);
    final hours = find.semantics.byLabel('hours');
    expect(hours, findsOneWidget);
    tester.semantics.performAction(hours, SemanticsAction.increase);
    await tester.pumpAndSettle();
    expect(changes.last, const Duration(hours: 1, minutes: 30));
    handle.dispose();
  });

  testWidgets('fits a small phone with large text', (tester) async {
    await pumpPicker(tester, textScale: 2.0);
    expect(tester.takeException(), isNull);
  });
}
