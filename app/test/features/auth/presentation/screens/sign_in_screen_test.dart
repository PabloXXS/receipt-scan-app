import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ticket_app/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:ticket_app/shared/components/app_button.dart';
import 'package:ticket_app/shared/components/app_text_field.dart';

import '../../../../helpers/pump_app.dart';
import '../../auth_test_fakes.dart';

void main() {
  testWidgets('SignInScreen рендерит поля и кнопку входа', (tester) async {
    await pumpApp(
      tester,
      const SignInScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    expect(find.byType(AppTextField), findsNWidgets(2)); // email + пароль
    expect(find.byType(AppButton), findsWidgets);
    expect(find.text('Войти'), findsOneWidget);
  });
}
