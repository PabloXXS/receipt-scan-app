/// Назначение: widget-тесты экрана «Настройки».
///
/// Слой: test/presentation
/// Фича: profile
/// Зависимости: flutter_test, flutter_riverpod, shared_preferences,
///   core/storage/preferences_providers.dart, core/auth/auth_providers.dart,
///   features/auth/data/repositories/auth_repository_impl.dart,
///   features/profile/data/repositories/profile_repository_impl.dart,
///   features/profile/presentation/screens/settings_screen.dart.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_app/core/auth/auth_providers.dart';
import 'package:ticket_app/core/storage/preferences_providers.dart';
import 'package:ticket_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ticket_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:ticket_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:ticket_app/shared/components/app_button.dart';

import '../../../../helpers/pump_app.dart';
import '../../../auth/auth_test_fakes.dart';
import '../../profile_test_fakes.dart';

/// Строит ProviderScope-overrides: prefs (тема), profileRepo, authRepo, email.
Future<List<Override>> _makeOverrides() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    profileRepositoryProvider
        .overrideWithValue(FakeProfileRepository(makeProfile())),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    currentUserEmailProvider.overrideWithValue('test@example.com'),
  ];
}

void main() {
  testWidgets('SettingsScreen: заголовок «Настройки»', (tester) async {
    final overrides = await _makeOverrides();
    await pumpApp(tester, const SettingsScreen(), overrides: overrides);
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);
  });

  testWidgets('SettingsScreen: кнопка «Выйти» присутствует', (tester) async {
    final overrides = await _makeOverrides();
    await pumpApp(tester, const SettingsScreen(), overrides: overrides);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppButton, 'Выйти'), findsOneWidget);
  });

  testWidgets('SettingsScreen: тап «Выйти» вызывает signOut', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final authRepo = FakeAuthRepository();
    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        profileRepositoryProvider
            .overrideWithValue(FakeProfileRepository(makeProfile())),
        authRepositoryProvider.overrideWithValue(authRepo),
        currentUserEmailProvider.overrideWithValue('test@example.com'),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppButton, 'Выйти'));
    await tester.pump();
    expect(authRepo.calls, contains('signOut'));
  });
}
