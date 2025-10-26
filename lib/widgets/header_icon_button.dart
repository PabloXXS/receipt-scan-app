import 'package:flutter/cupertino.dart';

/// Универсальная круглая кнопка для header с серой подложкой
/// Используется на странице категорий, в модальных окнах и т.д.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 32,
    this.iconSize = 16,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Icon(
          icon,
          size: iconSize,
          color: CupertinoColors.systemBlue.resolveFrom(context),
        ),
      ),
    );
  }
}

