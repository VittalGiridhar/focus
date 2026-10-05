import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus/features/partner/domain/partner.dart';
import 'package:focus/features/partner/domain/totp.dart';

void main() {
  final rfcSecret = utf8.encode('12345678901234567890');

  group('TOTP (RFC 6238 SHA-1 test vectors)', () {
    // 8-digit values from the RFC; the 6-digit code is the last six digits.
    const vectors = {
      59: '94287082',
      1111111109: '07081804',
      1111111111: '14050471',
      1234567890: '89005924',
      2000000000: '69279037',
      20000000000: '65353130',
    };

    vectors.forEach((seconds, expected) {
      test('t=$seconds', () {
        final counter = seconds ~/ Totp.period;
        expect(Totp.codeAt(rfcSecret, counter, length: 8), expected);
        expect(Totp.codeAt(rfcSecret, counter), expected.substring(2));
      });
    });

    test('base32 matches the RFC secret and round-trips', () {
      expect(Totp.base32Encode(rfcSecret), 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ');
      expect(Totp.base32Decode('gezd gnbv gy3t qojq gezd gnbv gy3t qojq'), rfcSecret);
      final random = Totp.newSecret();
      expect(random.length, 20);
      expect(Totp.base32Decode(Totp.base32Encode(random)), random);
    });

    test('invalid base32 is rejected', () {
      expect(() => Totp.base32Decode('ABC1'), throwsFormatException);
    });
  });

  group('matching', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1111111111 * 1000);
    final counter = Totp.counterAt(now);

    test('accepts the current code and one step either side', () {
      expect(Totp.match(rfcSecret, Totp.codeAt(rfcSecret, counter), now), counter);
      expect(Totp.match(rfcSecret, Totp.codeAt(rfcSecret, counter - 1), now), counter - 1);
      expect(Totp.match(rfcSecret, Totp.codeAt(rfcSecret, counter + 1), now), counter + 1);
    });

    test('rejects older codes, wrong codes and malformed input', () {
      expect(Totp.match(rfcSecret, Totp.codeAt(rfcSecret, counter - 2), now), isNull);
      expect(Totp.match(rfcSecret, '000000', now), isNull);
      expect(Totp.match(rfcSecret, '12345', now), isNull);
      expect(Totp.match(rfcSecret, 'abcdef', now), isNull);
    });

    test('a code cannot be used twice', () {
      final code = Totp.codeAt(rfcSecret, counter);
      expect(Totp.match(rfcSecret, code, now, lastUsed: counter), isNull);
    });

    test('spaces typed in the middle are ignored', () {
      final code = Totp.codeAt(rfcSecret, counter);
      expect(Totp.match(rfcSecret, '${code.substring(0, 3)} ${code.substring(3)}', now), counter);
    });

    test('authenticator link', () {
      final uri = Totp.otpauthUri(secretBase32: 'ABC', account: 'Temporary unlock');
      expect(uri, startsWith('otpauth://totp/Focus%3ATemporary%20unlock?secret=ABC'));
      expect(uri, contains('digits=6'));
      expect(uri, contains('period=30'));
    });
  });

  group('partner verifier', () {
    final now = DateTime(2026, 3, 10, 12);
    final tempSecret = Totp.newSecret();
    final removeSecret = Totp.newSecret();
    final config = PartnerConfig(
      phone: '+919876543210',
      unlockWindow: const Duration(minutes: 15),
      temporarySecret: Totp.base32Encode(tempSecret),
      removeSecret: Totp.base32Encode(removeSecret),
    );
    const verifier = PartnerVerifier();
    String code(List<int> s) => Totp.codeAt(s, Totp.counterAt(now));

    test('the temporary code grants a break', () {
      final out = verifier.verify(config, code(tempSecret), now);
      expect(out.kind, UnlockKind.temporary);
      expect(out.config.lastTemporaryCounter, Totp.counterAt(now));
    });

    test('the remove code removes the block', () {
      expect(verifier.verify(config, code(removeSecret), now).kind, UnlockKind.remove);
    });

    test('only the remove code works for protected actions', () {
      expect(verifier.verify(config, code(tempSecret), now, removeOnly: true).ok, isFalse);
      expect(verifier.verify(config, code(removeSecret), now, removeOnly: true).kind, UnlockKind.remove);
    });

    test('a used code cannot be replayed', () {
      final first = verifier.verify(config, code(tempSecret), now);
      expect(verifier.verify(first.config, code(tempSecret), now).ok, isFalse);
    });

    test('five wrong codes lock out attempts for ten minutes', () {
      var c = config;
      VerifyOutcome? out;
      for (var i = 0; i < 4; i++) {
        out = verifier.verify(c, '000000', now);
        c = out.config;
        expect(out.lockedOutUntil, isNull);
        expect(out.attemptsLeft, PartnerVerifier.maxAttempts - (i + 1));
      }
      out = verifier.verify(c, '000000', now);
      expect(out.lockedOutUntil, now.add(PartnerVerifier.lockout));
      c = out.config;

      // Even the right code is refused during the lockout...
      final during = verifier.verify(c, code(tempSecret), now.add(const Duration(minutes: 5)));
      expect(during.ok, isFalse);
      expect(during.lockedOutUntil, isNotNull);

      // ...and accepted afterwards.
      final later = now.add(const Duration(minutes: 11));
      final after = verifier.verify(c, Totp.codeAt(tempSecret, Totp.counterAt(later)), later);
      expect(after.kind, UnlockKind.temporary);
      expect(after.config.lockedOutUntil, isNull);
    });

    test('phone numbers are normalised and validated', () {
      expect(PartnerConfig.normalizePhone('+91 98765-43210'), '+919876543210');
      expect(PartnerConfig.normalizePhone('(098) 7654 3210'), '09876543210');
      expect(PartnerConfig.normalizePhone('12345'), isNull);
      expect(PartnerConfig.normalizePhone('call me'), isNull);
      expect(config.maskedPhone, '•••• 3210');
    });
  });
}
