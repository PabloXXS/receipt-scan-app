/// Назначение: перевод исключений Supabase/сети в ProfileFailure.
///
/// Слой: data
/// Фича: profile
/// Зависимости: dart:io, supabase_flutter, core/error/failure.dart.
/// Ключевые типы: mapProfileException.
library;

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';

/// Преобразует [error] в [ProfileFailure]. Готовый [ProfileFailure] — как есть.
ProfileFailure mapProfileException(Object error) {
  if (error is ProfileFailure) return error;
  if (error is SocketException) return const ProfileNetworkFailure();
  if (error is StorageException) return const ProfileAvatarFailure();
  if (error is PostgrestException) return const ProfileLoadFailure();
  return const UnknownProfileFailure();
}
