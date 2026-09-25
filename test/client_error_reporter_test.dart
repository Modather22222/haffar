import 'package:flutter_test/flutter_test.dart';
import 'package:haffar/utils/client_error_reporter.dart';

void main() {
  group('ClientErrorReporter.scrub', () {
    test('redacts email addresses', () {
      const input = 'login failed for amir@example.com and a.b+tag@x.co';
      final out = ClientErrorReporter.scrub(input);
      expect(out, isNot(contains('amir@example.com')));
      expect(out, isNot(contains('a.b+tag@x.co')));
      expect(out, contains('[email]'));
    });

    test('redacts Supabase keys and JWTs', () {
      const input =
          'POST /rest/v1 with sbp_abcdefghijklmnopqrstuvwxyz012345 '
          'and eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIn0.signature1';
      final out = ClientErrorReporter.scrub(input);
      expect(out, isNot(contains('sbp_')));
      expect(out, isNot(contains('eyJhbGci')));
      expect(out, contains('[secret]'));
    });

    test('redacts bearer tokens regardless of case', () {
      expect(
        ClientErrorReporter.scrub('Bearer abc.def-123'),
        contains('[redacted]'),
      );
      expect(
        ClientErrorReporter.scrub('bearer abc.def-123'),
        contains('[redacted]'),
      );
      expect(
        ClientErrorReporter.scrub('BEARER abc123'),
        contains('[redacted]'),
      );
    });

    test('strips query strings but keeps the path', () {
      const input =
          'https://api.example.com/v1/users?token=abc123&email=a@b.com';
      final out = ClientErrorReporter.scrub(input);
      expect(out, contains('/v1/users?'));
      expect(out, isNot(contains('token=abc123')));
      expect(out, isNot(contains('email=a@b.com')));
    });

    test('redacts long digit runs (ids, phone numbers)', () {
      final out = ClientErrorReporter.scrub('call 0123456789 or 987654321');
      expect(out, isNot(contains('0123456789')));
      expect(out, isNot(contains('987654321')));
      expect(out, contains('[num]'));
    });

    test('keeps stack line:col numbers intact', () {
      const input = 'at foo (package:haffar/main.dart:42:13)';
      expect(ClientErrorReporter.scrub(input), input);
    });

    test('leaves plain messages untouched', () {
      const input = 'Null check operator used on a null value';
      expect(ClientErrorReporter.scrub(input), input);
    });
  });

  group('ClientErrorReporter.fingerprintOf', () {
    test('is 16 lowercase hex chars', () {
      final fp = ClientErrorReporter.fingerprintOf('Boom', '#0 main.dart:1');
      expect(fp, matches(RegExp(r'^[0-9a-f]{16}$')));
    });

    test('same message + frame → same fingerprint', () {
      final a = ClientErrorReporter.fingerprintOf(
        'StateError: boom\nextra',
        '#0 foo (package:x/y.dart:10:5)\n#1',
      );
      final b = ClientErrorReporter.fingerprintOf(
        'StateError: boom',
        '#0 foo (package:x/y.dart:99:7)\n#2',
      );
      expect(a, b);
    });

    test('digit differences in the message collapse to one group', () {
      final a = ClientErrorReporter.fingerprintOf(
        'HTTP 500 from /users/12',
        '',
      );
      final b = ClientErrorReporter.fingerprintOf(
        'HTTP 500 from /users/99',
        '',
      );
      expect(a, b);
    });

    test('different messages → different fingerprints', () {
      final a = ClientErrorReporter.fingerprintOf('Boom', '');
      final b = ClientErrorReporter.fingerprintOf('Fizzle', '');
      expect(a, isNot(b));
    });

    test('different first frames → different fingerprints', () {
      final a = ClientErrorReporter.fingerprintOf(
        'Boom',
        '#0 foo (package:x/a.dart:1:1)',
      );
      final b = ClientErrorReporter.fingerprintOf(
        'Boom',
        '#0 bar (package:x/b.dart:2:2)',
      );
      expect(a, isNot(b));
    });

    test('missing stack still produces a stable hash', () {
      final a = ClientErrorReporter.fingerprintOf('Boom', null);
      final b = ClientErrorReporter.fingerprintOf('Boom', '');
      expect(a, b);
      expect(a, matches(RegExp(r'^[0-9a-f]{16}$')));
    });
  });
}
