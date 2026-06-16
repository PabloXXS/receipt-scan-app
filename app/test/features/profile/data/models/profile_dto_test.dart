import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/profile/data/models/profile_dto.dart';

void main() {
  test('profileFromRow маппит все поля', () {
    final p = profileFromRow({
      'id': 'u1',
      'country_code': 'BY',
      'display_name': 'Аня',
      'avatar_url': 'https://x/a.jpg',
      'family_id': 'f1',
    });
    expect(p.id, 'u1');
    expect(p.countryCode, 'BY');
    expect(p.displayName, 'Аня');
    expect(p.avatarUrl, 'https://x/a.jpg');
    expect(p.familyId, 'f1');
  });

  test('profileFromRow допускает null-поля', () {
    final p = profileFromRow({'id': 'u1', 'country_code': 'RU'});
    expect(p.displayName, isNull);
    expect(p.avatarUrl, isNull);
    expect(p.familyId, isNull);
  });
}
