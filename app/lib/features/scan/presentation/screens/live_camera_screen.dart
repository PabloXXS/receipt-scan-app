/// Назначение: живое превью камеры в приложении + съёмка чека для OCR.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: dart:typed_data, flutter, flutter_riverpod, camera,
///   shared/components, core/theme, presentation/controllers/scan_controller.dart.
/// Ключевые типы: LiveCameraScreen.
library;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/scan_controller.dart';

/// Экран живой камеры: превью + затвор. Снимок → recognizePhoto → возврат на скан.
class LiveCameraScreen extends ConsumerStatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  ConsumerState<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends ConsumerState<LiveCameraScreen> {
  CameraController? _controller;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'Камера недоступна. Используйте «Из галереи».');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller =
          CameraController(back, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (e) {
      setState(() =>
          _error = 'Нет доступа к камере (${e.code}). Разрешите в настройках.');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      // Не ждём распознавание: состояние контроллера ведёт ScanScreen после возврата.
      ref.read(scanControllerProvider.notifier).recognizePhoto(bytes);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось сделать снимок. Попробуйте ещё раз.';
          _capturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final controller = _controller;

    final Widget body;
    if (_error != null) {
      body = Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: AppErrorView(message: _error!),
      );
    } else if (controller == null) {
      body = const AppLoader();
    } else {
      body = Stack(
        children: [
          Positioned.fill(child: CameraPreview(controller)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceXl),
              child: AppButton(
                label: 'Снять',
                icon: Icons.camera,
                expanded: true,
                loading: _capturing,
                onPressed: _capturing ? null : _capture,
              ),
            ),
          ),
        ],
      );
    }

    return AppScaffold(title: 'Камера', body: body);
  }
}
