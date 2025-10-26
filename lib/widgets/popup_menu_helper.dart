import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;

/// Универсальный helper для показа popup-меню под кнопкой в iOS-стиле
class PopupMenuHelper {
  static void show({
    required BuildContext context,
    required Widget menuContent,
    double menuWidth = 220,
  }) {
    // Получаем RenderBox кнопки напрямую из context (без GlobalKey!)
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition =
        button.localToGlobal(Offset.zero, ancestor: overlay);
    final Size buttonSize = button.size;

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: CupertinoColors.black.withValues(alpha: 0.3),
        barrierDismissible: true,
        pageBuilder: (BuildContext popupContext, _, __) => _PopupMenuOverlay(
          buttonPosition: buttonPosition,
          buttonSize: buttonSize,
          menuWidth: menuWidth,
          menuContent: menuContent,
        ),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ).drive(Tween<double>(begin: 0.9, end: 1.0)),
              alignment: Alignment.topRight,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _PopupMenuOverlay extends StatelessWidget {
  const _PopupMenuOverlay({
    required this.buttonPosition,
    required this.buttonSize,
    required this.menuWidth,
    required this.menuContent,
  });

  final Offset buttonPosition;
  final Size buttonSize;
  final double menuWidth;
  final Widget menuContent;

  @override
  Widget build(BuildContext context) {
    final double left = buttonPosition.dx + buttonSize.width - menuWidth;
    final double top = buttonPosition.dy + buttonSize.height + 8;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: GestureDetector(
              onTap: () {},
              child: menuContent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Обёртка для содержимого popup-меню в iOS-стиле
class PopupMenuContainer extends StatelessWidget {
  const PopupMenuContainer({
    required this.children,
    this.width = 220,
    super.key,
  });

  final List<Widget> children;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _intersperse(
            children,
            Container(
              height: 0.5,
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> items, Widget separator) {
    if (items.isEmpty) return items;
    
    final List<Widget> result = [];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(separator);
      }
    }
    return result;
  }
}

/// Стандартный элемент popup-меню
class PopupMenuItem extends StatelessWidget {
  const PopupMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.isSelected = false,
    super.key,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.1)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? CupertinoColors.systemBlue.resolveFrom(context)
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected
                      ? CupertinoColors.systemBlue.resolveFrom(context)
                      : CupertinoColors.label.resolveFrom(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark,
                size: 18,
                color: CupertinoColors.systemBlue.resolveFrom(context),
              ),
          ],
        ),
      ),
    );
  }
}

