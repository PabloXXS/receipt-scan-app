import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import '../core/receipts_api.dart';
import 'package:currency_picker/currency_picker.dart';

class _Canceled implements Exception {
  const _Canceled();
}

class TempReceiptItem {
  TempReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final double quantity;
  final double price;

  double get total => price * quantity;
}

class ReceiptAddResult {
  ReceiptAddResult({
    required this.merchantName,
    required this.items,
  });

  final String merchantName;
  final List<TempReceiptItem> items;

  int get itemsCount => items.length;
  double get totalAmount =>
      items.fold(0.0, (double acc, TempReceiptItem i) => acc + i.total);
}

class ReceiptAddSheet extends StatefulWidget {
  const ReceiptAddSheet({
    super.key,
    this.showInlineHeader = false,
    this.constrainHeight = true,
    this.initialUrl,
    this.initialImageBytes,
    this.autoStart = false,
  });

  // Поля оставлены для совместимости hot reload
  final bool showInlineHeader;
  final bool constrainHeight;
  final String? initialUrl;
  final Uint8List? initialImageBytes;
  final bool autoStart;

  @override
  State<ReceiptAddSheet> createState() => _ReceiptAddSheetState();
}

class _ReceiptAddSheetState extends State<ReceiptAddSheet> {
  final TextEditingController _merchantController = TextEditingController();
  final ValueNotifier<bool> _isAnalyzing = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _errorText = ValueNotifier<String?>(null);
  final TextEditingController _urlController = TextEditingController();
  List<TempReceiptItem> _items = <TempReceiptItem>[];
  Uint8List? _imageBytes;
  bool _cancelRequested = false;
  String? _currencyCode; // ISO-4217 код валюты

  void _throwIfCancelled() {
    if (_cancelRequested) {
      throw const _Canceled();
    }
  }

  void _cancelImageAndAnalysis() {
    _cancelRequested = true;
    _isAnalyzing.value = false;
    setState(() {
      _imageBytes = null;
    });
  }

  String _totalAmountString() {
    final double sum = _items.fold<double>(
      0.0,
      (double acc, TempReceiptItem item) => acc + item.total,
    );
    return sum.toStringAsFixed(2);
  }

  String _formatQty(double q) {
    if (q == q.roundToDouble()) {
      return q.toStringAsFixed(0);
    }
    return q
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'[\.,]$'), '');
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _isAnalyzing.dispose();
    _errorText.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _urlController.text = widget.initialUrl!;
      if (widget.autoStart) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalyzeByUrl());
      }
    }
    if (widget.initialImageBytes != null &&
        widget.initialImageBytes!.isNotEmpty) {
      _imageBytes = widget.initialImageBytes;
      if (widget.autoStart) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          _isAnalyzing.value = true;
          _cancelRequested = false;
          try {
            await _runAnalyzeFlow();
          } on _Canceled {
            return;
          } catch (e) {
            _errorText.value = 'Ошибка анализа: $e';
          } finally {
            _isAnalyzing.value = false;
          }
        });
      } else {
        setState(() {});
      }
    }
  }

  Future<Uint8List> _preprocessImage(Uint8List bytes) async {
    try {
      final img.Image? original = img.decodeImage(bytes);
      if (original == null) return bytes;
      img.Image work = original;

      // downscale to max 2000px on larger side
      final int maxSide = 2000;
      final int w = work.width;
      final int h = work.height;
      if (w > maxSide || h > maxSide) {
        if (w >= h) {
          work = img.copyResize(work, width: maxSide);
        } else {
          work = img.copyResize(work, height: maxSide);
        }
      }

      // convert to grayscale
      work = img.grayscale(work);

      // encode JPEG quality 85
      final List<int> encoded = img.encodeJpg(work, quality: 85);
      return Uint8List.fromList(encoded);
    } catch (_) {
      // fallback to original
      return bytes;
    }
  }

  Future<void> _runAnalyzeFlow() async {
    final SupabaseClient client = Supabase.instance.client;
    final String? userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Не авторизован');
    }
    if (_imageBytes == null) {
      throw Exception('Изображение не выбрано');
    }
    _throwIfCancelled();

    // 1) Upload to Storage (private bucket)
    final DateTime now = DateTime.now();
    final String path =
        '${userId}/${now.year.toString().padLeft(4, '0')}/${now.month.toString().padLeft(2, '0')}/receipt-${now.millisecondsSinceEpoch}.jpg';
    await client.storage.from('receipts').uploadBinary(
          path,
          _imageBytes!,
          fileOptions:
              const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    _throwIfCancelled();

    // 2) Insert row into files and get file_id
    final Map<String, dynamic> fileRow = <String, dynamic>{
      'bucket': 'receipts',
      'path': path,
      'mime': 'image/jpeg',
      'size': _imageBytes!.length,
    };
    final Map<String, dynamic> inserted =
        await client.from('files').insert(fileRow).select('id').single();
    final String fileId = inserted['id'] as String;
    _throwIfCancelled();

    // 3) Call analyze edge function
    final dynamic resp = await client.functions.invoke(
      'analyze',
      body: <String, dynamic>{'file_id': fileId},
    );
    final int status = (resp.status as int?) ?? 200;
    if (status >= 400) {
      throw Exception('analyze error: HTTP $status ${resp.data}');
    }
    final Map<String, dynamic> body =
        (resp.data as Map).cast<String, dynamic>();
    final String receiptId = body['receipt_id'] as String;

    // 4) Poll receipts until ready/failed
    const int maxAttempts = 20;
    for (int i = 0; i < maxAttempts; i++) {
      _throwIfCancelled();
      developer.log('[ReceiptAddSheet] Polling receipt status, attempt $i/$maxAttempts', name: 'ReceiptAddSheet');
      final Map<String, dynamic> row = await client
          .from('receipts')
          .select('status,error_text,currency,merchant_name')
          .eq('id', receiptId)
          .single();
      developer.log('[ReceiptAddSheet] Received row: $row', name: 'ReceiptAddSheet');
      final String status = (row['status'] as String?) ?? 'processing';
      developer.log('[ReceiptAddSheet] Status: $status', name: 'ReceiptAddSheet');
      if (status == 'ready') {
        final String store = (row['merchant_name'] as String?) ?? '';
        if (store.isNotEmpty) {
          _merchantController.text = store;
        }
        final String? dbCurrency = row['currency'] as String?;
        if (dbCurrency != null && dbCurrency.isNotEmpty) {
          _currencyCode = dbCurrency.toUpperCase();
          final Currency? c = CurrencyService().findByCode(_currencyCode);
          developer.log(
            'currency detected (db): ${_currencyCode}${c != null ? ' - ' + c.name : ''}',
            name: 'receipt',
          );
        }
        // 5) Load items
        final ReceiptsApi api = ReceiptsApi();
        final List<ReceiptLine> lines =
            await api.fetchReceiptItems(receiptId: receiptId);
        _items = lines
            .map((ReceiptLine l) => TempReceiptItem(
                  name: l.name,
                  quantity: l.qty,
                  price: l.price,
                ))
            .toList();
        setState(() {});
        return;
      }
      if (status == 'failed') {
        final String err = (row['error_text'] as String?) ?? 'Ошибка анализа';
        throw Exception(err);
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    throw Exception('Таймаут ожидания анализа');
  }

  Future<void> _runAnalyzeByUrl() async {
    final String raw = _urlController.text.trim();
    if (raw.isEmpty) return;
    _errorText.value = null;
    _isAnalyzing.value = true;
    _cancelRequested = false;
    try {
      final Uri? parsed = Uri.tryParse(raw);
      if (parsed == null || !parsed.hasScheme) {
        throw Exception('Некорректный URL');
      }
      final ReceiptsApi api = ReceiptsApi();
      final String receiptId = await api.analyzeByUrl(url: raw);
      final SupabaseClient client = Supabase.instance.client;
      // poll until ready
      const int maxAttempts = 20;
      for (int i = 0; i < maxAttempts; i++) {
        _throwIfCancelled();
        developer.log('[ReceiptAddSheet-Inline] Polling receipt status, attempt $i/$maxAttempts', name: 'ReceiptAddSheet');
        final Map<String, dynamic> row = await client
            .from('receipts')
            .select('status,error_text,currency,merchant_name')
            .eq('id', receiptId)
            .single();
        developer.log('[ReceiptAddSheet-Inline] Received row: $row', name: 'ReceiptAddSheet');
        final String status = (row['status'] as String?) ?? 'processing';
        developer.log('[ReceiptAddSheet-Inline] Status: $status', name: 'ReceiptAddSheet');
        if (status == 'ready') {
          final String store = (row['merchant_name'] as String?) ?? '';
          if (store.isNotEmpty) {
            _merchantController.text = store;
          }
          // валюта из БД приоритизируется над эвристикой
          final String? dbCurrency = row['currency'] as String?;
          if (dbCurrency != null && dbCurrency.isNotEmpty) {
            _currencyCode = dbCurrency.toUpperCase();
            final Currency? c = CurrencyService().findByCode(_currencyCode);
            developer.log(
              'currency detected (db): ${_currencyCode}${c != null ? ' - ' + c.name : ''}',
              name: 'receipt',
            );
          } else {
            // попробуем определить валюту по коду/символу в тексте URL-чека
            final String allText = textFromUrlFallback(_urlController.text);
            final String? detected = _detectCurrencyFromText(allText);
            if (detected != null) {
              _currencyCode = detected;
              final Currency? c = CurrencyService().findByCode(_currencyCode);
              developer.log(
                'currency detected (regex): ${_currencyCode}${c != null ? ' - ' + c.name : ''}',
                name: 'receipt',
              );
            }
          }
          // load items
          final List<ReceiptLine> lines =
              await api.fetchReceiptItems(receiptId: receiptId);
          _items = lines
              .map((ReceiptLine l) => TempReceiptItem(
                    name: l.name,
                    quantity: l.qty,
                    price: l.price,
                  ))
              .toList();
          setState(() {});
          return;
        }
        if (status == 'failed') {
          final String err = (row['error_text'] as String?) ?? 'Ошибка анализа';
          throw Exception(err);
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      throw Exception('Таймаут ожидания анализа');
    } on _Canceled {
      return;
    } catch (e) {
      _errorText.value = 'Ошибка анализа URL: $e';
    } finally {
      _isAnalyzing.value = false;
    }
  }

  // Фолбэк-функция (заглушка) — для совместимости компиляции
  String textFromUrlFallback(String _) => '';

  String? _detectCurrencyFromText(String text) {
    final String t = text.toLowerCase();
    final List<(String, RegExp)> patterns = <(String, RegExp)>[
      ('BYN', RegExp(r'\bby[nr]\b|\bby[n]\b|\bbyr\b|\sbr\b|бел\.?\s*руб')),
      ('RUB', RegExp(r'₽|\bруб\.?\b|\brur\b|\brub\b|\br\b')),
      ('KZT', RegExp(r'₸|\bkzt\b|\bтг\b')),
      ('UAH', RegExp(r'₴|\buah\b|грн|грив')),
      ('PLN', RegExp(r'zł|\bpln\b|зл\b')),
      ('EUR', RegExp(r'€|\beur\b|евро')),
      ('USD', RegExp(r'\$|\busd\b|долл|доллар')),
    ];
    for (final (String code, RegExp re) in patterns) {
      if (re.hasMatch(t)) return code;
    }
    return null;
  }

  void _openCurrencyMenu() {
    final Size size = MediaQuery.of(context).size;
    final double statusBar = MediaQuery.of(context).padding.top;
    const double extraTopInset = 24; // визуальный отступ сверху
    final double sheetHeight =
        size.height - (statusBar + (kToolbarHeight / 1.5) + extraTopInset);

    final CurrencyService service = CurrencyService();
    final List<Currency> all = service.getAll();
    final List<String> recommendedCodes = <String>[
      'BYN',
      'RUB',
      'PLN',
      'EUR',
      'USD'
    ];
    final List<Currency> recommended =
        service.findCurrenciesByCode(recommendedCodes);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext ctx) {
        String query = '';
        List<Currency> filtered = List<Currency>.from(all);
        void applyFilter(String q) {
          query = q.trim();
          if (query.isEmpty) {
            filtered = List<Currency>.from(all);
          } else {
            final String qq = query.toLowerCase();
            filtered = all
                .where((Currency c) =>
                    c.name.toLowerCase().contains(qq) ||
                    c.code.toLowerCase().contains(qq))
                .toList();
          }
        }

        applyFilter('');
        return SafeArea(
          top: true,
          bottom: false,
          child: SizedBox(
            height: sheetHeight,
            child: StatefulBuilder(
              builder:
                  (BuildContext context, void Function(void Function()) setSt) {
                Widget buildTile(Currency c) {
                  final bool isSelected = (_currencyCode ?? '') == c.code;
                  Widget leading;
                  if (c.flag == null) {
                    leading = Image.asset(
                      'lib/src/res/no_flag.png',
                      package: 'currency_picker',
                      width: 27,
                    );
                  } else if (c.isFlagImage) {
                    leading = Image.asset(
                      'lib/src/res/${c.flag!}',
                      package: 'currency_picker',
                      width: 27,
                    );
                  } else {
                    leading = Text(
                      CurrencyUtils.currencyToEmoji(c),
                      style: const TextStyle(fontSize: 22),
                    );
                  }
                  return ListTile(
                    leading: leading,
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(c.code,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        if (isSelected) ...<Widget>[
                          const SizedBox(width: 8),
                          const Icon(Icons.check, size: 18),
                        ],
                      ],
                    ),
                    onTap: () {
                      setState(() => _currencyCode = c.code);
                      Navigator.of(ctx).pop();
                    },
                  );
                }

                return Material(
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Поиск',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (String v) => setSt(() => applyFilter(v)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: <Widget>[
                            if (query.isEmpty &&
                                recommended.isNotEmpty) ...<Widget>[
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: Text(
                                  'рекомендации',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              ...recommended.map(buildTile),
                              const Divider(height: 1),
                            ],
                            ...filtered.map(buildTile),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? xfile =
        await picker.pickImage(source: source, imageQuality: 85);
    if (xfile == null) return;
    _errorText.value = null;
    final Uint8List raw = await xfile.readAsBytes();
    _imageBytes = await _preprocessImage(raw);
    setState(() {});
    // Реальный анализ: upload → analyze → poll → fill items
    _isAnalyzing.value = true;
    _cancelRequested = false;
    try {
      await _runAnalyzeFlow();
    } on _Canceled {
      // тишина при отмене
      return;
    } catch (e) {
      _errorText.value = 'Ошибка анализа: $e';
    } finally {
      _isAnalyzing.value = false;
    }
  }

  Future<void> _onPickImagePressed() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Сделать фото'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _showImagePreview() async {
    if (_imageBytes == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: Hero(
              tag: 'receipt_preview',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                  errorBuilder: (BuildContext context, Object error,
                          StackTrace? stackTrace) =>
                      const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editItem(int index) async {
    final TempReceiptItem current = _items[index];
    final TextEditingController nameCtrl =
        TextEditingController(text: current.name);
    final TextEditingController qtyCtrl =
        TextEditingController(text: current.quantity.toString());
    final TextEditingController priceCtrl =
        TextEditingController(text: current.price.toStringAsFixed(2));

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Редактировать позицию'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Количество',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Цена',
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
    if (saved == true) {
      final double? qty =
          double.tryParse(qtyCtrl.text.trim().replaceAll(',', '.'));
      final double? price =
          double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
      if (qty != null && qty > 0 && price != null && price >= 0) {
        setState(() {
          _items[index] = TempReceiptItem(
            name: nameCtrl.text.trim().isEmpty
                ? current.name
                : nameCtrl.text.trim(),
            quantity: qty,
            price: price,
          );
        });
      }
    }
  }

  Future<void> _addItem() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController qtyCtrl = TextEditingController(text: '1');
    final TextEditingController priceCtrl = TextEditingController(text: '0.00');

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Новая позиция'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Название', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Количество', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Цена', isDense: true),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final double? qty =
          double.tryParse(qtyCtrl.text.trim().replaceAll(',', '.'));
      final double? price =
          double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
      final String name = nameCtrl.text.trim();
      if (name.isNotEmpty &&
          qty != null &&
          qty > 0 &&
          price != null &&
          price >= 0) {
        setState(() {
          _items.add(TempReceiptItem(name: name, quantity: qty, price: price));
        });
      }
    }
  }

  void _onAddPressed() {
    if (_currencyCode == null || _currencyCode!.isEmpty) {
      _errorText.value = 'Выберите валюту';
      return;
    }
    final String merchant = _merchantController.text.trim().isEmpty
        ? 'Без названия'
        : _merchantController.text.trim();
    final ReceiptAddResult result = ReceiptAddResult(
      merchantName: merchant,
      items: _items,
    );
    developer.log('submit with currency: ${_currencyCode}', name: 'receipt');
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 80,
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: GestureDetector(
                      onTap: _onPickImagePressed,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.12),
                          ),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isAnalyzing,
                          builder: (
                            BuildContext context,
                            bool analyzing,
                            Widget? _,
                          ) {
                            return Stack(
                              children: <Widget>[
                                if (_imageBytes != null && !analyzing)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: GestureDetector(
                                      onTap: _showImagePreview,
                                      child: Hero(
                                        tag: 'receipt_preview',
                                        child: Image.memory(
                                          _imageBytes!,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            BuildContext context,
                                            Object error,
                                            StackTrace? stackTrace,
                                          ) =>
                                              const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Center(
                                    child: analyzing
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.add, size: 28),
                                  ),
                                if (_imageBytes != null || analyzing)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Material(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.54),
                                      shape: const CircleBorder(),
                                      child: GestureDetector(
                                        onTap: _cancelImageAndAnalysis,
                                        child: const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Icon(Icons.close,
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 84),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: SizedBox(
                        height: 56,
                        child: TextField(
                          controller: _merchantController,
                          textInputAction: TextInputAction.done,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            labelText: 'Название магазина',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _urlController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Вставьте URL веб-чека',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<bool>(
                valueListenable: _isAnalyzing,
                builder: (BuildContext context, bool analyzing, Widget? _) {
                  return ElevatedButton(
                    onPressed: analyzing ? null : _runAnalyzeByUrl,
                    child: const Text('Анализ'),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // селект валюты перенесён в строку итога
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ValueListenableBuilder<String?>(
            valueListenable: _errorText,
            builder: (BuildContext context, String? err, Widget? _) {
              if (err == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText.rich(
                  TextSpan(
                    text: err,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Товары',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Добавить позицию'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _items.isEmpty
                      ? const _EmptyListPlaceholder()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final TempReceiptItem it = _items[index];
                            return Dismissible(
                              key: ValueKey<String>('item_${it.name}_$index'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) {
                                setState(() {
                                  _items.removeAt(index);
                                });
                              },
                              child: ListTile(
                                dense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                title: Text(
                                    '${_formatQty(it.quantity)} × ${it.name}'),
                                subtitle: const SizedBox.shrink(),
                                onTap: () => _editItem(index),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text('${it.total.toStringAsFixed(2)} ₽'),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _editItem(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Позиций: ${_items.length}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'Итого: ${_totalAmountString()} ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: _openCurrencyMenu,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(52, 32),
                  ),
                  child: Text(
                    _currencyCode == null || _currencyCode!.isEmpty
                        ? 'валюта'
                        : _currencyCode!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onAddPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Добавить'),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final Widget content = SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: body,
      ),
    );

    return Material(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.9),
        child: content,
      ),
    );
  }
}

class _EmptyListPlaceholder extends StatelessWidget {
  const _EmptyListPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.receipt_long,
            size: 48,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.26),
          ),
          const SizedBox(height: 8),
          Text(
            'Список товаров пуст. Загрузите изображение чека.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.54),
                ),
          ),
        ],
      ),
    );
  }
}
