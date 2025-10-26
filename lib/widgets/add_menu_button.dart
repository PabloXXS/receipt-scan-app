import 'package:flutter/cupertino.dart';

class AddMenuButton extends StatelessWidget {
  const AddMenuButton({
    super.key,
    required this.onAddReceipt,
    required this.onAddMerchant,
  });

  final VoidCallback onAddReceipt;
  final VoidCallback onAddMerchant; // onAddCategory

  void _showMenu(BuildContext context) {
    // Получаем позицию кнопки для показа меню под ней
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition =
        button.localToGlobal(Offset.zero, ancestor: overlay);
    final Size buttonSize = button.size;

    // Используем PageRouteBuilder для кастомной анимации (fade + scale как в CupertinoContextMenu)
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false, // Прозрачный фон
        barrierColor: CupertinoColors.black.withValues(alpha: 0.3),
        barrierDismissible: true, // Закрытие по клику вне меню
        pageBuilder: (BuildContext popupContext, _, __) => _IOSStylePopupMenu(
          buttonPosition: buttonPosition,
          buttonSize: buttonSize,
          onAddReceipt: () {
            Navigator.of(popupContext).pop();
            onAddReceipt();
          },
          onAddCategory: () {
            Navigator.of(popupContext).pop();
            onAddMerchant();
          },
        ),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade + Scale анимация как в CupertinoContextMenu
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
              alignment: Alignment.topRight, // Анимация от позиции меню
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showMenu(context),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          CupertinoIcons.add,
          size: 16,
          color: CupertinoColors.systemBlue,
        ),
      ),
    );
  }
}

class _IOSStylePopupMenu extends StatelessWidget {
  const _IOSStylePopupMenu({
    required this.buttonPosition,
    required this.buttonSize,
    required this.onAddReceipt,
    required this.onAddCategory,
  });

  final Offset buttonPosition;
  final Size buttonSize;
  final VoidCallback onAddReceipt;
  final VoidCallback onAddCategory;

  @override
  Widget build(BuildContext context) {
    // Вычисляем позицию меню под кнопкой
    final double left = buttonPosition.dx + buttonSize.width - 220; // Прижато к правому краю кнопки
    final double top = buttonPosition.dy + buttonSize.height + 8; // 8px отступ вниз

    return GestureDetector(
      // Закрытие при клике вне меню
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Само меню в стиле iOS
          Positioned(
            left: left,
            top: top,
            child: GestureDetector(
              // Предотвращаем закрытие при клике на меню
              onTap: () {},
              child: Container(
                width: 220,
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
                    children: [
                      _PopupMenuItem(
                        icon: CupertinoIcons.doc_text,
                        text: 'Добавить чек',
                        onTap: onAddReceipt,
                      ),
                      Container(
                        height: 0.5,
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                      _PopupMenuItem(
                        icon: CupertinoIcons.folder,
                        text: 'Добавить категорию',
                        onTap: onAddCategory,
                      ),
                    ],
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

class _PopupMenuItem extends StatelessWidget {
  const _PopupMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ),
            Icon(
              icon,
              size: 22,
              color: CupertinoColors.systemBlue.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}