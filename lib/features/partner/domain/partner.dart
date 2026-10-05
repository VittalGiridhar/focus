import 'package:equatable/equatable.dart';

import 'totp.dart';

/// What the partner's code allows.
enum UnlockKind {
  /// From the partner's "Temporary unlock" entry: a short break, then the block resumes.
  temporary,

  /// From the partner's "Remove block" entry: the app's restrictions are removed.
  /// The same code also authorises changing the partner or deleting data.
  remove,
}

class PartnerConfig extends Equatable {
  const PartnerConfig({
    required this.phone,
    required this.unlockWindow,
    required this.temporarySecret,
    required this.removeSecret,
    this.lastTemporaryCounter = -1,
    this.lastRemoveCounter = -1,
    this.failedAttempts = 0,
    this.lockedOutUntil,
  });

  static const windows = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
  ];

  final String phone;
  final Duration unlockWindow;

  /// Base32 secrets; they are shown once during setup and never again.
  final String temporarySecret;
  final String removeSecret;
  final int lastTemporaryCounter;
  final int lastRemoveCounter;
  final int failedAttempts;
  final DateTime? lockedOutUntil;

  String get maskedPhone {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final tail = digits.length <= 4 ? digits : digits.substring(digits.length - 4);
    return '•••• $tail';
  }

  /// Digits with an optional leading "+", 8-15 digits long; null if not a phone number.
  static String? normalizePhone(String input) {
    final trimmed = input.trim().replaceAll(RegExp(r'[\s\-().]'), '');
    if (!RegExp(r'^\+?\d{8,15}$').hasMatch(trimmed)) return null;
    return trimmed;
  }

  PartnerConfig copyWith({
    int? lastTemporaryCounter,
    int? lastRemoveCounter,
    int? failedAttempts,
    DateTime? lockedOutUntil,
    bool clearLockout = false,
  }) =>
      PartnerConfig(
        phone: phone,
        unlockWindow: unlockWindow,
        temporarySecret: temporarySecret,
        removeSecret: removeSecret,
        lastTemporaryCounter: lastTemporaryCounter ?? this.lastTemporaryCounter,
        lastRemoveCounter: lastRemoveCounter ?? this.lastRemoveCounter,
        failedAttempts: failedAttempts ?? this.failedAttempts,
        lockedOutUntil: clearLockout ? null : (lockedOutUntil ?? this.lockedOutUntil),
      );

  @override
  List<Object?> get props => [
        phone,
        unlockWindow,
        temporarySecret,
        removeSecret,
        lastTemporaryCounter,
        lastRemoveCounter,
        failedAttempts,
        lockedOutUntil,
      ];
}

class VerifyOutcome {
  const VerifyOutcome({required this.config, this.kind, this.lockedOutUntil});

  /// What the code unlocks, or null when it was wrong or attempts are locked out.
  final UnlockKind? kind;

  /// The config with updated counters and attempt tracking; always save it.
  final PartnerConfig config;
  final DateTime? lockedOutUntil;

  bool get ok => kind != null;

  int get attemptsLeft => PartnerVerifier.maxAttempts - config.failedAttempts;
}

class PartnerVerifier {
  const PartnerVerifier();

  static const maxAttempts = 5;
  static const lockout = Duration(minutes: 10);

  /// Checks [code] against the partner's codes. With [removeOnly] only the stronger
  /// "Remove block" code is accepted (used for changing the partner or deleting data).
  VerifyOutcome verify(PartnerConfig c, String code, DateTime now, {bool removeOnly = false}) {
    final lockedOut = c.lockedOutUntil;
    if (lockedOut != null && now.isBefore(lockedOut)) {
      return VerifyOutcome(config: c, lockedOutUntil: lockedOut);
    }

    final removeCounter = Totp.match(
      Totp.base32Decode(c.removeSecret),
      code,
      now,
      lastUsed: c.lastRemoveCounter,
    );
    if (removeCounter != null) {
      return VerifyOutcome(
        kind: UnlockKind.remove,
        config: c.copyWith(lastRemoveCounter: removeCounter, failedAttempts: 0, clearLockout: true),
      );
    }

    if (!removeOnly) {
      final tempCounter = Totp.match(
        Totp.base32Decode(c.temporarySecret),
        code,
        now,
        lastUsed: c.lastTemporaryCounter,
      );
      if (tempCounter != null) {
        return VerifyOutcome(
          kind: UnlockKind.temporary,
          config: c.copyWith(lastTemporaryCounter: tempCounter, failedAttempts: 0, clearLockout: true),
        );
      }
    }

    final failures = c.failedAttempts + 1;
    if (failures >= maxAttempts) {
      final until = now.add(lockout);
      return VerifyOutcome(
        config: c.copyWith(failedAttempts: 0, lockedOutUntil: until),
        lockedOutUntil: until,
      );
    }
    return VerifyOutcome(config: c.copyWith(failedAttempts: failures, clearLockout: true));
  }
}
