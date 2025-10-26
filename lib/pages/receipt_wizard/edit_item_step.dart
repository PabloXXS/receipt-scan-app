import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/receipt_item.dart';
import '../../models/item_category.dart';
import '../../providers/item_categories_provider.dart';

class EditItemStep extends ConsumerStatefulWidget {
  const EditItemStep({
    required this.item,
    required this.onSave,
    this.onDelete,
    super.key,
  });

  final ReceiptItem? item;
  final ValueChanged<ReceiptItem> onSave;
  final VoidCallback? onDelete;

  @override
  ConsumerState<EditItemStep> createState() => _EditItemStepState();
}

class _EditItemStepState extends ConsumerState<EditItemStep> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  
  final GlobalKey _nameFieldKey = GlobalKey();
  final GlobalKey _priceFieldKey = GlobalKey();
  final GlobalKey _categoryFieldKey = GlobalKey();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  bool _nameError = false;
  bool _categoryError = false;

  String? _selectedCategoryId;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toStringAsFixed(2);
      _selectedCategoryId = widget.item!.categoryId;
      _selectedCategoryName = widget.item!.categoryName;
    }
    
    _nameController.addListener(_clearNameError);
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  void _clearNameError() {
    if (_nameError && _nameController.text.trim().isNotEmpty) {
      setState(() {
        _nameError = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _nameFocusNode.dispose();
    _priceFocusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  bool _validateAndShowErrors() {
    final String name = _nameController.text.trim();
    
    bool hasErrors = false;
    GlobalKey? firstErrorKey;

    // Проверка названия
    if (name.isEmpty) {
      setState(() {
        _nameError = true;
      });
      hasErrors = true;
      firstErrorKey ??= _nameFieldKey;
    }

    // Проверка категории
    if (_selectedCategoryId == null) {
      setState(() {
        _categoryError = true;
      });
      hasErrors = true;
      firstErrorKey ??= _categoryFieldKey;
    }

    if (hasErrors) {
      // Скроллим к первому полю с ошибкой
      if (firstErrorKey?.currentContext != null) {
        Scrollable.ensureVisible(
          firstErrorKey!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      
      // Встряхиваем
      _shakeController.forward(from: 0);
      
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            largeTitle: Text(widget.item != null ? 'Редактировать товар' : 'Новый товар'),
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: const Text(
                  'Отмена',
                  style: TextStyle(
                    color: CupertinoColors.systemBlue,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            trailing: GestureDetector(
              onTap: _saveItem,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(
                    color: CupertinoColors.systemBlue,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildForm(context),
                  const SizedBox(height: 32),
                  _buildInfo(context),
                  if (widget.item != null && widget.onDelete != null) ...[
                    const SizedBox(height: 32),
                    _buildDeleteButton(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Заполните информацию о товаре',
          style: TextStyle(
            fontSize: 17,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNameField(context),
        const SizedBox(height: 24),
        _buildCategoryField(context),
        const SizedBox(height: 24),
        _buildPriceField(context),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Название товара',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: _nameError ? Offset(_shakeAnimation.value, 0) : Offset.zero,
              child: CupertinoTextField(
                key: _nameFieldKey,
                controller: _nameController,
                focusNode: _nameFocusNode,
                placeholder: 'Введите название товара',
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _priceFocusNode.requestFocus(),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                  border: _nameError
                      ? Border.all(
                          color: CupertinoColors.systemRed,
                          width: 2,
                        )
                      : Border.all(
                          color: CupertinoColors.separator.resolveFrom(context),
                        ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Цена',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          key: _priceFieldKey,
          controller: _priceController,
          focusNode: _priceFocusNode,
          placeholder: 'Введите цену',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveItem(),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ],
    );
  }

  Widget _buildCategoryField(BuildContext context) {
    return Column(
      key: _categoryFieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Категория',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: _categoryError ? Offset(_shakeAnimation.value, 0) : Offset.zero,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showCategoryPicker(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
                    border: _categoryError
                        ? Border.all(
                            color: CupertinoColors.systemRed,
                            width: 2,
                          )
                        : Border.all(
                            color: CupertinoColors.separator.resolveFrom(context),
                          ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCategoryName ?? 'Выберите категорию',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedCategoryName != null
                                ? CupertinoColors.label.resolveFrom(context)
                                : CupertinoColors.placeholderText.resolveFrom(
                                    context,
                                  ),
                          ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 20,
                        color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showCategoryPicker(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => _CategoryPickerModal(
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (categoryId, categoryName) {
            setState(() {
              _selectedCategoryId = categoryId;
              _selectedCategoryName = categoryName;
              _categoryError = false;
            });
          },
        ),
      ),
    );
  }


  Widget _buildInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            color: CupertinoColors.systemBlue,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Выберите категорию товара для корректного анализа расходов',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        _showDeleteConfirmation(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.systemRed.resolveFrom(context).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.delete,
              color: CupertinoColors.systemRed.resolveFrom(context),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Удалить позицию',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemRed.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Удалить позицию?'),
        content: Text('Позиция "${widget.item!.name}" будет удалена из чека'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop(); // Закрываем диалог
              widget.onDelete!(); // Вызываем callback удаления (он сам закроет экран)
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _saveItem() {
    if (!_validateAndShowErrors()) {
      return;
    }

    final String name = _nameController.text.trim();
    final String priceText = _priceController.text.trim().replaceAll(',', '.');
    final double price = double.tryParse(priceText) ?? 0.0;
    
    final ReceiptItem item = ReceiptItem(
      id: '', // Временное значение для wizard
      receiptId: '', // Будет установлено при сохранении
      name: name,
      quantity: 1.0, // Всегда 1, так как убрали поле количества
      price: price,
      categoryId: _selectedCategoryId,
      categoryName: _selectedCategoryName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    widget.onSave(item);
    // Удалили Navigator.of(context).pop() - callback onSave сам закроет экран
  }
}

class _CategoryPickerModal extends ConsumerStatefulWidget {
  const _CategoryPickerModal({
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final String? selectedCategoryId;
  final void Function(String? categoryId, String? categoryName)
      onCategorySelected;

  @override
  ConsumerState<_CategoryPickerModal> createState() =>
      _CategoryPickerModalState();
}

class _CategoryPickerModalState extends ConsumerState<_CategoryPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(itemCategoriesProvider);

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            CupertinoColors.systemGroupedBackground.resolveFrom(context),
        middle: const Text('Выберите категорию'),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: const Text(
              'Отмена',
              style: TextStyle(
                color: CupertinoColors.systemBlue,
                fontSize: 17,
              ),
            ),
          ),
        ),
        trailing: GestureDetector(
          onTap: () {
            widget.onCategorySelected(null, null);
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: const Text(
              'Сброс',
              style: TextStyle(
                color: CupertinoColors.systemBlue,
                fontSize: 17,
              ),
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: categoriesAsync.when(
          data: (categories) => _buildContent(context, categories),
          loading: () => const Center(
            child: CupertinoActivityIndicator(),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Ошибка загрузки категорий: $error',
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<ItemCategory> categories) {
    final filteredCategories = categories.where((category) {
      if (_searchQuery.isEmpty) return true;
      return category.name
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        _buildSearchField(context),
        Expanded(
          child: filteredCategories.isEmpty
              ? _buildNoResultsState(context)
              : ListView.builder(
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    final category = filteredCategories[index];
                    return _buildCategoryOption(
                      context,
                      category.id,
                      category.name,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: 'Поиск категории',
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
        ),
        placeholderStyle: TextStyle(
          color: CupertinoColors.placeholderText.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 64,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Категории не найдены',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте другой запрос',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption(
    BuildContext context,
    String categoryId,
    String categoryName,
  ) {
    final bool isSelected = widget.selectedCategoryId == categoryId;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        widget.onCategorySelected(categoryId, categoryName);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                categoryName,
                style: TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.check_mark,
                color: CupertinoColors.systemBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
