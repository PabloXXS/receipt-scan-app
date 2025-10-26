import 'package:flutter/cupertino.dart';

class CurrencyPickerPage extends StatefulWidget {
  const CurrencyPickerPage({
    required this.selectedCurrency,
    required this.onCurrencySelected,
    super.key,
  });

  final String selectedCurrency;
  final ValueChanged<String> onCurrencySelected;

  @override
  State<CurrencyPickerPage> createState() => _CurrencyPickerPageState();
}

class _CurrencyPickerPageState extends State<CurrencyPickerPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Расширенный список валют (отсортирован по коду A-Z)
  static const List<Map<String, String>> _allCurrencies = [
    {'code': 'AED', 'name': 'Дирхам ОАЭ', 'symbol': 'د.إ'},
    {'code': 'AMD', 'name': 'Армянский драм', 'symbol': '֏'},
    {'code': 'ARS', 'name': 'Аргентинский песо', 'symbol': '\$'},
    {'code': 'AUD', 'name': 'Австралийский доллар', 'symbol': 'A\$'},
    {'code': 'AZN', 'name': 'Азербайджанский манат', 'symbol': '₼'},
    {'code': 'BDT', 'name': 'Бангладешская така', 'symbol': '৳'},
    {'code': 'BGN', 'name': 'Болгарский лев', 'symbol': 'лв'},
    {'code': 'BHD', 'name': 'Бахрейнский динар', 'symbol': 'د.ب'},
    {'code': 'BRL', 'name': 'Бразильский реал', 'symbol': 'R\$'},
    {'code': 'BYN', 'name': 'Белорусский рубль', 'symbol': 'Br'},
    {'code': 'CAD', 'name': 'Канадский доллар', 'symbol': 'C\$'},
    {'code': 'CHF', 'name': 'Швейцарский франк', 'symbol': 'CHF'},
    {'code': 'CLP', 'name': 'Чилийский песо', 'symbol': '\$'},
    {'code': 'CNY', 'name': 'Китайский юань', 'symbol': '¥'},
    {'code': 'COP', 'name': 'Колумбийский песо', 'symbol': '\$'},
    {'code': 'CZK', 'name': 'Чешская крона', 'symbol': 'Kč'},
    {'code': 'DKK', 'name': 'Датская крона', 'symbol': 'kr'},
    {'code': 'EGP', 'name': 'Египетский фунт', 'symbol': '£'},
    {'code': 'EUR', 'name': 'Евро', 'symbol': '€'},
    {'code': 'GBP', 'name': 'Фунт стерлингов', 'symbol': '£'},
    {'code': 'GEL', 'name': 'Грузинский лари', 'symbol': '₾'},
    {'code': 'HKD', 'name': 'Гонконгский доллар', 'symbol': 'HK\$'},
    {'code': 'HUF', 'name': 'Венгерский форинт', 'symbol': 'Ft'},
    {'code': 'IDR', 'name': 'Индонезийская рупия', 'symbol': 'Rp'},
    {'code': 'ILS', 'name': 'Израильский шекель', 'symbol': '₪'},
    {'code': 'INR', 'name': 'Индийская рупия', 'symbol': '₹'},
    {'code': 'JOD', 'name': 'Иорданский динар', 'symbol': 'د.ا'},
    {'code': 'JPY', 'name': 'Японская иена', 'symbol': '¥'},
    {'code': 'KGS', 'name': 'Киргизский сом', 'symbol': 'с'},
    {'code': 'KRW', 'name': 'Южнокорейская вона', 'symbol': '₩'},
    {'code': 'KWD', 'name': 'Кувейтский динар', 'symbol': 'د.ك'},
    {'code': 'KZT', 'name': 'Казахстанский тенге', 'symbol': '₸'},
    {'code': 'LKR', 'name': 'Шри-ланкийская рупия', 'symbol': '₨'},
    {'code': 'MDL', 'name': 'Молдавский лей', 'symbol': 'L'},
    {'code': 'MXN', 'name': 'Мексиканский песо', 'symbol': '\$'},
    {'code': 'MYR', 'name': 'Малайзийский ринггит', 'symbol': 'RM'},
    {'code': 'NOK', 'name': 'Норвежская крона', 'symbol': 'kr'},
    {'code': 'NPR', 'name': 'Непальская рупия', 'symbol': '₨'},
    {'code': 'NZD', 'name': 'Новозеландский доллар', 'symbol': 'NZ\$'},
    {'code': 'OMR', 'name': 'Оманский риал', 'symbol': 'ر.ع.'},
    {'code': 'PEN', 'name': 'Перуанский соль', 'symbol': 'S/.'},
    {'code': 'PHP', 'name': 'Филиппинское песо', 'symbol': '₱'},
    {'code': 'PKR', 'name': 'Пакистанская рупия', 'symbol': '₨'},
    {'code': 'PLN', 'name': 'Польский злотый', 'symbol': 'zł'},
    {'code': 'QAR', 'name': 'Катарский риал', 'symbol': 'ر.ق'},
    {'code': 'RON', 'name': 'Румынский лей', 'symbol': 'lei'},
    {'code': 'RUB', 'name': 'Российский рубль', 'symbol': '₽'},
    {'code': 'SAR', 'name': 'Саудовский риял', 'symbol': '﷼'},
    {'code': 'SEK', 'name': 'Шведская крона', 'symbol': 'kr'},
    {'code': 'SGD', 'name': 'Сингапурский доллар', 'symbol': 'S\$'},
    {'code': 'THB', 'name': 'Тайский бат', 'symbol': '฿'},
    {'code': 'TJS', 'name': 'Таджикский сомони', 'symbol': 'ЅМ'},
    {'code': 'TMT', 'name': 'Туркменский манат', 'symbol': 'm'},
    {'code': 'TRY', 'name': 'Турецкая лира', 'symbol': '₺'},
    {'code': 'TWD', 'name': 'Новый тайваньский доллар', 'symbol': 'NT\$'},
    {'code': 'UAH', 'name': 'Украинская гривна', 'symbol': '₴'},
    {'code': 'USD', 'name': 'Доллар США', 'symbol': '\$'},
    {'code': 'UZS', 'name': 'Узбекский сум', 'symbol': 'soʻm'},
    {'code': 'VND', 'name': 'Вьетнамский донг', 'symbol': '₫'},
    {'code': 'ZAR', 'name': 'Южноафриканский рэнд', 'symbol': 'R'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredCurrencies {
    if (_searchQuery.isEmpty) {
      return _allCurrencies;
    }
    final query = _searchQuery.toLowerCase();
    return _allCurrencies.where((currency) {
      return currency['code']!.toLowerCase().contains(query) ||
          currency['name']!.toLowerCase().contains(query) ||
          currency['symbol']!.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCurrencies = _filteredCurrencies;

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            CupertinoColors.systemGroupedBackground.resolveFrom(context),
        middle: const Text('Выберите валюту'),
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
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildSearchField(context),
            Expanded(
              child: filteredCurrencies.isEmpty
                  ? _buildNoResultsState(context)
                  : ListView.builder(
                      itemCount: filteredCurrencies.length,
                      itemBuilder: (context, index) {
                        final currency = filteredCurrencies[index];
                        return _buildCurrencyOption(
                          context,
                          currency['code']!,
                          currency['name']!,
                          currency['symbol']!,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: 'Поиск валюты',
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
              'Валюты не найдены',
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

  Widget _buildCurrencyOption(
    BuildContext context,
    String code,
    String name,
    String symbol,
  ) {
    final bool isSelected = widget.selectedCurrency == code;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        widget.onCurrencySelected(code);
        Navigator.of(context).pop();
      },
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
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                symbol,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
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

