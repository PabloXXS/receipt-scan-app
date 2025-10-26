import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController(text: 'pablovins777@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: '123456');
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorText = 'Заполните все поля';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      // Сначала пытаемся войти
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      setState(() {
        _errorText = 'Ошибка входа: $e';
      });
      print('Login error details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithMagicLink() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorText = 'Введите email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _emailController.text.trim(),
      );
      
      if (mounted) {
        setState(() {
          _errorText = 'Проверьте email для входа по ссылке';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'Ошибка Magic Link: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Вход'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Заголовок
              Text(
                'Добро пожаловать',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Войдите в систему для работы с чеками',
                style: TextStyle(
                  fontSize: 17,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Поле email
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 18),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemGrey4,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              const SizedBox(height: 16),
              // Поле пароля
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Пароль',
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                style: const TextStyle(fontSize: 18),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemGrey4,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              const Spacer(),
              // Кнопка входа на всю ширину
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isLoading ? null : _login,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isLoading 
                          ? CupertinoColors.systemGrey 
                          : CupertinoColors.systemBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text(
                            'Войти',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Кнопка Magic Link
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isLoading ? null : _loginWithMagicLink,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemGrey4,
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Войти через Magic Link',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
