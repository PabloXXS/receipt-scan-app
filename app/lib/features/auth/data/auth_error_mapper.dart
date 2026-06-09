/// Назначение: перевод исключений Supabase/сети в доменные AuthFailure.
///
/// Слой: data
/// Фича: auth
/// Зависимости: supabase_flutter (AuthException), core/error/failure.dart.
/// Ключевые типы: mapAuthException.
library;

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';

/// Преобразует [error] (исключение Supabase/сети) в [AuthFailure].
AuthFailure mapAuthException(Object error) {
  if (error is SocketException) {
    return const NetworkFailure();
  }
  if (error is AuthException) {
    final code = error is AuthApiException ? error.code : null;
    switch (code) {
      case 'invalid_credentials':
        return const InvalidCredentialsFailure();
      case 'email_not_confirmed':
        return const EmailNotConfirmedFailure();
      case 'user_already_exists':
      case 'email_exists':
        return const EmailAlreadyRegisteredFailure();
      case 'weak_password':
        return const WeakPasswordFailure();
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return const RateLimitFailure();
    }
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login')) return const InvalidCredentialsFailure();
    if (msg.contains('already registered')) {
      return const EmailAlreadyRegisteredFailure();
    }
    return const UnknownAuthFailure();
  }
  return const UnknownAuthFailure();
}
