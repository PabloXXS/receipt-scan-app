import 'package:flutter/cupertino.dart';

class CategoryNameField extends StatefulWidget {
  const CategoryNameField({
    required this.initialValue,
    required this.onChanged,
    required this.onSelectExisting,
    this.onValidate,
    super.key,
  });

  final String? initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onSelectExisting;
  final VoidCallback? onValidate;

  @override
  State<CategoryNameField> createState() => _CategoryNameFieldState();
}

class _CategoryNameFieldState extends State<CategoryNameField>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
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
  void didUpdateWidget(CategoryNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue ?? '';
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

  void validate() {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _hasError = true;
      });
      _triggerShakeAnimation();
      _focusNode.requestFocus();
    } else {
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
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _hasError = true;
      });
      _triggerShakeAnimation();
      _focusNode.requestFocus();
      return false;
    } else {
      setState(() {
        _hasError = false;
      });
      return true;
    }
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
                  placeholder: 'Категория *',
                  onChanged: (value) {
                    widget.onChanged(value);
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
          onPressed: widget.onSelectExisting,
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
                Icon(
                  CupertinoIcons.folder_fill,
                  size: 16,
                  color: CupertinoColors.systemBlue.resolveFrom(context),
                ),
                const SizedBox(width: 6),
                Text(
                  'Выбрать',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemBlue.resolveFrom(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

