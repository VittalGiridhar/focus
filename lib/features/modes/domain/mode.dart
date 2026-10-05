import 'package:equatable/equatable.dart';

class ModeApp extends Equatable {
  const ModeApp({required this.packageName, required this.label});

  final String packageName;
  final String label;

  @override
  List<Object?> get props => [packageName, label];
}

class FocusMode extends Equatable {
  const FocusMode({
    required this.id,
    required this.name,
    required this.duration,
    required this.createdAt,
    this.apps = const [],
  });

  final String id;
  final String name;
  final Duration duration;
  final DateTime createdAt;
  final List<ModeApp> apps;

  FocusMode copyWith({String? name, Duration? duration, List<ModeApp>? apps}) => FocusMode(
        id: id,
        name: name ?? this.name,
        duration: duration ?? this.duration,
        createdAt: createdAt,
        apps: apps ?? this.apps,
      );

  @override
  List<Object?> get props => [id, name, duration, createdAt, apps];
}

/// A block that is currently running (a saved mode or a quick block), as
/// reported by the native layer.
class ActiveMode extends Equatable {
  const ActiveMode({
    required this.id,
    required this.name,
    required this.packageNames,
    required this.endsAt,
  });

  static const quickPrefix = 'quick-';

  /// A mode's own id, or `quick-<timestamp>` for a one-off block.
  final String id;
  final String name;
  final List<String> packageNames;
  final DateTime endsAt;

  bool get isQuick => id.startsWith(quickPrefix);

  Duration remaining(DateTime now) {
    final d = endsAt.difference(now);
    return d.isNegative ? Duration.zero : d;
  }

  @override
  List<Object?> get props => [id, name, packageNames, endsAt];
}
