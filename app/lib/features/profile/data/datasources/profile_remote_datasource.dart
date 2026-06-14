/// Назначение: доступ к строке profiles и Storage-бакету avatars.
///
/// Слой: data
/// Фича: profile
/// Зависимости: dart:typed_data, flutter_riverpod, supabase_flutter,
///   core/supabase/supabase_providers.dart, models/profile_dto.dart, domain/entities.
/// Ключевые типы: ProfileRemoteDataSource, SupabaseProfileRemoteDataSource,
///   profileRemoteDataSourceProvider.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../domain/entities/profile.dart';
import '../models/profile_dto.dart';

/// Удалённые операции с профилем и аватаром.
abstract interface class ProfileRemoteDataSource {
  Future<Profile> fetchCurrent();
  Future<Profile> updateName(String displayName);
  Future<Profile> setCountry(String countryCode);
  Future<Profile> uploadAvatar(Uint8List bytes);
  Future<Profile> removeAvatar();
}

/// Реализация поверх Supabase PostgREST + Storage.
class SupabaseProfileRemoteDataSource implements ProfileRemoteDataSource {
  const SupabaseProfileRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'avatars';

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<Profile> fetchCurrent() async {
    final row = await _client
        .from('profiles')
        .select(kProfileColumns)
        .eq('id', _uid)
        .single();
    return profileFromRow(row);
  }

  Future<Profile> _patch(Map<String, dynamic> values) async {
    final row = await _client
        .from('profiles')
        .update(values)
        .eq('id', _uid)
        .select(kProfileColumns)
        .single();
    return profileFromRow(row);
  }

  @override
  Future<Profile> updateName(String displayName) =>
      _patch({'display_name': displayName});

  @override
  Future<Profile> setCountry(String countryCode) =>
      _patch({'country_code': countryCode});

  @override
  Future<Profile> uploadAvatar(Uint8List bytes) async {
    final path = '$_uid/avatar.jpg';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions:
              const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    final base = _client.storage.from(_bucket).getPublicUrl(path);
    // Cache-bust, чтобы UI подхватил новый файл по тому же пути.
    final url = '$base?v=${DateTime.now().millisecondsSinceEpoch}';
    return _patch({'avatar_url': url});
  }

  @override
  Future<Profile> removeAvatar() async {
    await _client.storage.from(_bucket).remove(['$_uid/avatar.jpg']);
    return _patch({'avatar_url': null});
  }
}

/// DI-провайдер источника данных профиля.
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => SupabaseProfileRemoteDataSource(ref.watch(supabaseClientProvider)),
);
