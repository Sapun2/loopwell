import 'package:flutter/material.dart';

/// Circular progress dial: a track ring, a filled sweep and the percentage
/// centred inside.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    required this.trackColor,
    this.size = 56,
    this.strokeWidth = 5,
    this.textStyle,
  });

  /// 0.0 - 1.0.
  final double value;
  final Color color;
  final Color trackColor;
  final double size;
  final double strokeWidth;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    return Semantics(
      label: '$percent per cent of today\'s habits done',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: clamped,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '$percent%',
              style: textStyle ??
                  TextStyle(
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
