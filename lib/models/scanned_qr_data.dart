import 'package:freezed_annotation/freezed_annotation.dart';

part 'scanned_qr_data.freezed.dart';

/// Тип распознанного QR-кода
enum QrCodeType {
  url, // HTTP(S) ссылка на чек
  fiscalData, // Фискальные данные (Россия, Беларусь и т.д.)
  unknown, // Неизвестный формат, но можем попытаться извлечь данные
}

/// Результат сканирования QR-кода
@freezed
class ScannedQrData with _$ScannedQrData {
  const factory ScannedQrData({
    required QrCodeType type,
    required String rawText,
    // Извлеченные поля (если удалось распарсить)
    double? amount,
    DateTime? dateTime,
    String? merchantName,
    String? url,
    @Default({}) Map<String, dynamic> additionalData,
  }) = _ScannedQrData;
}



