import 'package:flutter/cupertino.dart';

class MerchantConfidenceIndicator extends StatelessWidget {
  final double? confidence;
  final String merchantName;

  const MerchantConfidenceIndicator({
    super.key,
    required this.confidence,
    required this.merchantName,
  });

  @override
  Widget build(BuildContext context) {
    if (confidence == null) {
      return const SizedBox.shrink();
    }

    final confidenceValue = confidence!;
    final confidenceText = _getConfidenceText(confidenceValue);
    final confidenceColor = _getConfidenceColor(confidenceValue, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: confidenceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: confidenceColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getConfidenceIcon(confidenceValue),
            size: 12,
            color: confidenceColor,
          ),
          const SizedBox(width: 4),
          Text(
            confidenceText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: confidenceColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getConfidenceText(double confidence) {
    if (confidence >= 0.9) return 'Высокая';
    if (confidence >= 0.7) return 'Средняя';
    if (confidence >= 0.5) return 'Низкая';
    return 'Неопределено';
  }

  Color _getConfidenceColor(double confidence, BuildContext context) {
    if (confidence >= 0.7) {
      return CupertinoColors.systemGreen.resolveFrom(context);
    } else if (confidence >= 0.5) {
      return CupertinoColors.systemOrange.resolveFrom(context);
    } else {
      return CupertinoColors.systemRed.resolveFrom(context);
    }
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 0.7) {
      return CupertinoIcons.checkmark_circle_fill;
    } else if (confidence >= 0.5) {
      return CupertinoIcons.exclamationmark_triangle_fill;
    } else {
      return CupertinoIcons.xmark_circle_fill;
    }
  }
}
