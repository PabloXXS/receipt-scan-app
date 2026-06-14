import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:ticket_app/features/profile/presentation/controllers/profile_controller.dart';

import '../../profile_test_fakes.dart';

ProviderContainer makeContainer(FakeProfileRepository repo) =>
    ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );

void main() {
  test('build грузит профиль', () async {
    final c = makeContainer(FakeProfileRepository(makeProfile()));
    final p = await c.read(profileControllerProvider.future);
    expect(p.displayName, 'Аня');
  });

  test('updateName обновляет состояние', () async {
    final repo = FakeProfileRepository(makeProfile());
    final c = makeContainer(repo);
    await c.read(profileControllerProvider.future);
    await c.read(profileControllerProvider.notifier).updateName('Боря');
    final p = c.read(profileControllerProvider).requireValue;
    expect(p.displayName, 'Боря');
  });

  test('setCountry обновляет страну', () async {
    final repo = FakeProfileRepository(makeProfile());
    final c = makeContainer(repo);
    await c.read(profileControllerProvider.future);
    await c.read(profileControllerProvider.notifier).setCountry('BY');
    expect(c.read(profileControllerProvider).requireValue.countryCode, 'BY');
  });

  test('removeAvatar сбрасывает аватар', () async {
    final repo =
        FakeProfileRepository(makeProfile(avatarUrl: 'https://x/a.jpg'));
    final c = makeContainer(repo);
    await c.read(profileControllerProvider.future);
    await c.read(profileControllerProvider.notifier).removeAvatar();
    expect(c.read(profileControllerProvider).requireValue.avatarUrl, isNull);
  });

  test('updateAvatar задаёт avatar_url', () async {
    final repo = FakeProfileRepository(makeProfile());
    final c = makeContainer(repo);
    await c.read(profileControllerProvider.future);
    await c.read(profileControllerProvider.notifier).updateAvatar(Uint8List(0));
    expect(c.read(profileControllerProvider).requireValue.avatarUrl, isNotNull);
  });
}
