import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ticket_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:ticket_app/features/auth/presentation/widgets/country_field.dart';
import 'package:ticket_app/shared/components/app_text_field.dart';

import '../../../../helpers/pump_app.dart';
import '../../auth_test_fakes.dart';

void main() {
  testWidgets('SignUpScreen рендерит поля, страну и кнопку', (tester) async {
    await pumpApp(
      tester,
      const SignUpScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    expect(find.byType(AppTextField), findsNWidgets(2)); // email + пароль
    expect(find.byType(CountryField), findsOneWidget);
    expect(find.text('Зарегистрироваться'), findsOneWidget);
  });
}
