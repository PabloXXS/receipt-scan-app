import 'package:flutter/cupertino.dart';

class AddMerchantModal extends StatefulWidget {
  const AddMerchantModal({
    super.key,
    required this.onAdd,
    required this.onCheckDuplicate,
  });

  final Future<void> Function(String) onAdd;
  final Future<bool> Function(String) onCheckDuplicate;

  @override
  State<AddMerchantModal> createState() => _AddMerchantModalState();
}

class _AddMerchantModalState extends State<AddMerchantModal>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
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
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    final String name = _nameController.text.trim();
    
    if (name.isEmpty) {
      _triggerShakeAnimation();
      _focusNode.requestFocus();
      return;
    }

    if (name.length < 2) {
      setState(() {
        _errorText = 'Название должно содержать минимум 2 символа';
      });
      return;
    }

    // Проверка дубликатов
    await _checkDuplicate(name);
  }

  void _triggerShakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  Future<void> _checkDuplicate(String name) async {
    try {
      final isDuplicate = await widget.onCheckDuplicate(name);
      if (isDuplicate) {
        setState(() {
          _errorText = 'Магазин с таким названием уже существует';
        });
        return;
      }
      
      await widget.onAdd(name);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorText = 'Ошибка при создании магазина: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        middle: const Text(
          'Новый магазин',
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
          onPressed: _validateAndSubmit,
          child: const Text(
            'Добавить',
            style: TextStyle(
              color: CupertinoColors.systemBlue,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Заголовок
              Text(
                'Добавить новый магазин',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Введите название магазина для создания новой группы чеков',
                style: TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Поле ввода с анимацией тряски
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: CupertinoTextField(
                      controller: _nameController,
                      focusNode: _focusNode,
                      placeholder: 'Название магазина',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground.resolveFrom(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _errorText != null 
                              ? CupertinoColors.systemRed 
                              : CupertinoColors.systemGrey4,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      onChanged: (String value) {
                        if (_errorText != null) {
                          setState(() {
                            _errorText = null;
                          });
                        }
                      },
                      onSubmitted: (_) => _validateAndSubmit(),
                    ),
                  );
                },
              ),
              // Ошибка
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CupertinoColors.systemRed.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        color: CupertinoColors.systemRed,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
