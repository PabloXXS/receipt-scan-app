import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'receipt_item.dart';

part 'receipt_wizard_state.freezed.dart';

@freezed
class ReceiptWizardState with _$ReceiptWizardState {
  const factory ReceiptWizardState({
    @Default(ReceiptWizardStep.preview) ReceiptWizardStep currentStep,
    @Default(null) ReceiptSourceType? sourceType,
    @Default(null) Uint8List? imageBytes,
    @Default(null) String? imageUrl,
    @Default(null) String? categoryName,
    @Default(null) String? currencyCode,
    @Default([]) List<ReceiptItem> items,
    @Default(null) String? totalAmountText,
    @Default(false) bool isAnalyzing,
    @Default(null) String? errorText,
    @Default(false) bool isSaving,
    @Default(false) bool isPickingImage,
    @Default(false) bool isImagePickCanceled,
    @Default(null) String? receiptId, // ID чека для очистки при отмене
    @Default(false) bool isCancelling, // Флаг отмены анализа
    @Default(null) String? merchantName,
    @Default(null) DateTime? purchaseDate,
    @Default(null) DateTime? purchaseTime,
  }) = _ReceiptWizardState;
}

enum ReceiptWizardStep {
  preview,
  result,
}

enum ReceiptSourceType {
  camera,
  gallery,
  url,
  manual,
}
