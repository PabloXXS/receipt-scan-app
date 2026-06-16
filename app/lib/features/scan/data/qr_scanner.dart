/// Назначение: извлечение QR (УИ) из фото чека через нативный канал scan/qr.
///
/// Слой: data
/// Фича: scan
/// Зависимости: flutter/services, flutter_riverpod.
/// Ключевые типы: QrScanner, VisionQrScanner, qrScannerProvider.
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Извлекает строку QR из фото (или `null`, если QR не найден).
abstract interface class QrScanner {
  Future<String?> scan(Uint8List photoBytes);
}

/// Реализация поверх нативного Vision (канал `scan/qr`).
class VisionQrScanner implements QrScanner {
  const VisionQrScanner();

  static const _channel = MethodChannel('scan/qr');

  @override
  Future<String?> scan(Uint8List photoBytes) async {
    final res = await _channel.invokeMapMethod<String, dynamic>(
      'scanQr',
      {'bytes': photoBytes},
    );
    return res?['qr'] as String?;
  }
}

/// DI-провайдер QR-сканера.
final qrScannerProvider = Provider<QrScanner>((ref) => const VisionQrScanner());
