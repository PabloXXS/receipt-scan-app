import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Модальное окно для выбора иконки категории
class IconPickerModal extends StatefulWidget {
  const IconPickerModal({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  final String selectedIcon;
  final Function(String) onIconSelected;

  @override
  State<IconPickerModal> createState() => _IconPickerModalState();
}

class _IconPickerModalState extends State<IconPickerModal> {
  late String _selectedIcon;
  final ImagePicker _imagePicker = ImagePicker();
  String? _customImagePath;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.selectedIcon;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _customImagePath = image.path;
          _selectedIcon = 'custom:${image.path}';
        });
      }
    } catch (e) {
      // Показываем ошибку
      if (mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Ошибка'),
            content: Text('Не удалось загрузить изображение: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground
          .resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground
            .resolveFrom(context),
        middle: const Text(
          'Выбор иконки',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Отмена',
            style: TextStyle(
              color: CupertinoColors.systemBlue,
              fontSize: 17,
            ),
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            widget.onIconSelected(_selectedIcon);
            Navigator.of(context).pop();
          },
          child: const Text(
            'Готово',
            style: TextStyle(
              color: CupertinoColors.systemBlue,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: CategoryIcon.availableIcons.length + 1,
            itemBuilder: (context, index) {
              // Кнопка загрузки изображения
              if (index == CategoryIcon.availableIcons.length) {
                final isSelected = _selectedIcon.startsWith('custom:');
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CupertinoColors.systemBlue.resolveFrom(context)
                          : CupertinoColors.systemBackground
                              .resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? CupertinoColors.systemBlue.resolveFrom(context)
                            : CupertinoColors.separator.resolveFrom(context),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_customImagePath != null && isSelected)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_customImagePath!),
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Icon(
                            CupertinoIcons.photo,
                            size: 32,
                            color: isSelected
                                ? CupertinoColors.white
                                : CupertinoColors.label.resolveFrom(context),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Загрузить',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? CupertinoColors.white
                                : CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final categoryIcon = CategoryIcon.availableIcons[index];
              final isSelected = _selectedIcon == categoryIcon.name;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIcon = categoryIcon.name;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CupertinoColors.systemBlue.resolveFrom(context)
                        : CupertinoColors.systemBackground
                            .resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? CupertinoColors.systemBlue.resolveFrom(context)
                          : CupertinoColors.separator.resolveFrom(context),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      categoryIcon.icon,
                      size: 32,
                      color: isSelected
                          ? CupertinoColors.white
                          : CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CategoryIcon {
  final String name;
  final IconData icon;
  final String label;

  const CategoryIcon({
    required this.name,
    required this.icon,
    required this.label,
  });

  // Список типовых иконок для категорий трат (статический)
  static const List<CategoryIcon> availableIcons = [
    CategoryIcon(
      name: 'cart',
      icon: CupertinoIcons.cart_fill,
      label: 'Продукты',
    ),
    CategoryIcon(
      name: 'bag',
      icon: CupertinoIcons.bag_fill,
      label: 'Покупки',
    ),
    CategoryIcon(
      name: 'building',
      icon: CupertinoIcons.building_2_fill,
      label: 'Магазин',
    ),
    CategoryIcon(
      name: 'car',
      icon: CupertinoIcons.car_fill,
      label: 'Транспорт',
    ),
    CategoryIcon(
      name: 'game',
      icon: CupertinoIcons.game_controller_solid,
      label: 'Развлечения',
    ),
    CategoryIcon(
      name: 'sportscourt',
      icon: CupertinoIcons.sportscourt_fill,
      label: 'Спорт',
    ),
    CategoryIcon(
      name: 'house',
      icon: CupertinoIcons.house_fill,
      label: 'Дом',
    ),
    CategoryIcon(
      name: 'airplane',
      icon: CupertinoIcons.airplane,
      label: 'Путешествия',
    ),
    CategoryIcon(
      name: 'heart',
      icon: CupertinoIcons.heart_fill,
      label: 'Здоровье',
    ),
    CategoryIcon(
      name: 'book',
      icon: CupertinoIcons.book_fill,
      label: 'Образование',
    ),
  ];

  static IconData getIconData(String iconName) {
    // Если это пользовательское изображение, возвращаем иконку фото
    if (iconName.startsWith('custom:')) {
      return CupertinoIcons.photo_fill;
    }
    
    final icon = availableIcons.firstWhere(
      (icon) => icon.name == iconName,
      orElse: () => const CategoryIcon(
        name: 'folder',
        icon: CupertinoIcons.folder_fill,
        label: 'Папка',
      ),
    );
    return icon.icon;
  }

  static String getIconLabel(String iconName) {
    // Если это пользовательское изображение
    if (iconName.startsWith('custom:')) {
      return 'Своё изображение';
    }
    
    final icon = availableIcons.firstWhere(
      (icon) => icon.name == iconName,
      orElse: () => const CategoryIcon(
        name: 'folder',
        icon: CupertinoIcons.folder_fill,
        label: 'Папка',
      ),
    );
    return icon.label;
  }
}

