import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ticket_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:ticket_app/shared/components/app_button.dart';

import '../../../../helpers/pump_app.dart';
import '../../../auth/auth_test_fakes.dart';

void main() {
  testWidgets('ProfileScreen: заголовок и кнопка «Выйти»', (tester) async {
    await pumpApp(
      tester,
      const ProfileScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository())
      ],
    );
    expect(find.text('Профиль'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Выйти'), findsOneWidget);
  });

  testWidgets('ProfileScreen: тап «Выйти» вызывает signOut', (tester) async {
    final repo = FakeAuthRepository();
    await pumpApp(
      tester,
      const ProfileScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.tap(find.widgetWithText(AppButton, 'Выйти'));
    await tester.pump();
    expect(repo.calls, contains('signOut'));
  });
}
