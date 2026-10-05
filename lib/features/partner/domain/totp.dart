import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Time-based one-time passwords (RFC 6238, HMAC-SHA1, 30 s, 6 digits) — the same
/// codes Google Authenticator and similar apps show, so the partner needs no
/// special app and no server is involved.
abstract final class Totp {
  static const period = 30;
  static const digits = 6;
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// A fresh 160-bit secret from a cryptographically secure source.
  static Uint8List newSecret([Random? random]) {
    final r = random ?? Random.secure();
    return Uint8List.fromList(List<int>.generate(20, (_) => r.nextInt(256)));
  }

  static String base32Encode(List<int> bytes) {
    final out = StringBuffer();
    var buffer = 0;
    var bits = 0;
    for (final b in bytes) {
      buffer = (buffer << 8) | (b & 0xff);
      bits += 8;
      while (bits >= 5) {
        out.write(_alphabet[(buffer >> (bits - 5)) & 31]);
        bits -= 5;
      }
      buffer &= (1 << bits) - 1;
    }
    if (bits > 0) out.write(_alphabet[(buffer << (5 - bits)) & 31]);
    return out.toString();
  }

  static Uint8List base32Decode(String input) {
    final clean = input.toUpperCase().replaceAll(RegExp(r'[\s=-]'), '');
    final out = <int>[];
    var buffer = 0;
    var bits = 0;
    for (final ch in clean.split('')) {
      final v = _alphabet.indexOf(ch);
      if (v < 0) throw FormatException('Invalid base32 character: $ch');
      buffer = (buffer << 5) | v;
      bits += 5;
      if (bits >= 8) {
        out.add((buffer >> (bits - 8)) & 0xff);
        bits -= 8;
        buffer &= (1 << bits) - 1;
      }
    }
    return Uint8List.fromList(out);
  }

  static int counterAt(DateTime t) => t.millisecondsSinceEpoch ~/ 1000 ~/ period;

  static String codeAt(List<int> secret, int counter, {int length = digits}) {
    final message = ByteData(8)..setInt64(0, counter);
    final hash = Hmac(sha1, secret).convert(message.buffer.asUint8List()).bytes;
    final offset = hash.last & 0x0f;
    final binary = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);
    return (binary % pow(10, length).toInt()).toString().padLeft(length, '0');
  }

  /// The time step [code] belongs to, or null if it is wrong. One step either side is
  /// accepted for clock drift, and steps at or before [lastUsed] are refused so a
  /// code can only ever be used once.
  static int? match(
    List<int> secret,
    String code,
    DateTime now, {
    int window = 1,
    int lastUsed = -1,
  }) {
    final c = code.replaceAll(RegExp(r'\s'), '');
    if (c.length != digits || int.tryParse(c) == null) return null;
    final current = counterAt(now);
    for (var i = -window; i <= window; i++) {
      final counter = current + i;
      if (counter <= lastUsed) continue;
      if (_equals(codeAt(secret, counter), c)) return counter;
    }
    return null;
  }

  /// The link an authenticator app reads from the setup QR code.
  static String otpauthUri({
    required String secretBase32,
    required String account,
    String issuer = 'Focus',
  }) =>
      'otpauth://totp/${Uri.encodeComponent('$issuer:$account')}'
      '?secret=$secretBase32&issuer=${Uri.encodeComponent(issuer)}'
      '&algorithm=SHA1&digits=$digits&period=$period';

  static bool _equals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
