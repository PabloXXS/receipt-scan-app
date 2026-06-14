/// Назначение: контроллер состояния профиля (загрузка + мутации).
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: dart:typed_data, riverpod_annotation,
///   data/repositories/profile_repository_impl.dart, domain/entities/profile.dart.
/// Ключевые типы: ProfileController, profileControllerProvider.
library;

import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile.dart';

part 'profile_controller.g.dart';

/// Асинхронное состояние профиля текущего пользователя.
@riverpod
class ProfileController extends _$ProfileController {
  @override
  Future<Profile> build() {
    return ref.watch(profileRepositoryProvider).getCurrent();
  }

  Future<void> _mutate(Future<Profile> Function() action) async {
    state = const AsyncLoading<Profile>().copyWithPrevious(state);
    state = await AsyncValue.guard(action);
  }

  /// Меняет отображаемое имя.
  Future<void> updateName(String displayName) => _mutate(
      () => ref.read(profileRepositoryProvider).updateName(displayName));

  /// Меняет страну.
  Future<void> setCountry(String countryCode) => _mutate(
      () => ref.read(profileRepositoryProvider).setCountry(countryCode));

  /// Загружает новый аватар (готовые байты).
  Future<void> updateAvatar(Uint8List bytes) =>
      _mutate(() => ref.read(profileRepositoryProvider).updateAvatar(bytes));

  /// Удаляет аватар.
  Future<void> removeAvatar() =>
      _mutate(() => ref.read(profileRepositoryProvider).removeAvatar());
}
