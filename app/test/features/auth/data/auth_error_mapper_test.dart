import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/auth/data/auth_error_mapper.dart';

void main() {
  group('mapAuthException', () {
    test('invalid_credentials → InvalidCredentialsFailure', () {
      final r = mapAuthException(
        AuthApiException('Invalid login credentials',
            code: 'invalid_credentials'),
      );
      expect(r, isA<InvalidCredentialsFailure>());
    });

    test('email_not_confirmed → EmailNotConfirmedFailure', () {
      final r = mapAuthException(
        AuthApiException('Email not confirmed', code: 'email_not_confirmed'),
      );
      expect(r, isA<EmailNotConfirmedFailure>());
    });

    test('user_already_exists → EmailAlreadyRegisteredFailure', () {
      final r = mapAuthException(
        AuthApiException('User already registered',
            code: 'user_already_exists'),
      );
      expect(r, isA<EmailAlreadyRegisteredFailure>());
    });

    test('weak_password → WeakPasswordFailure', () {
      final r = mapAuthException(
        AuthApiException('Password too short', code: 'weak_password'),
      );
      expect(r, isA<WeakPasswordFailure>());
    });

    test('over_email_send_rate_limit → RateLimitFailure', () {
      final r = mapAuthException(
        AuthApiException('Too many requests',
            code: 'over_email_send_rate_limit'),
      );
      expect(r, isA<RateLimitFailure>());
    });

    test('SocketException → NetworkFailure', () {
      final r = mapAuthException(const SocketException('no route'));
      expect(r, isA<NetworkFailure>());
    });

    test('неизвестный код → UnknownAuthFailure', () {
      final r = mapAuthException(
        AuthApiException('boom', code: 'something_else'),
      );
      expect(r, isA<UnknownAuthFailure>());
    });
  });
}
