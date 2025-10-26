import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/receipt_wizard_state.dart';
import '../models/receipt_item.dart';
import '../providers/receipt_wizard_provider.dart';
import '../widgets/receipt_wizard/image_preview_modal.dart';
import 'currency_picker_page.dart';
import 'receipt_wizard/edit_item_step.dart';

/// Полноценный wizard для добавления чека с несколькими шагами
class ReceiptWizardPage extends ConsumerStatefulWidget {
  const ReceiptWizardPage({
    required this.sourceType,
    super.key,
  });

  final ReceiptSourceType sourceType;

  @override
  ConsumerState<ReceiptWizardPage> createState() => _ReceiptWizardPageState();
}

class _ReceiptWizardPageState extends ConsumerState<ReceiptWizardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(receiptWizardProvider.notifier)
          .initWithSource(widget.sourceType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(receiptWizardProvider);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: _buildStepContent(context, wizardState),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    ReceiptWizardState state,
  ) {
    // Если пользователь отменил выбор фото - закрываем wizard
    if (state.isImagePickCanceled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }

    // Показываем индикатор загрузки во время выбора изображения
    if (state.isPickingImage) {
      return const Center(
        child: CupertinoActivityIndicator(radius: 16),
      );
    }

    switch (state.currentStep) {
      case ReceiptWizardStep.preview:
        return _PreviewStep(
          sourceType: widget.sourceType,
          imageBytes: state.imageBytes,
          imageUrl: state.imageUrl,
          isAnalyzing: state.isAnalyzing,
          isCancelling: state.isCancelling,
          errorText: state.errorText,
          onAnalyze: () async {
            await ref.read(receiptWizardProvider.notifier).analyzeReceipt();
          },
          onCancel: () async {
            // Отменяем анализ если он идет и сразу закрываем окно
            if (state.isAnalyzing) {
              ref.read(receiptWizardProvider.notifier).cancelAnalysis();
            }
            await ref.read(receiptWizardProvider.notifier).cancelAndCleanup();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        );

      case ReceiptWizardStep.result:
        return _ResultStep(
          imageBytes: state.imageBytes,
          merchantName: state.merchantName,
          purchaseDate: state.purchaseDate,
          items: state.items,
          totalAmount: state.totalAmountText ?? '0.00',
          currencyCode: state.currencyCode ?? 'RUB',
          errorText: state.errorText,
          isSaving: state.isSaving,
          onImageTap: state.imageBytes != null
              ? () {
                  Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (context) => ImagePreviewModal(
                        imageBytes: state.imageBytes!,
                      ),
                    ),
                  );
                }
              : null,
          onMerchantNameChanged: (value) {
            ref.read(receiptWizardProvider.notifier).setMerchantName(value);
          },
          onPurchaseDateChanged: (date) {
            ref.read(receiptWizardProvider.notifier).setPurchaseDate(date);
          },
          onCurrencyChanged: (code) {
            ref.read(receiptWizardProvider.notifier).setCurrencyCode(code);
          },
          onEditItem: (index) {
            // Редактирование конкретной позиции
            final item = state.items[index];
            Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (context) => EditItemStep(
                  item: item,
                  onSave: (updatedItem) {
                    ref.read(receiptWizardProvider.notifier).updateItem(
                          index,
                          updatedItem,
                        );
                    Navigator.of(context).pop();
                  },
                  onDelete: () {
                    ref.read(receiptWizardProvider.notifier).removeItem(index);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          },
          onAddItem: () {
            // Добавление новой позиции
            Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (context) => EditItemStep(
                  item: null,
                  onSave: (newItem) {
                    ref.read(receiptWizardProvider.notifier).addItem(newItem);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          },
          onSave: () async {
            await ref.read(receiptWizardProvider.notifier).saveReceipt();
            if (!state.isSaving && state.errorText == null) {
              ref.read(receiptWizardProvider.notifier).clearState();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          onCancel: () async {
            await ref.read(receiptWizardProvider.notifier).cancelAndCleanup();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        );
    }
  }
}

/// Превью изображения/URL и анализ
class _PreviewStep extends ConsumerStatefulWidget {
  const _PreviewStep({
    required this.sourceType,
    required this.imageBytes,
    required this.imageUrl,
    required this.isAnalyzing,
    required this.isCancelling,
    required this.errorText,
    required this.onAnalyze,
    required this.onCancel,
  });

  final ReceiptSourceType sourceType;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final bool isAnalyzing;
  final bool isCancelling;
  final String? errorText;
  final VoidCallback onAnalyze;
  final Future<void> Function() onCancel;

  @override
  ConsumerState<_PreviewStep> createState() => _PreviewStepState();
}

class _PreviewStepState extends ConsumerState<_PreviewStep> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl != null) {
      _urlController.text = widget.imageUrl!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrlMode = widget.sourceType == ReceiptSourceType.url;
    final canAnalyze = isUrlMode
        ? _urlController.text.trim().isNotEmpty
        : widget.imageBytes != null;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              const SizedBox(width: 70), // Balance right button
              const Spacer(),
              Text(
                isUrlMode ? 'Ссылка на чек' : 'Превью',
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.onCancel, // Всегда активна
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: Column(
            children: [
              // Content area - всегда занимает оставшееся пространство
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              // URL input field
                              if (isUrlMode)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Введите ссылку на веб чек',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: CupertinoColors.label
                                              .resolveFrom(context),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      CupertinoTextField(
                                        controller: _urlController,
                                        placeholder:
                                            'https://example.com/receipt.jpg',
                                        keyboardType: TextInputType.url,
                                        autocorrect: false,
                                        enabled: !widget.isAnalyzing,
                                        onChanged: (value) {
                                          setState(() {});
                                          ref
                                              .read(receiptWizardProvider
                                                  .notifier)
                                              .setUrl(value);
                                        },
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemGrey6
                                              .resolveFrom(context),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Image preview - адаптивное
                              if (!isUrlMode && widget.imageBytes != null)
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          maxHeight: 450,
                                        ),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Image.memory(
                                            widget.imageBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Кнопка "Выбрать другое изображение"
                              if (!isUrlMode && widget.imageBytes != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: widget.isAnalyzing
                                        ? null
                                        : () async {
                                            final source = widget.sourceType ==
                                                    ReceiptSourceType.camera
                                                ? ImageSource.camera
                                                : ImageSource.gallery;
                                            await ref
                                                .read(receiptWizardProvider
                                                    .notifier)
                                                .pickImage(source);
                                          },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          widget.sourceType ==
                                                  ReceiptSourceType.camera
                                              ? CupertinoIcons.camera
                                              : CupertinoIcons.photo,
                                          size: 20,
                                          color: widget.isAnalyzing
                                              ? CupertinoColors.systemGrey
                                                  .resolveFrom(context)
                                              : CupertinoColors.systemBlue
                                                  .resolveFrom(context),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.sourceType ==
                                                  ReceiptSourceType.camera
                                              ? 'Сфотографировать заново'
                                              : 'Выбрать другое изображение',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: widget.isAnalyzing
                                                ? CupertinoColors.systemGrey
                                                    .resolveFrom(context)
                                                : CupertinoColors.systemBlue
                                                    .resolveFrom(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Spacer - толкает кнопку вниз
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Error message - всегда фиксирована внизу
              if (widget.errorText != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    widget.errorText!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Analyze button - всегда фиксирована внизу
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: (canAnalyze && !widget.isAnalyzing)
                        ? widget.onAnalyze
                        : null,
                    child: widget.isCancelling
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                              ),
                              SizedBox(width: 8),
                              Text('Отмена анализа...'),
                            ],
                          )
                        : widget.isAnalyzing
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                              )
                            : const Text('Анализировать'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Шаг 3: Результат анализа
class _ResultStep extends StatefulWidget {
  const _ResultStep({
    required this.imageBytes,
    required this.merchantName,
    required this.purchaseDate,
    required this.items,
    required this.totalAmount,
    required this.currencyCode,
    required this.errorText,
    required this.isSaving,
    required this.onImageTap,
    required this.onMerchantNameChanged,
    required this.onPurchaseDateChanged,
    required this.onCurrencyChanged,
    required this.onEditItem,
    required this.onAddItem,
    required this.onSave,
    required this.onCancel,
  });

  final Uint8List? imageBytes;
  final String? merchantName;
  final DateTime? purchaseDate;
  final List<ReceiptItem> items;
  final String totalAmount;
  final String currencyCode;
  final String? errorText;
  final bool isSaving;
  final VoidCallback? onImageTap;
  final ValueChanged<String> onMerchantNameChanged;
  final ValueChanged<DateTime> onPurchaseDateChanged;
  final ValueChanged<String> onCurrencyChanged;
  final Function(int index) onEditItem;
  final VoidCallback onAddItem;
  final VoidCallback onSave;
  final Future<void> Function() onCancel;

  @override
  State<_ResultStep> createState() => _ResultStepState();
}

class _ResultStepState extends State<_ResultStep> with SingleTickerProviderStateMixin {
  late TextEditingController _merchantController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  final GlobalKey _merchantFieldKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _merchantFieldError = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.merchantName ?? '');
    _merchantController.addListener(() {
      widget.onMerchantNameChanged(_merchantController.text);
      if (_merchantFieldError && _merchantController.text.trim().isNotEmpty) {
        setState(() {
          _merchantFieldError = false;
        });
      }
    });

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

  @override
  void dispose() {
    _merchantController.dispose();
    _shakeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ResultStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.merchantName != oldWidget.merchantName &&
        widget.merchantName != _merchantController.text) {
      _merchantController.text = widget.merchantName ?? '';
    }
  }

  bool _validateFields() {
    if (_merchantController.text.trim().isEmpty) {
      setState(() {
        _merchantFieldError = true;
      });
      
      // Скроллим к полю
      final context = _merchantFieldKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      
      // Встряхиваем поле
      _shakeController.forward(from: 0);
      
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.onCancel,
                child: const Text('Отмена'),
              ),
              const Spacer(),
              Text(
                'Детали чека',
                style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.isSaving 
                    ? null 
                    : () {
                        if (_validateFields()) {
                          widget.onSave();
                        }
                      },
                child: widget.isSaving
                    ? const CupertinoActivityIndicator()
                    : const Text(
                        'Сохранить',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
              // Error message
              if (widget.errorText != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.errorText!,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Photo preview section
              if (widget.imageBytes != null) _buildPhotoSection(context),

              // Receipt details section
              _buildDetailsSection(context),

              // Items section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Позиции',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    Text(
                      '${widget.items.length}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel
                            .resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Items list
              if (widget.items.isEmpty)
                _buildEmptyItemsState(context)
              else
                ..._buildItemsList(context),

                    // Add item button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        onPressed: widget.onAddItem,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.add_circled,
                              color: CupertinoColors.systemBlue.resolveFrom(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Добавить позицию',
                              style: TextStyle(
                                color: CupertinoColors.systemBlue.resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Amount section fixed at bottom
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    top: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: _buildAmountSection(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: widget.onImageTap,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              widget.imageBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merchant name
            Text(
              'Название',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: CupertinoTextField(
                    key: _merchantFieldKey,
                    controller: _merchantController,
                    placeholder: 'Введите название',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                      border: _merchantFieldError
                          ? Border.all(
                              color: CupertinoColors.systemRed,
                              width: 2,
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Purchase date
            Text(
              'Дата покупки',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showDatePicker(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.purchaseDate != null
                          ? DateFormat('dd.MM.yyyy').format(widget.purchaseDate!)
                          : DateFormat('dd.MM.yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.calendar,
                      size: 20,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection(BuildContext context) {
    final total = widget.items.fold(0.0, (sum, item) => sum + item.total);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.systemBlue.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Итого',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
              ],
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (context) => CurrencyPickerPage(
                      selectedCurrency: widget.currencyCode,
                      onCurrencySelected: widget.onCurrencyChanged,
                    ),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.currencyCode,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItemsState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.cart,
            size: 64,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Позиции не найдены',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте товары из чека',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItemsList(BuildContext context) {
    return widget.items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.all(12),
            onPressed: () => widget.onEditItem(index),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (item.categoryName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey5
                                .resolveFrom(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.categoryName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${item.price.toStringAsFixed(2)} ${widget.currencyCode}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 18,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showDatePicker(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: widget.purchaseDate ?? now,
          maximumDate: today,
          onDateTimeChanged: (DateTime newDate) {
            widget.onPurchaseDateChanged(newDate);
          },
        ),
      ),
    );
  }

}
