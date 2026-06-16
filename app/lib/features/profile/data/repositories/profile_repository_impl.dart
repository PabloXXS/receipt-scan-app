/// Назначение: реализация ProfileRepository поверх remote datasource.
///
/// Слой: data
/// Фича: profile
/// Зависимости: dart:typed_data, flutter_riverpod,
///   datasources/profile_remote_datasource.dart, profile_error_mapper.dart,
///   domain/repositories/profile_repository.dart.
/// Ключевые типы: ProfileRepositoryImpl, profileRepositoryProvider.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../profile_error_mapper.dart';

/// Делегирует datasource, оборачивает исключения в ProfileFailure.
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._ds);

  final ProfileRemoteDataSource _ds;

  @override
  Future<Profile> getCurrent() async {
    try {
      return await _ds.fetchCurrent();
    } catch (e) {
      throw mapProfileException(e);
    }
  }

  @override
  Future<Profile> updateName(String displayName) async {
    try {
      return await _ds.updateName(displayName);
    } catch (e) {
      throw mapProfileException(e);
    }
  }

  @override
  Future<Profile> setCountry(String countryCode) async {
    try {
      return await _ds.setCountry(countryCode);
    } catch (e) {
      throw mapProfileException(e);
    }
  }

  @override
  Future<Profile> updateAvatar(Uint8List bytes) async {
    try {
      return await _ds.uploadAvatar(bytes);
    } catch (e) {
      throw mapProfileException(e);
    }
  }

  @override
  Future<Profile> removeAvatar() async {
    try {
      return await _ds.removeAvatar();
    } catch (e) {
      throw mapProfileException(e);
    }
  }
}

/// DI-провайдер репозитория профиля.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider)),
);
