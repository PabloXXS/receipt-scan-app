import 'dart:typed_data';
import 'package:flutter/cupertino.dart';

class ImagePreviewModal extends StatelessWidget {
  const ImagePreviewModal({
    required this.imageBytes,
    super.key,
  });

  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: const Icon(
              CupertinoIcons.xmark,
              color: CupertinoColors.white,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

