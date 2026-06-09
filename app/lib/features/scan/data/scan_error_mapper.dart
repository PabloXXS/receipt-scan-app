/// Назначение: перевод исключений image_picker/Supabase/сети в ScanFailure.
///
/// Слой: data
/// Фича: scan
/// Зависимости: dart:io, flutter/services, supabase_flutter, core/error/failure.dart.
/// Ключевые типы: mapScanException.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';

/// Преобразует [error] в [ScanFailure]. Уже готовый [ScanFailure] возвращается как есть.
ScanFailure mapScanException(Object error) {
  if (error is ScanFailure) return error;
  if (error is SocketException) return const ScanNetworkFailure();
  if (error is PlatformException) {
    if (error.code == 'camera_access_denied' ||
        error.code == 'photo_access_denied') {
      return const CameraPermissionDeniedFailure();
    }
    return const UnknownScanFailure();
  }
  if (error is StorageException) return const UploadFailure();
  if (error is PostgrestException) return const UploadFailure();
  return const UnknownScanFailure();
}
