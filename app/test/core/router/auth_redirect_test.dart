import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/router/app_routes.dart';
import 'package:ticket_app/core/router/auth_redirect.dart';

void main() {
  group('authRedirect', () {
    test('неавторизованный на приватном маршруте → на вход', () {
      expect(
        authRedirect(isAuthenticated: false, location: AppRoutes.receipts),
        AppRoutes.signIn,
      );
    });

    test('неавторизованный на home → на вход', () {
      expect(
        authRedirect(isAuthenticated: false, location: AppRoutes.home),
        AppRoutes.signIn,
      );
    });

    test('неавторизованный на публичном маршруте → без редиректа', () {
      expect(
        authRedirect(isAuthenticated: false, location: AppRoutes.signUp),
        isNull,
      );
    });

    test('авторизованный на экране входа → на чеки', () {
      expect(
        authRedirect(isAuthenticated: true, location: AppRoutes.signIn),
        AppRoutes.receipts,
      );
    });

    test('авторизованный на home → на чеки', () {
      expect(
        authRedirect(isAuthenticated: true, location: AppRoutes.home),
        AppRoutes.receipts,
      );
    });

    test('авторизованный на вкладке → без редиректа', () {
      expect(
        authRedirect(isAuthenticated: true, location: AppRoutes.statistics),
        isNull,
      );
    });

    test('авторизованный (recovery) на reset-password → без редиректа', () {
      expect(
        authRedirect(isAuthenticated: true, location: AppRoutes.resetPassword),
        isNull,
      );
    });
  });
}
