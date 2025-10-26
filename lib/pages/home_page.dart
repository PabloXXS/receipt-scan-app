import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide PopupMenuItem;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt.dart';
import '../models/receipt_wizard_state.dart';
import '../providers/receipts_provider.dart';
import '../providers/receipt_wizard_provider.dart';
import '../widgets/sliver_pull_to_refresh.dart';
import '../widgets/popup_menu_helper.dart';
import 'receipt_wizard_page.dart';
import 'receipt_detail_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _Content(title: 'Чеки');
  }
}

class _Content extends ConsumerStatefulWidget {
  const _Content({required this.title});

  final String title;

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  String _query = '';

  Map<String, List<Receipt>> _groupReceiptsByDate(List<Receipt> receipts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    final Map<String, List<Receipt>> groups = {
      'Сегодня': [],
      'Вчера': [],
      'Этот месяц': [],
      'Ранее': [],
    };

    for (final receipt in receipts) {
      // Фильтр по поиску
      if (_query.isNotEmpty) {
        final searchLower = _query.toLowerCase();
        final merchantName = receipt.merchantName?.toLowerCase() ?? '';
        if (!merchantName.contains(searchLower)) {
          continue;
        }
      }

      final date = receipt.purchaseDate ?? receipt.createdAt;
      final receiptDay = DateTime(date.year, date.month, date.day);

      if (receiptDay.isAtSameMomentAs(today)) {
        groups['Сегодня']!.add(receipt);
      } else if (receiptDay.isAtSameMomentAs(yesterday)) {
        groups['Вчера']!.add(receipt);
      } else if (receiptDay.isAfter(thisMonthStart) ||
          receiptDay.isAtSameMomentAs(thisMonthStart)) {
        groups['Этот месяц']!.add(receipt);
      } else {
        groups['Ранее']!.add(receipt);
      }
    }

    // Убрать пустые группы
    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }

  Future<void> _load() async {
    await ref.read(receiptsProvider.notifier).refresh();
  }

  void _showAddMenu(BuildContext buttonContext) {
    PopupMenuHelper.show(
      context: buttonContext,
      menuContent: PopupMenuContainer(
        children: [
          PopupMenuItem(
            icon: CupertinoIcons.camera,
            text: 'Сфотографировать',
            onTap: () async {
              Navigator.of(context).pop();
              await Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => const ReceiptWizardPage(
                    sourceType: ReceiptSourceType.camera,
                  ),
                ),
              );
              _load();
            },
          ),
          PopupMenuItem(
            icon: CupertinoIcons.photo,
            text: 'Выбрать из галереи',
            onTap: () async {
              Navigator.of(context).pop();
              await Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => const ReceiptWizardPage(
                    sourceType: ReceiptSourceType.gallery,
                  ),
                ),
              );
              _load();
            },
          ),
          PopupMenuItem(
            icon: CupertinoIcons.link,
            text: 'Ссылка на веб чек',
            onTap: () async {
              Navigator.of(context).pop();
              await Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => const ReceiptWizardPage(
                    sourceType: ReceiptSourceType.url,
                  ),
                ),
              );
              _load();
            },
          ),
          PopupMenuItem(
            icon: CupertinoIcons.pencil,
            text: 'Добавить вручную',
            onTap: () async {
              Navigator.of(context).pop();
              ref.read(receiptWizardProvider.notifier).clearState();
              await Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => const ReceiptWizardPage(
                    sourceType: ReceiptSourceType.manual,
                  ),
                ),
              );
              _load();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            CupertinoColors.systemGroupedBackground.resolveFrom(context),
        middle: _isSearching
            ? SizedBox(
                height: 36,
                child: CupertinoTextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (String v) => setState(() => _query = v),
                  placeholder: 'Поиск по магазину',
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      CupertinoIcons.search,
                      color: CupertinoColors.systemGrey,
                      size: 16,
                    ),
                  ),
                  suffix: _searchController.text.isNotEmpty
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          child: const Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: CupertinoColors.systemGrey,
                            size: 16,
                          ),
                        )
                      : null,
                ),
              )
            : Text(widget.title),
        leading: _isSearching
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _searchFocusNode.requestFocus();
                  });
                },
                child: const Icon(
                  CupertinoIcons.search,
                  size: 22,
                  color: CupertinoColors.activeBlue,
                ),
              ),
        trailing: _isSearching
            ? CupertinoButton(
                padding: EdgeInsets.zero,
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
                  style: TextStyle(
                    color: CupertinoColors.systemBlue,
                    fontSize: 17,
                  ),
                ),
              )
                : Builder(
                    builder: (BuildContext btnContext) => CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () => _showAddMenu(btnContext),
                      child: const Icon(
                        CupertinoIcons.add_circled,
                        size: 28,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
      ),
      child: CustomScrollView(
        slivers: <Widget>[
          BluePullToRefresh(
            backgroundColor:
                CupertinoColors.systemGroupedBackground.resolveFrom(context),
            topRadius: 0,
            onRefresh: _load,
          ),
          receiptsAsync.when(
            data: (receipts) {
              if (receipts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    color: CupertinoColors.systemGroupedBackground
                        .resolveFrom(context),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom,
                      ),
                      child: const _EmptyPlaceholder(
                        text: 'Пока нет чеков',
                      ),
                    ),
                  ),
                );
              }

              final groupedReceipts = _groupReceiptsByDate(receipts);

              if (groupedReceipts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    color: CupertinoColors.systemGroupedBackground
                        .resolveFrom(context),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom,
                      ),
                      child: _EmptyPlaceholder(
                        text: 'Нет результатов для "$_query"',
                      ),
                    ),
                  ),
                );
              }

              // Используем SliverList с группировкой
              final sections = groupedReceipts.entries.toList();

              return SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      // Расчет индекса: заголовки и элементы
                      int itemIndex = 0;
                      for (var i = 0; i < sections.length; i++) {
                        final section = sections[i];
                        final sectionSize = 1 + section.value.length;

                        if (index < itemIndex + sectionSize) {
                          final relativeIndex = index - itemIndex;
                          if (relativeIndex == 0) {
                            // Заголовок секции
                            return _SectionHeader(title: section.key);
                          } else {
                            // Элемент чека
                            final receipt = section.value[relativeIndex - 1];
                            return _ReceiptItem(
                              receipt: receipt,
                              onTap: () {
                                Navigator.of(context).push(
                                  CupertinoPageRoute<void>(
                                    builder: (context) => ReceiptDetailPage(
                                      receiptId: receipt.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        }
                        itemIndex += sectionSize;
                      }
                      return null;
                    },
                    childCount: sections.fold<int>(
                      0,
                      (sum, entry) => sum + 1 + entry.value.length,
                    ),
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                color:
                    CupertinoColors.systemGroupedBackground.resolveFrom(context),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: const Center(child: CupertinoActivityIndicator()),
                ),
              ),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                color:
                    CupertinoColors.systemGroupedBackground.resolveFrom(context),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          size: 48,
                          color: CupertinoColors.systemRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки',
                          style: TextStyle(
                            fontSize: 17,
                            color: CupertinoColors.label.resolveFrom(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          '$error',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}

class _ReceiptItem extends StatelessWidget {
  const _ReceiptItem({
    required this.receipt,
    required this.onTap,
  });

  final Receipt receipt;
  final VoidCallback onTap;

  String _formatDate(DateTime date) {
    final months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final date = receipt.purchaseDate ?? receipt.createdAt;
    final merchantName = receipt.merchantName ?? 'Чек';
    final time = receipt.purchaseTime;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
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
          children: <Widget>[
            // Иконка чека
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.doc_text_fill,
                color: CupertinoColors.label.resolveFrom(context),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Основной контент
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    merchantName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time != null
                        ? '${_formatDate(date)} в ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                        : _formatDate(date),
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
            // Сумма и стрелка
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${receipt.total.toStringAsFixed(2)} ₽',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            CupertinoIcons.tray,
            size: 48,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
