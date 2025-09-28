import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../widgets/sliver_pull_to_refresh.dart';
import '../widgets/receipt_add_sheet.dart';
import 'dart:math';

// Мок-данные позиций чека
List<ReceiptItem> _mockReceiptItems() => <ReceiptItem>[
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Content(title: 'Список', icon: Icons.list_alt);
  }
}

class _Content extends StatefulWidget {
  const _Content({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  final List<String> _assetPool = <String>[
    'assets/ticket-1.jpg',
    'assets/ticket-2.png',
    'assets/ticket-3.png',
  ];

  final Random _random = Random();

  String _randomAsset() => _assetPool[_random.nextInt(_assetPool.length)];

  late final List<_ItemData> _items = List<_ItemData>.generate(
    10,
    (int i) => _ItemData(
      id: i,
      title: 'Элемент #${i + 1}',
      createdAt: DateTime.now().subtract(Duration(days: i)),
      imageAsset: _randomAsset(),
      items: _mockReceiptItems(),
    ),
  );

  String _query = '';

  List<_ItemData> get _filteredItems => _query.isEmpty
      ? _items
      : _items
          .where((_) => _.title.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  Future<ReceiptAddResult?> _openAddReceipt(BuildContext context) async {
    return showModalBottomSheet<ReceiptAddResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) => const ReceiptAddSheet(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).viewPadding.top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: top + 12, left: 16, right: 16, bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Colors.blue.shade800, Colors.blue.shade600],
            ),
          ),
          child: Row(
            children: <Widget>[
              if (!_isSearching)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _searchFocusNode.requestFocus();
                    });
                  },
                  icon: const Icon(Icons.search, color: Colors.white),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(width: 8),
              Expanded(
                child: _isSearching
                    ? TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (String v) => setState(() => _query = v),
                        textInputAction: TextInputAction.search,
                        cursorColor: Colors.white,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Поиск',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                          isDense: true,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.transparent, width: 0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.transparent, width: 0),
                          ),
                          suffixIcon: (_query.isNotEmpty)
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              _isSearching
                  ? TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        setState(() {
                          _query = '';
                          _isSearching = false;
                        });
                      },
                      child: const Text(
                        'Отмена',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    )
                  : IconButton(
                      onPressed: () async {
                        final ReceiptAddResult? res = await _openAddReceipt(context);
                        if (res != null) {
                          setState(() {
                            final int newId = (_items.isEmpty ? 0 : (_items.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1));
                            _items.insert(
                              0,
                              _ItemData(
                                id: newId,
                                title: res.merchantName,
                                createdAt: DateTime.now(),
                                imageAsset: _randomAsset(),
                                items: res.items,
                              ),
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: SlidableAutoCloseBehavior(
              child: CustomScrollView(
              slivers: <Widget>[
                BluePullToRefresh(
                  backgroundColor: Colors.blue.shade600,
                  topRadius: 0,
                  onRefresh: () async {
                    await Future<void>.delayed(const Duration(milliseconds: 800));
                  },
                ),
                if (_items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyPlaceholder(text: 'Пока нет элементов'),
                  )
                else if (_filteredItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyPlaceholder(
                      text: 'Нет результатов для "${''}"',
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      final _ItemData item = _filteredItems[index];
                      return Slidable(
                        key: ValueKey<int>(item.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.2,
                          children: <Widget>[
                            SlidableAction(
                              onPressed: (BuildContext actionContext) async {
                                final bool ok = await _confirmDelete(context, item.title);
                                if (ok) {
                                  setState(() {
                                    _items.removeWhere((e) => e.id == item.id);
                                  });
                                } else {
                                  Slidable.of(actionContext)?.close();
                                }
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              borderRadius: BorderRadius.zero,
                            ),
                          ],
                        ),
                        child: _ListItem(
                          item: item,
                          onUpdated: (_ItemData updated) {
                            setState(() {
                              final int i = _items.indexWhere((e) => e.id == updated.id);
                              if (i != -1) {
                                _items[i] = updated;
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({required this.item, required this.onUpdated});

  final _ItemData item;
  final void Function(_ItemData updated) onUpdated;

  @override
  Widget build(BuildContext context) {
    final String date = item.createdAt.toString().substring(0, 10);
    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push<_ItemData>(
              MaterialPageRoute<_ItemData>(
                builder: (_) => _DetailPage(item: item),
              ),
            )
            .then((value) {
          if (value != null) onUpdated(value);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                item.imageAsset ?? 'assets/ticket-1.jpg',
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Создан: $date', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _DetailPage extends StatefulWidget {
  const _DetailPage({required this.item});

  final _ItemData item;

  @override
  State<_DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<_DetailPage> {
  late bool _isEditing = false;
  late TextEditingController _titleCtrl;
  late List<ReceiptItem> _items;
  _ItemData? _pendingUpdated;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item.title);
    _items = List<ReceiptItem>.from(widget.item.items ?? _mockReceiptItems());
    _titleCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing) {
      // Выходим из редактирования без сохранения: откатываем локальные изменения
      _titleCtrl.text = widget.item.title;
      _items = List<ReceiptItem>.from(widget.item.items ?? _mockReceiptItems());
    }
    setState(() => _isEditing = !_isEditing);
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
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Название', isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Количество', isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Цена', isDense: true)),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Добавить')),
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

  Future<void> _editItem(int index) async {
    final ReceiptItem current = _items[index];
    final TextEditingController nameCtrl = TextEditingController(text: current.name);
    final TextEditingController qtyCtrl = TextEditingController(text: current.quantity.toString());
    final TextEditingController priceCtrl = TextEditingController(text: current.price.toStringAsFixed(2));
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Редактировать позицию'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Название', isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Количество', isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Цена', isDense: true)),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Сохранить')),
        ],
      ),
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

  void _onSave() {
    setState(() {
      _isEditing = false;
      _pendingUpdated = _ItemData(
        id: widget.item.id,
        title: _titleCtrl.text.trim().isEmpty ? widget.item.title : _titleCtrl.text.trim(),
        createdAt: widget.item.createdAt,
        imageAsset: widget.item.imageAsset,
        items: _items,
      );
    });
  }

  void _onBack() {
    if (_pendingUpdated != null) {
      Navigator.of(context).pop<_ItemData>(_pendingUpdated);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).viewPadding.top;
    final String date = widget.item.createdAt.toString().substring(0, 10);
    final double footerInset = _isEditing ? 0 : 32;
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _isEditing
          ? Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewPadding.bottom + 12,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: <BoxShadow>[
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4)),
                ],
              ),
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Сохранить'),
              ),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(top: top + 12, left: 16, right: 16, bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.blue.shade800, Colors.blue.shade600],
              ),
            ),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: _onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _titleCtrl.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: _toggleEdit,
                  icon: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, footerInset),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        widget.item.imageAsset ?? 'assets/ticket-1.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => const Icon(
                          Icons.broken_image,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            height: 56,
                            child: TextField(
                              controller: _titleCtrl,
                              enabled: _isEditing,
                              maxLines: 1,
                              textInputAction: TextInputAction.done,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: const InputDecoration(
                                labelText: 'Название магазина',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 0),
                          Text('Создан: $date'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text('Товары', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IgnorePointer(
                        ignoring: !_isEditing,
                        child: Opacity(
                          opacity: _isEditing ? 1 : 0,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: _addItem,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Нет отступа между заголовком и списком
                const SizedBox(height: 0),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: _isEditing ? 0 : 0),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final ReceiptItem it = _items[index];
                    return Dismissible(
                      key: ValueKey<String>('detail_item_${it.name}_$index'),
                      direction: _isEditing ? DismissDirection.endToStart : DismissDirection.none,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: _isEditing
                          ? (_) {
                              setState(() {
                                _items.removeAt(index);
                              });
                            }
                          : null,
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        title: _isEditing
                            ? GestureDetector(
                                onTap: () => _editItem(index),
                                child: Text('${it.quantity} × ${it.name}'),
                              )
                            : Text('${it.quantity} × ${it.name}'),
                        subtitle: Text('по ${it.price.toStringAsFixed(2)} ₽'),
                        trailing: Text('${it.total.toStringAsFixed(2)} ₽'),
                        onTap: _isEditing ? () => _editItem(index) : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemData {
  _ItemData({
    required this.id,
    required this.title,
    required this.createdAt,
    this.imageAsset,
    this.items,
  });
  final int id;
  final String title;
  final DateTime createdAt;
  final String? imageAsset;
  final List<ReceiptItem>? items;
}
// Удалены карточки; контент заглушка выше

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final String resolvedText = text == 'Нет результатов для ""'
        ? 'Нет результатов для "${_queryAccessor(context)}"'
        : text;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.inbox_outlined, size: 56, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            resolvedText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

String _queryAccessor(BuildContext context) {
  final _ContentState? state = context.findAncestorStateOfType<_ContentState>();
  return state?._query ?? '';
}

Future<bool> _confirmDelete(BuildContext context, String title) async {
  final bool? res = await showCupertinoDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: const Text('Удалить элемент'),
        content: Text('Действительно удалить "$title"?'),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      );
    },
  );
  return res ?? false;
}


