/// Назначение: перевод исключений Supabase/сети в ReceiptsFailure.
///
/// Слой: data
/// Фича: receipts
/// Зависимости: dart:io, supabase_flutter, core/error/failure.dart.
/// Ключевые типы: mapReceiptsException.
library;

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';

/// Преобразует [error] в [ReceiptsFailure]. Готовый [ReceiptsFailure] — как есть.
ReceiptsFailure mapReceiptsException(Object error) {
  if (error is ReceiptsFailure) return error;
  if (error is SocketException) return const ReceiptsNetworkFailure();
  if (error is StorageException) return const ReceiptsLoadFailure();
  if (error is PostgrestException) return const ReceiptsLoadFailure();
  return const UnknownReceiptsFailure();
}
