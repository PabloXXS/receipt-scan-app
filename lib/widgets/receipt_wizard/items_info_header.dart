import 'package:flutter/cupertino.dart';
import '../header_icon_button.dart';
import '../popup_menu_helper.dart';

class ItemsInfoHeader extends StatefulWidget {
  const ItemsInfoHeader({
    required this.itemCount,
    required this.onSortChanged,
    super.key,
  });

  final int itemCount;
  final ValueChanged<String> onSortChanged;

  @override
  State<ItemsInfoHeader> createState() => _ItemsInfoHeaderState();
}

class _ItemsInfoHeaderState extends State<ItemsInfoHeader> {
  String? _selectedSort;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Позиций: ${widget.itemCount}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const Spacer(),
        Builder(
          builder: (BuildContext btnContext) => HeaderIconButton(
            icon: CupertinoIcons.arrow_up_arrow_down,
            onPressed: () => _showSortMenu(btnContext),
          ),
        ),
      ],
    );
  }

  void _showSortMenu(BuildContext buttonContext) {
    PopupMenuHelper.show(
      context: buttonContext,
      menuContent: PopupMenuContainer(
        children: [
          PopupMenuItem(
            icon: CupertinoIcons.arrow_down,
            text: 'Дорогие → Дешевые',
            isSelected: _selectedSort == 'priceHighToLow',
            onTap: () {
              setState(() => _selectedSort = 'priceHighToLow');
              widget.onSortChanged('priceHighToLow');
              Navigator.of(context).pop();
            },
          ),
          PopupMenuItem(
            icon: CupertinoIcons.arrow_up,
            text: 'Дешевые → Дорогие',
            isSelected: _selectedSort == 'priceLowToHigh',
            onTap: () {
              setState(() => _selectedSort = 'priceLowToHigh');
              widget.onSortChanged('priceLowToHigh');
              Navigator.of(context).pop();
            },
          ),
          PopupMenuItem(
            icon: CupertinoIcons.arrow_down,
            text: 'А → Я',
            isSelected: _selectedSort == 'nameAToZ',
            onTap: () {
              setState(() => _selectedSort = 'nameAToZ');
              widget.onSortChanged('nameAToZ');
              Navigator.of(context).pop();
            },
          ),
          PopupMenuItem(
            icon: CupertinoIcons.arrow_up,
            text: 'Я → А',
            isSelected: _selectedSort == 'nameZToA',
            onTap: () {
              setState(() => _selectedSort = 'nameZToA');
              widget.onSortChanged('nameZToA');
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
