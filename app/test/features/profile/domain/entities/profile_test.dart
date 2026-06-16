import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/profile/domain/entities/profile.dart';

void main() {
  const base = Profile(id: 'u1', countryCode: 'RU', displayName: 'Аня');

  test('copyWith меняет только переданные поля', () {
    final next = base.copyWith(displayName: 'Боря');
    expect(next.id, 'u1');
    expect(next.countryCode, 'RU');
    expect(next.displayName, 'Боря');
    expect(next.avatarUrl, isNull);
  });

  test('copyWith с clearAvatar сбрасывает avatarUrl', () {
    const withAvatar = Profile(
      id: 'u1',
      countryCode: 'RU',
      avatarUrl: 'https://x/a.jpg',
    );
    final next = withAvatar.copyWith(clearAvatar: true);
    expect(next.avatarUrl, isNull);
  });
}
