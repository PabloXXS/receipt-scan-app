import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AmountCurrencyField extends StatefulWidget {
  const AmountCurrencyField({
    required this.amount,
    required this.currencyCode,
    required this.onAmountChanged,
    required this.onCurrencyChanged,
    super.key,
  });

  final String amount;
  final String? currencyCode;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String> onCurrencyChanged;

  @override
  State<AmountCurrencyField> createState() => _AmountCurrencyFieldState();
}

class _AmountCurrencyFieldState extends State<AmountCurrencyField>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.amount;
    _controller.addListener(_onTextChanged);
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  @override
  void didUpdateWidget(AmountCurrencyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount != oldWidget.amount) {
      _controller.text = widget.amount;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_hasError && _controller.text.trim().isNotEmpty) {
      setState(() {
        _hasError = false;
      });
    }
  }

  void _triggerShakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  // Публичный метод для валидации извне
  bool validateField() {
    final text = _controller.text.trim();
    
    if (text.isEmpty) {
      setState(() {
        _hasError = true;
      });
      _triggerShakeAnimation();
      _focusNode.requestFocus();
      return false;
    }
    
    setState(() {
      _hasError = false;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: CupertinoTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  placeholder: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (value) {
                    widget.onAmountChanged(value);
                    if (_hasError && value.trim().isNotEmpty) {
                      setState(() {
                        _hasError = false;
                      });
                    }
                  },
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hasError 
                          ? CupertinoColors.systemRed 
                          : CupertinoColors.separator.resolveFrom(context),
                      width: _hasError ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showCurrencyPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.currencyCode ?? 'Валюта',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.currencyCode != null 
                        ? CupertinoColors.label.resolveFrom(context)
                        : CupertinoColors.tertiaryLabel.resolveFrom(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 14,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => _CurrencyPickerModal(
          selectedCurrency: widget.currencyCode,
          onCurrencySelected: widget.onCurrencyChanged,
        ),
      ),
    );
  }

}

class _CurrencyPickerModal extends StatefulWidget {
  const _CurrencyPickerModal({
    required this.selectedCurrency,
    required this.onCurrencySelected,
  });

  final String? selectedCurrency;
  final ValueChanged<String> onCurrencySelected;

  @override
  State<_CurrencyPickerModal> createState() => _CurrencyPickerModalState();
}

class _CurrencyPickerModalState extends State<_CurrencyPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _currencies = [
    {'code': 'RUB', 'name': 'Российский рубль', 'symbol': '₽'},
    {'code': 'BYN', 'name': 'Белорусский рубль', 'symbol': 'Br'},
    {'code': 'USD', 'name': 'Доллар США', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Евро', 'symbol': '€'},
    {'code': 'PLN', 'name': 'Польский злотый', 'symbol': 'zł'},
    {'code': 'UAH', 'name': 'Украинская гривна', 'symbol': '₴'},
    {'code': 'KZT', 'name': 'Казахстанский тенге', 'symbol': '₸'},
    {'code': 'KGS', 'name': 'Киргизский сом', 'symbol': 'с'},
    {'code': 'TJS', 'name': 'Таджикский сомони', 'symbol': 'SM'},
    {'code': 'UZS', 'name': 'Узбекский сум', 'symbol': 'сўм'},
    {'code': 'AMD', 'name': 'Армянский драм', 'symbol': '֏'},
    {'code': 'GEL', 'name': 'Грузинский лари', 'symbol': '₾'},
    {'code': 'AZN', 'name': 'Азербайджанский манат', 'symbol': '₼'},
    {'code': 'MDL', 'name': 'Молдавский лей', 'symbol': 'L'},
    {'code': 'BGN', 'name': 'Болгарский лев', 'symbol': 'лв'},
    {'code': 'RON', 'name': 'Румынский лей', 'symbol': 'lei'},
    {'code': 'HUF', 'name': 'Венгерский форинт', 'symbol': 'Ft'},
    {'code': 'CZK', 'name': 'Чешская крона', 'symbol': 'Kč'},
    {'code': 'SEK', 'name': 'Шведская крона', 'symbol': 'kr'},
    {'code': 'NOK', 'name': 'Норвежская крона', 'symbol': 'kr'},
    {'code': 'DKK', 'name': 'Датская крона', 'symbol': 'kr'},
    {'code': 'CHF', 'name': 'Швейцарский франк', 'symbol': 'CHF'},
    {'code': 'GBP', 'name': 'Британский фунт', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Японская иена', 'symbol': '¥'},
    {'code': 'CNY', 'name': 'Китайский юань', 'symbol': '¥'},
    {'code': 'KRW', 'name': 'Южнокорейская вона', 'symbol': '₩'},
    {'code': 'INR', 'name': 'Индийская рупия', 'symbol': '₹'},
    {'code': 'BRL', 'name': 'Бразильский реал', 'symbol': 'R\$'},
    {'code': 'CAD', 'name': 'Канадский доллар', 'symbol': 'C\$'},
    {'code': 'AUD', 'name': 'Австралийский доллар', 'symbol': 'A\$'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCurrencies = _currencies.where((currency) {
      if (_searchQuery.isEmpty) return true;
      return currency['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             currency['code']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
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
      child: CupertinoTextField(
        controller: _searchController,
        placeholder: 'Поиск валют...',
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(
            CupertinoIcons.search,
            size: 16,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
        ),
        suffix: SizedBox(
          width: 32,
          child: _searchQuery.isNotEmpty
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    size: 16,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(BuildContext context, String code, String name, String symbol) {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                    ],
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

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 64,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Ничего не найдено',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить поисковый запрос',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
