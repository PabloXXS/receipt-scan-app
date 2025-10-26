import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';

class CurrencySelector extends StatelessWidget {
  const CurrencySelector({
    required this.selectedCurrency,
    required this.onChanged,
    super.key,
  });

  final String? selectedCurrency;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Валюта',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          onPressed: () => _showCurrencyPicker(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            child: Row(
              children: [
                if (selectedCurrency != null) ...[
                  _buildCurrencyIcon(selectedCurrency!),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    selectedCurrency != null 
                        ? _getCurrencyName(selectedCurrency!)
                        : 'Выберите валюту',
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedCurrency != null 
                          ? CupertinoColors.label.resolveFrom(context)
                          : CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyIcon(String currencyCode) {
    final Currency? currency = CurrencyService().findByCode(currencyCode);
    if (currency == null) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          CupertinoIcons.money_dollar,
          size: 14,
          color: CupertinoColors.label,
        ),
      );
    }

    if (currency.flag == null) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          CupertinoIcons.money_dollar,
          size: 14,
          color: CupertinoColors.label,
        ),
      );
    }

    if (currency.isFlagImage) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            'lib/src/res/${currency.flag!}',
            package: 'currency_picker',
            width: 24,
            height: 24,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          CurrencyUtils.currencyToEmoji(currency),
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  String _getCurrencyName(String currencyCode) {
    final Currency? currency = CurrencyService().findByCode(currencyCode);
    return currency?.name ?? currencyCode;
  }

  void _showCurrencyPicker(BuildContext context) {
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

    showCupertinoModalPopup<void>(
      context: context,
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
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setSt) {
                Widget buildTile(Currency c) {
                  final bool isSelected = (selectedCurrency ?? '') == c.code;
                  Widget leading;
                  if (c.flag == null) {
                    leading = Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        CupertinoIcons.money_dollar,
                        size: 14,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    );
                  } else if (c.isFlagImage) {
                    leading = Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          'lib/src/res/${c.flag!}',
                          package: 'currency_picker',
                          width: 27,
                          height: 27,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  } else {
                    leading = Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          CurrencyUtils.currencyToEmoji(c),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }
                  
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      onChanged(c.code);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? CupertinoColors.systemBlue.withOpacity(0.1)
                            : CupertinoColors.systemBackground.resolveFrom(context),
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.separator.resolveFrom(context),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          leading,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: CupertinoColors.label.resolveFrom(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.code,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              CupertinoIcons.checkmark,
                              size: 18,
                              color: CupertinoColors.systemBlue,
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return CupertinoPageScaffold(
                  backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey4.resolveFrom(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CupertinoTextField(
                          placeholder: 'Поиск валюты',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              CupertinoIcons.search,
                              color: CupertinoColors.systemGrey,
                              size: 16,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6.resolveFrom(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onChanged: (String v) => setSt(() => applyFilter(v)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: [
                            if (query.isEmpty && recommended.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: Text(
                                  'Рекомендуемые',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                  ),
                                ),
                              ),
                              ...recommended.map(buildTile),
                              Container(
                                height: 1,
                                color: CupertinoColors.separator.resolveFrom(context),
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                              ),
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
        );
      },
    );
  }
}
