import 'dart:typed_data';

import 'package:ticket_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:ticket_app/features/profile/domain/entities/profile.dart';
import 'package:ticket_app/features/profile/domain/repositories/profile_repository.dart';

/// Профиль для тестов.
Profile makeProfile({
  String id = 'u1',
  String countryCode = 'RU',
  String? displayName = 'Аня',
  String? avatarUrl,
}) =>
    Profile(
      id: id,
      countryCode: countryCode,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );

/// Фейк datasource: хранит профиль в памяти, опционально кидает [error].
class FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  FakeProfileRemoteDataSource(this.profile);
  Profile profile;
  Object? error;

  @override
  Future<Profile> fetchCurrent() async {
    if (error != null) throw error!;
    return profile;
  }

  @override
  Future<Profile> updateName(String displayName) async {
    if (error != null) throw error!;
    profile = profile.copyWith(displayName: displayName);
    return profile;
  }

  @override
  Future<Profile> setCountry(String countryCode) async {
    if (error != null) throw error!;
    profile = profile.copyWith(countryCode: countryCode);
    return profile;
  }

  @override
  Future<Profile> uploadAvatar(Uint8List bytes) async {
    if (error != null) throw error!;
    profile = profile.copyWith(avatarUrl: 'https://x/a.jpg?v=1');
    return profile;
  }

  @override
  Future<Profile> removeAvatar() async {
    if (error != null) throw error!;
    profile = profile.copyWith(clearAvatar: true);
    return profile;
  }
}

/// Фейк репозитория для тестов контроллеров.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.profile);
  Profile profile;
  Object? error;

  @override
  Future<Profile> getCurrent() async {
    if (error != null) throw error!;
    return profile;
  }

  @override
  Future<Profile> updateName(String displayName) async {
    if (error != null) throw error!;
    profile = profile.copyWith(displayName: displayName);
    return profile;
  }

  @override
  Future<Profile> setCountry(String countryCode) async {
    if (error != null) throw error!;
    profile = profile.copyWith(countryCode: countryCode);
    return profile;
  }

  @override
  Future<Profile> updateAvatar(Uint8List bytes) async {
    if (error != null) throw error!;
    profile = profile.copyWith(avatarUrl: 'https://x/a.jpg?v=1');
    return profile;
  }

  @override
  Future<Profile> removeAvatar() async {
    if (error != null) throw error!;
    profile = profile.copyWith(clearAvatar: true);
    return profile;
  }
}
