import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptItem {
  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final int quantity;
  final double price;

  double get total => price * quantity;
}

class ReceiptAddResult {
  ReceiptAddResult({
    required this.merchantName,
    required this.items,
  });

  final String merchantName;
  final List<ReceiptItem> items;

  int get itemsCount => items.length;
  double get totalAmount => items.fold(0.0, (double acc, ReceiptItem i) => acc + i.total);
}

class ReceiptAddSheet extends StatefulWidget {
  const ReceiptAddSheet({
    super.key,
    this.showInlineHeader = false,
    this.constrainHeight = true,
  });

  // Поля оставлены для совместимости hot reload
  final bool showInlineHeader;
  final bool constrainHeight;

  @override
  State<ReceiptAddSheet> createState() => _ReceiptAddSheetState();
}

class _ReceiptAddSheetState extends State<ReceiptAddSheet> {
  final TextEditingController _merchantController = TextEditingController();
  final ValueNotifier<bool> _isAnalyzing = ValueNotifier<bool>(false);
  List<ReceiptItem> _items = <ReceiptItem>[];
  Uint8List? _imageBytes;

  String _totalAmountString() {
    final double sum = _items.fold<double>(
      0.0,
      (double acc, ReceiptItem item) => acc + item.total,
    );
    return sum.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _isAnalyzing.dispose();
    super.dispose();
  }

  Future<void> _mockAnalyzeReceipt() async {
    _isAnalyzing.value = true;
    await Future<void>.delayed(const Duration(seconds: 2));
    // Мок-данные позиций из чека
    _items = <ReceiptItem>[
      ReceiptItem(name: 'Хлеб', quantity: 1, price: 49.90),
      ReceiptItem(name: 'Молоко 1л', quantity: 2, price: 79.50),
      ReceiptItem(name: 'Яйца 10 шт', quantity: 1, price: 129.00),
      ReceiptItem(name: 'Сыр', quantity: 1, price: 249.90),
      ReceiptItem(name: 'Йогурт', quantity: 3, price: 39.90),
      ReceiptItem(name: 'Печенье', quantity: 1, price: 89.00),
      ReceiptItem(name: 'Сок апельсиновый', quantity: 2, price: 119.00),
      ReceiptItem(name: 'Кофе молотый', quantity: 1, price: 349.00),
      ReceiptItem(name: 'Макароны', quantity: 2, price: 59.00),
      ReceiptItem(name: 'Масло сливочное', quantity: 1, price: 219.00),
    ];
    // Автозаполнение названия магазина (мок)
    _merchantController.text = 'Магнит';
    _isAnalyzing.value = false;
    setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? xfile = await picker.pickImage(source: source, imageQuality: 85);
    if (xfile == null) return;
    _imageBytes = await xfile.readAsBytes();
    setState(() {});
    // Запускаем мок-анализ после выбора изображения
    await _mockAnalyzeReceipt();
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

  Future<void> _editItem(int index) async {
    final ReceiptItem current = _items[index];
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
                keyboardType: TextInputType.number,
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
      final int? qty = int.tryParse(qtyCtrl.text.trim());
      final double? price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
      if (qty != null && qty > 0 && price != null && price >= 0) {
        setState(() {
          _items[index] = ReceiptItem(
            name: nameCtrl.text.trim().isEmpty ? current.name : nameCtrl.text.trim(),
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
              decoration: const InputDecoration(labelText: 'Название', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Количество', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Цена', isDense: true),
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
      final int? qty = int.tryParse(qtyCtrl.text.trim());
      final double? price = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
      final String name = nameCtrl.text.trim();
      if (name.isNotEmpty && qty != null && qty > 0 && price != null && price >= 0) {
        setState(() {
          _items.add(ReceiptItem(name: name, quantity: qty, price: price));
        });
      }
    }
  }

  void _onAddPressed() {
    final String merchant = _merchantController.text.trim().isEmpty
        ? 'Без названия'
        : _merchantController.text.trim();
    final ReceiptAddResult result = ReceiptAddResult(
      merchantName: merchant,
      items: _items,
    );
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
                    child: InkWell(
                      onTap: _onPickImagePressed,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                          color: Colors.grey.shade200,
                        ),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isAnalyzing,
                          builder: (
                            BuildContext context,
                            bool analyzing,
                            Widget? _,
                          ) {
                            if (_imageBytes != null && !analyzing) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _imageBytes!,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) => const Icon(Icons.broken_image),
                                ),
                              );
                            }
                            return Center(
                              child: analyzing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add, size: 28),
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
                            final ReceiptItem it = _items[index];
                            return Dismissible(
                              key: ValueKey<String>('item_${it.name}_$index'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) {
                                setState(() {
                                  _items.removeAt(index);
                                });
                              },
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                title: Text('${it.quantity} × ${it.name}'),
                                subtitle: Text('по ${it.price.toStringAsFixed(2)} ₽'),
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
                'Итого: ${_totalAmountString()} ₽',
                style: const TextStyle(fontWeight: FontWeight.w700),
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

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height * 0.9),
      child: content,
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
          Icon(Icons.receipt_long, size: 48, color: Colors.black26),
          const SizedBox(height: 8),
          Text(
            'Список товаров пуст. Загрузите изображение чека.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}


