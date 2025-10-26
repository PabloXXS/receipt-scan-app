import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../models/receipt_wizard_state.dart';
import '../models/receipt_item.dart';
import '../core/receipts_api.dart';
import 'receipts_provider.dart';

part 'receipt_wizard_provider.g.dart';

@riverpod
class ReceiptWizard extends _$ReceiptWizard {
  @override
  ReceiptWizardState build() => const ReceiptWizardState();

  void setStep(ReceiptWizardStep step) {
    state = state.copyWith(currentStep: step);
  }

  void setImage(Uint8List bytes) {
    state = state.copyWith(
      imageBytes: bytes,
      imageUrl: null,
      errorText: null,
    );
  }

  void setUrl(String url) {
    state = state.copyWith(
      imageUrl: url,
      imageBytes: null,
      errorText: null,
    );
  }

  void setCategoryName(String name) {
    state = state.copyWith(categoryName: name);
  }

  void setCurrencyCode(String code) {
    state = state.copyWith(currencyCode: code);
  }

  void setTotalAmountText(String text) {
    state = state.copyWith(totalAmountText: text);
  }

  void setMerchantName(String name) {
    state = state.copyWith(merchantName: name);
  }

  void setPurchaseDate(DateTime date) {
    state = state.copyWith(purchaseDate: date);
  }

  void setPurchaseTime(DateTime time) {
    state = state.copyWith(purchaseTime: time);
  }

  void clearState() {
    state = const ReceiptWizardState();
  }

  Future<void> initWithSource(ReceiptSourceType source) async {
    state = state.copyWith(sourceType: source);

    switch (source) {
      case ReceiptSourceType.manual:
        // Сразу переходим к результату с пустым списком
        state = state.copyWith(
          currentStep: ReceiptWizardStep.result,
          items: [],
          currencyCode: 'RUB',
        );
        break;

      case ReceiptSourceType.camera:
        // Открываем камеру
        await pickImage(ImageSource.camera);
        break;

      case ReceiptSourceType.gallery:
        // Открываем галерею
        await pickImage(ImageSource.gallery);
        break;

      case ReceiptSourceType.url:
        // Просто показываем preview с полем для URL
        state = state.copyWith(currentStep: ReceiptWizardStep.preview);
        break;
    }
  }

  void setItems(List<ReceiptItem> items) {
    state = state.copyWith(items: items);
  }

  void addItem(ReceiptItem item) {
    final newItems = [...state.items, item];
    final newTotal = newItems.fold(0.0, (sum, item) => sum + item.total);
    state = state.copyWith(
      items: newItems,
      totalAmountText: newTotal.toStringAsFixed(2),
    );
  }

  void updateItem(int index, ReceiptItem item) {
    final newItems = List<ReceiptItem>.from(state.items);
    newItems[index] = item;
    final newTotal = newItems.fold(0.0, (sum, item) => sum + item.total);
    state = state.copyWith(
      items: newItems,
      totalAmountText: newTotal.toStringAsFixed(2),
    );
  }

  void removeItem(int index) {
    final newItems = List<ReceiptItem>.from(state.items);
    newItems.removeAt(index);
    final newTotal = newItems.fold(0.0, (sum, item) => sum + item.total);
    state = state.copyWith(
      items: newItems,
      totalAmountText: newTotal.toStringAsFixed(2),
    );
  }

  void sortItems(String sortOption) {
    final List<ReceiptItem> sortedItems = List<ReceiptItem>.from(state.items);

    switch (sortOption) {
      case 'price_desc':
        sortedItems.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'price_asc':
        sortedItems.sort((a, b) => a.total.compareTo(b.total));
        break;
      case 'name_asc':
        sortedItems.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        sortedItems.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }

    state = state.copyWith(items: sortedItems);
  }

  void setError(String error) {
    state = state.copyWith(errorText: error);
  }

  void clearError() {
    state = state.copyWith(errorText: null);
  }

  Future<void> pickImage(ImageSource source) async {
    final hadImageBefore = state.imageBytes != null;
    state = state.copyWith(isPickingImage: true, isImagePickCanceled: false);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? xfile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (xfile == null) {
        // Пользователь отменил выбор
        // Закрываем wizard только если это был первый выбор
        state = state.copyWith(
          isPickingImage: false,
          isImagePickCanceled: !hadImageBefore,
        );
        return;
      }

      final Uint8List raw = await xfile.readAsBytes();
      final Uint8List processed = await _preprocessImage(raw);

      setImage(processed);
      setStep(ReceiptWizardStep.preview);
      state = state.copyWith(isPickingImage: false);
    } catch (e) {
      state = state.copyWith(isPickingImage: false);
      setError('Ошибка выбора изображения: $e');
    }
  }

  Future<void> analyzeReceipt() async {
    if (state.imageBytes == null && state.imageUrl == null) {
      setError('Не выбран источник для анализа');
      return;
    }

    state = state.copyWith(
      isAnalyzing: true,
      errorText: null,
      receiptId: null,
      isCancelling: false,
    );

    String? receiptId;

    try {
      final SupabaseClient client = Supabase.instance.client;
      final String? userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Не авторизован');
      }

      if (state.imageBytes != null) {
        receiptId = await _analyzeImage(userId);
      } else {
        receiptId = await _analyzeUrl();
      }

      // Проверяем отмену после создания чека
      if (state.isCancelling) {
        if (receiptId != null) {
          await _deleteFailedReceipt(receiptId);
        }
        state = state.copyWith(
          isAnalyzing: false,
          isCancelling: false,
          receiptId: null,
        );
        return;
      }

      // После этого receiptId точно не null
      if (receiptId == null) {
        throw Exception('Failed to get receipt ID');
      }

      // Сохраняем receiptId для возможной очистки при отмене
      state = state.copyWith(receiptId: receiptId);

      await _pollReceiptStatus(receiptId);

      // Если отменено во время polling - не переходим к результату
      if (state.isCancelling) {
        return;
      }

      state = state.copyWith(
        currentStep: ReceiptWizardStep.result,
        isAnalyzing: false,
      );
    } catch (e) {
      // При ошибке удаляем чек из БД, если он был создан
      if (receiptId != null && !state.isCancelling) {
        await _deleteFailedReceipt(receiptId);
      }

      state = state.copyWith(
        isAnalyzing: false,
        isCancelling: false,
        errorText: 'Ошибка анализа: $e',
        receiptId: null,
      );
    }
  }

  Future<String> _analyzeImage(String userId) async {
    final SupabaseClient client = Supabase.instance.client;

    // 1) Upload to Storage
    final DateTime now = DateTime.now();
    final String path =
        '$userId/${now.year.toString().padLeft(4, '0')}/${now.month.toString().padLeft(2, '0')}/receipt-${now.millisecondsSinceEpoch}.jpg';

    await client.storage.from('receipts').uploadBinary(
          path,
          state.imageBytes!,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    // 2) Insert file record
    final Map<String, dynamic> fileRow = {
      'bucket': 'receipts',
      'path': path,
      'mime': 'image/jpeg',
      'size': state.imageBytes!.length,
    };

    final Map<String, dynamic> inserted =
        await client.from('files').insert(fileRow).select('id').single();

    final String fileId = inserted['id'] as String;

    // 3) Call analyze function
    final dynamic resp = await client.functions.invoke(
      'analyze',
      body: {'file_id': fileId},
    );

    final int status = (resp.status as int?) ?? 200;
    if (status >= 400) {
      throw Exception('analyze error: HTTP $status ${resp.data}');
    }

    final Map<String, dynamic> body =
        (resp.data as Map).cast<String, dynamic>();
    return body['receipt_id'] as String;
  }

  Future<String> _analyzeUrl() async {
    final ReceiptsApi api = ReceiptsApi();
    return await api.analyzeByUrl(url: state.imageUrl!);
  }

  Future<void> _pollReceiptStatus(String receiptId) async {
    final SupabaseClient client = Supabase.instance.client;
    const int maxAttempts = 20;

    for (int i = 0; i < maxAttempts; i++) {
      // Проверяем отмену на каждой итерации
      if (state.isCancelling) {
        debugPrint('🛑 [RECEIPT_WIZARD] Анализ отменен пользователем');
        await _deleteFailedReceipt(receiptId);
        state = state.copyWith(
          isAnalyzing: false,
          isCancelling: false,
          receiptId: null,
        );
        return;
      }

      developer.log(
          '[ReceiptWizard] Polling receipt status, attempt $i/$maxAttempts',
          name: 'ReceiptWizard');
      final Map<String, dynamic> row = await client
          .from('receipts')
          .select('status,error_text,currency,merchant_name')
          .eq('id', receiptId)
          .single();

      developer.log('[ReceiptWizard] Received row: $row',
          name: 'ReceiptWizard');
      final String status = (row['status'] as String?) ?? 'processing';
      developer.log('[ReceiptWizard] Status: $status', name: 'ReceiptWizard');

      if (status == 'ready') {
        // Категория будет установлена пользователем вручную
        // OCR не определяет категорию автоматически

        // Extract currency
        final String? currency = row['currency'] as String?;
        if (currency != null && currency.isNotEmpty) {
          setCurrencyCode(currency.toUpperCase());
        }

        // Load items
        final ReceiptsApi api = ReceiptsApi();
        final List<ReceiptLine> lines =
            await api.fetchReceiptItems(receiptId: receiptId);
        final List<ReceiptItem> items = lines
            .map((ReceiptLine l) => ReceiptItem(
                  id: '', // Временное значение для wizard
                  receiptId: receiptId,
                  name: l.name,
                  quantity: l.qty,
                  price: l.price,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ))
            .toList();

        setItems(items);

        // Устанавливаем сумму чека с правильным форматированием
        final double total = items.fold(0.0, (sum, item) => sum + item.total);
        setTotalAmountText(total.toStringAsFixed(2));

        return;
      }

      if (status == 'failed') {
        final String error = (row['error_text'] as String?) ?? 'Ошибка анализа';
        throw Exception(error);
      }

      await Future<void>.delayed(const Duration(seconds: 1));
    }

    throw Exception('Таймаут ожидания анализа');
  }

  Future<Uint8List> _preprocessImage(Uint8List bytes) async {
    try {
      final img.Image? original = img.decodeImage(bytes);
      if (original == null) return bytes;

      img.Image work = original;

      // Downscale to max 2000px on larger side для оптимизации размера
      const int maxSide = 2000;
      final int w = work.width;
      final int h = work.height;

      if (w > maxSide || h > maxSide) {
        if (w >= h) {
          work = img.copyResize(work, width: maxSide);
        } else {
          work = img.copyResize(work, height: maxSide);
        }
      }

      // Encode JPEG quality 85 для баланса качества и размера
      final List<int> encoded = img.encodeJpg(work, quality: 85);
      return Uint8List.fromList(encoded);
    } catch (_) {
      // Fallback to original
      return bytes;
    }
  }

  Future<void> saveReceipt() async {
    debugPrint('📝 [RECEIPT_WIZARD] saveReceipt вызван');

    if (state.currencyCode == null || state.currencyCode!.isEmpty) {
      debugPrint('❌ [RECEIPT_WIZARD] Ошибка: валюта не выбрана');
      setError('Выберите валюту');
      return;
    }

    if (state.items.isEmpty) {
      debugPrint('❌ [RECEIPT_WIZARD] Ошибка: нет товаров');
      setError('Добавьте хотя бы один товар');
      return;
    }

    debugPrint('📝 [RECEIPT_WIZARD] Валидация пройдена.');

    state = state.copyWith(isSaving: true);

    try {
      final SupabaseClient client = Supabase.instance.client;
      final String? userId = client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Не авторизован');
      }

      debugPrint('📝 [RECEIPT_WIZARD] userId: $userId');

      // Название магазина из формы
      final String merchantName = state.merchantName?.trim() ?? '';

      debugPrint('📝 [RECEIPT_WIZARD] merchantName: $merchantName');

      // Дата и время покупки
      final DateTime purchaseDate = state.purchaseDate ?? DateTime.now();
      final DateTime purchaseTime = state.purchaseTime ?? DateTime.now();

      // 2. Создаем чек
      final Map<String, dynamic> receiptData = {
        'user_id': userId,
        'merchant_name': merchantName, // Название магазина (не FK)
        'total': state.totalAmountText != null
            ? (double.tryParse(state.totalAmountText!) ?? 0.0)
            : state.items.fold(0.0, (sum, item) => sum + item.total),
        'currency': state.currencyCode ?? 'RUB',
        'status': 'ready',
        'purchase_date': purchaseDate.toIso8601String().split('T')[0],
        'purchase_time':
            '${purchaseTime.hour.toString().padLeft(2, '0')}:${purchaseTime.minute.toString().padLeft(2, '0')}:00',
      };

      debugPrint('📝 [RECEIPT_WIZARD] Создаём чек с данными: $receiptData');

      final Map<String, dynamic> receipt = await client
          .from('receipts')
          .insert(receiptData)
          .select('id')
          .single();

      final String receiptId = receipt['id'] as String;

      debugPrint('📝 [RECEIPT_WIZARD] Чек создан. receiptId: $receiptId');

      // 3. Создаем позиции чека
      for (final item in state.items) {
        await client.from('receipt_items').insert({
          'receipt_id': receiptId,
          'name': item.name,
          'qty': item.quantity,
          'price': item.price,
          'category_id': item.categoryId,
        });
      }

      debugPrint(
          '📝 [RECEIPT_WIZARD] Добавлено ${state.items.length} позиций чека');

      state = state.copyWith(isSaving: false);

      // Обновляем список чеков после успешного сохранения
      ref.invalidate(receiptsProvider);

      debugPrint('📝 [RECEIPT_WIZARD] Чек успешно сохранён');
    } catch (e, stackTrace) {
      debugPrint('❌ [RECEIPT_WIZARD] Ошибка сохранения: $e');
      debugPrint('❌ [RECEIPT_WIZARD] Stack trace: $stackTrace');
      state = state.copyWith(
        isSaving: false,
        errorText: 'Ошибка сохранения: $e',
      );
    }
  }

  void reset() {
    state = const ReceiptWizardState();
  }

  /// Удаляет чек при отмене или ошибке (оптимизированная версия)
  Future<void> _deleteFailedReceipt(String receiptId) async {
    try {
      final SupabaseClient client = Supabase.instance.client;

      // Удаляем сразу с условием в запросе (1 запрос вместо 2 для скорости)
      final response = await client
          .from('receipts')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', receiptId)
          .or('status.eq.processing,status.eq.failed')
          .select('id');

      if (response.isNotEmpty) {
        debugPrint('🗑️ [RECEIPT_WIZARD] Удален незавершенный чек: $receiptId');
      }
    } catch (e) {
      debugPrint('⚠️ [RECEIPT_WIZARD] Ошибка удаления чека: $e');
      // Не прерываем работу при ошибке удаления
    }
  }

  /// Отменяет текущий анализ
  void cancelAnalysis() {
    if (state.isAnalyzing) {
      debugPrint('🛑 [RECEIPT_WIZARD] Запрос на отмену анализа');
      state = state.copyWith(isCancelling: true);
    }
  }

  /// Отменяет wizard и очищает незавершенный чек
  Future<void> cancelAndCleanup() async {
    // Если есть незавершенный чек - удаляем его немедленно
    if (state.receiptId != null) {
      await _deleteFailedReceipt(state.receiptId!);
    }
    clearState();
  }
}
