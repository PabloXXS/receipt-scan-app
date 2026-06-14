/// Назначение: экран редактирования профиля — имя и аватар.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, flutter_riverpod, image_picker,
///   core/theme/app_tokens.dart, shared/components, data (avatar_image_processor),
///   presentation/controllers/profile_controller.dart.
/// Ключевые типы: EditProfileScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../data/avatar_image_processor.dart';
import '../controllers/profile_controller.dart';

/// Радиус аватара на экране редактирования профиля.
const double _kAvatarRadius = 48;

/// Редактирование имени и аватара текущего пользователя.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(profileControllerProvider).valueOrNull;
    _name = TextEditingController(text: current?.displayName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final raw = await file.readAsBytes();
      final processed = processAvatar(raw);
      await ref
          .read(profileControllerProvider.notifier)
          .updateAvatar(processed);
    } catch (_) {
      _showError('Не удалось обновить аватар');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _busy = true);
    try {
      await ref.read(profileControllerProvider.notifier).removeAvatar();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(profileControllerProvider.notifier)
          .updateName(_name.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _showError('Не удалось сохранить');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileControllerProvider).valueOrNull;

    return AppScaffold(
      title: 'Редактировать профиль',
      body: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: _kAvatarRadius,
                backgroundColor: scheme.primaryContainer,
                foregroundImage: profile?.avatarUrl != null
                    ? NetworkImage(profile!.avatarUrl!)
                    : null,
                child: profile?.avatarUrl == null
                    ? Icon(Icons.person_outline,
                        color: scheme.onPrimaryContainer)
                    : null,
              ),
            ),
            SizedBox(height: tokens.spaceMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  label: 'Сменить фото',
                  variant: AppButtonVariant.secondary,
                  onPressed: _busy ? null : _pickAvatar,
                ),
                SizedBox(width: tokens.spaceSm),
                if (profile?.avatarUrl != null)
                  AppButton(
                    label: 'Удалить',
                    variant: AppButtonVariant.text,
                    onPressed: _busy ? null : _removeAvatar,
                  ),
              ],
            ),
            SizedBox(height: tokens.spaceLg),
            AppTextField(
              label: 'Имя',
              controller: _name,
              prefixIcon: Icons.person_outline,
            ),
            const Spacer(),
            AppButton(
              label: 'Сохранить',
              expanded: true,
              loading: _busy,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
