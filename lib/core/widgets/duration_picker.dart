import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format/duration_format.dart';
import '../theme/app_theme.dart';

/// Picks a duration without typing: quick presets ordered small to big, plus two
/// scroll wheels (hours and minutes) for any exact value in between.
class DurationPicker extends StatefulWidget {
  const DurationPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.max,
    this.min = const Duration(minutes: 1),
    this.presets = const [],
  });

  final Duration value;
  final ValueChanged<Duration> onChanged;
  final Duration min;
  final Duration max;
  final List<Duration> presets;

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late Duration _value;
  late final FixedExtentScrollController _hours;
  late final FixedExtentScrollController _minutes;

  @override
  void initState() {
    super.initState();
    _value = _clamp(widget.value);
    _hours = FixedExtentScrollController(initialItem: _value.inHours);
    _minutes = FixedExtentScrollController(initialItem: _value.inMinutes % 60);
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Duration _clamp(Duration d) {
    final whole = Duration(minutes: d.inMinutes);
    if (whole < widget.min) return widget.min;
    if (whole > widget.max) return widget.max;
    return whole;
  }

  void _set(Duration next) {
    final clamped = _clamp(next);
    if (clamped == _value) {
      // The wheels may be showing a value that was clamped back; snap them to it.
      _snap();
      return;
    }
    setState(() => _value = clamped);
    widget.onChanged(clamped);
    _snap();
  }

  void _snap() {
    for (final (controller, item) in [
      (_hours, _value.inHours),
      (_minutes, _value.inMinutes % 60),
    ]) {
      if (controller.hasClients && controller.selectedItem != item) {
        controller.animateToItem(
          item,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presets = [
      for (final p in widget.presets)
        if (p >= widget.min && p <= widget.max) p,
    ]..sort();
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    final extent = 44.0 * scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(formatDuration(_value), style: theme.textTheme.headlineMedium),
        ),
        if (presets.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in presets)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(formatDuration(p)),
                      selected: _value == p,
                      onSelected: (_) => _set(p),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Or scroll to set an exact time',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Wheel(
              wheelKey: const Key('wheel-hours'),
              label: 'hours',
              controller: _hours,
              count: widget.max.inHours + 1,
              selected: _value.inHours,
              extent: extent,
              itemLabel: (i) => '$i',
              onSelected: (h) => _set(Duration(hours: h, minutes: _value.inMinutes % 60)),
            ),
            const SizedBox(width: AppSpacing.lg),
            _Wheel(
              wheelKey: const Key('wheel-minutes'),
              label: 'min',
              controller: _minutes,
              count: 60,
              selected: _value.inMinutes % 60,
              extent: extent,
              itemLabel: (i) => i.toString().padLeft(2, '0'),
              onSelected: (m) => _set(Duration(hours: _value.inHours, minutes: m)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.wheelKey,
    required this.label,
    required this.controller,
    required this.count,
    required this.selected,
    required this.extent,
    required this.itemLabel,
    required this.onSelected,
  });

  final Key wheelKey;
  final String label;
  final FixedExtentScrollController controller;
  final int count;
  final int selected;
  final double extent;
  final String Function(int) itemLabel;
  final ValueChanged<int> onSelected;

  void _nudge(int delta) {
    final next = (selected + delta).clamp(0, count - 1);
    controller.animateToItem(next, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: label,
      value: itemLabel(selected),
      increasedValue: itemLabel((selected + 1).clamp(0, count - 1)),
      decreasedValue: itemLabel((selected - 1).clamp(0, count - 1)),
      onIncrease: () => _nudge(1),
      onDecrease: () => _nudge(-1),
      child: ExcludeSemantics(
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            SizedBox(
              width: 88,
              height: extent * 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: extent,
                    decoration: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    key: wheelKey,
                    controller: controller,
                    itemExtent: extent,
                    diameterRatio: 1.9,
                    perspective: 0.004,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (i) {
                      HapticFeedback.selectionClick();
                      onSelected(i);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: count,
                      builder: (context, i) => Center(
                        child: Text(
                          itemLabel(i),
                          style: i == selected
                              ? theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSecondaryContainer,
                                )
                              : theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
