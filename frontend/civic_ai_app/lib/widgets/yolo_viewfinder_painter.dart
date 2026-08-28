import 'package:flutter/material.dart';
import '../models/yolo_detection.dart';

class YoloViewfinderPainter extends CustomPainter {
  final List<YoloDetection> detections;
  final bool showGrid;
  final double scanLineOffset; // 0.0 to 1.0 for subtle scan animation

  YoloViewfinderPainter({
    required this.detections,
    this.showGrid = true,
    this.scanLineOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawHudCornerBrackets(canvas, size);

    if (showGrid) {
      _drawSubtleGrid(canvas, size);
    }

    _drawScanTelemetry(canvas, size);

    for (final detection in detections) {
      _drawDetectionBox(canvas, size, detection);
    }
  }

  void _drawHudCornerBrackets(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const double length = 24.0;
    const double inset = 20.0;

    // Top-Left
    canvas.drawLine(const Offset(inset, inset), const Offset(inset + length, inset), paint);
    canvas.drawLine(const Offset(inset, inset), const Offset(inset, inset + length), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width - inset, inset), Offset(size.width - inset - length, inset), paint);
    canvas.drawLine(Offset(size.width - inset, inset), Offset(size.width - inset, inset + length), paint);

    // Bottom-Left
    canvas.drawLine(Offset(inset, size.height - inset), Offset(inset + length, size.height - inset), paint);
    canvas.drawLine(Offset(inset, size.height - inset), Offset(inset, size.height - inset - length), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - inset, size.height - inset), Offset(size.width - inset - length, size.height - inset), paint);
    canvas.drawLine(Offset(size.width - inset, size.height - inset), Offset(size.width - inset, size.height - inset - length), paint);
  }

  void _drawSubtleGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.12)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Center crosshair
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(center.dx - 12, center.dy), Offset(center.dx + 12, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 12), Offset(center.dx, center.dy + 12), paint);

    // Rule of thirds lines
    canvas.drawLine(Offset(size.width / 3, 40), Offset(size.width / 3, size.height - 40), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 40), Offset(2 * size.width / 3, size.height - 40), paint);
    canvas.drawLine(Offset(20, size.height / 3), Offset(size.width - 20, size.height / 3), paint);
    canvas.drawLine(Offset(20, 2 * size.height / 3), Offset(size.width - 20, 2 * size.height / 3), paint);
  }

  void _drawScanTelemetry(Canvas canvas, Size size) {
    // Subtle laser horizontal sweep line
    final scanY = 60 + (size.height - 140) * scanLineOffset;
    final sweepPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(24, scanY), Offset(size.width - 24, scanY), sweepPaint);
  }

  void _drawDetectionBox(Canvas canvas, Size size, YoloDetection detection) {
    final rect = Rect.fromLTWH(
      detection.normalizedRect.left * size.width,
      detection.normalizedRect.top * size.height,
      detection.normalizedRect.width * size.width,
      detection.normalizedRect.height * size.height,
    );

    final boxColor = detection.boxColor;

    // Bounding Box Rect
    final boxPaint = Paint()
      ..color = boxColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), boxPaint);

    // Accent corner brackets on bounding box
    const notch = 10.0;
    final notchPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // TL
    canvas.drawLine(rect.topLeft, Offset(rect.left + notch, rect.top), notchPaint);
    canvas.drawLine(rect.topLeft, Offset(rect.left, rect.top + notch), notchPaint);
    // TR
    canvas.drawLine(rect.topRight, Offset(rect.right - notch, rect.top), notchPaint);
    canvas.drawLine(rect.topRight, Offset(rect.right, rect.top + notch), notchPaint);
    // BL
    canvas.drawLine(rect.bottomLeft, Offset(rect.left + notch, rect.bottom), notchPaint);
    canvas.drawLine(rect.bottomLeft, Offset(rect.left, rect.bottom - notch), notchPaint);
    // BR
    canvas.drawLine(rect.bottomRight, Offset(rect.right - notch, rect.bottom), notchPaint);
    canvas.drawLine(rect.bottomRight, Offset(rect.right, rect.bottom - notch), notchPaint);

    // Top Tag Badge [LABEL • CONFIDENCE]
    final tagText = '${detection.label.toUpperCase()} ${detection.confidencePercentage}';
    final textSpan = TextSpan(
      text: tagText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeWidth = textPainter.width + 14;
    const badgeHeight = 20.0;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, rect.top - badgeHeight - 2, badgeWidth, badgeHeight),
      const Radius.circular(3),
    );

    final badgeBgPaint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(badgeRect, badgeBgPaint);
    textPainter.paint(canvas, Offset(rect.left + 7, rect.top - badgeHeight + 2));

    // Bottom Auxiliary Telemetry (Estimated Area & Latency)
    final subText = 'Area: ~${detection.estimatedAreaSqM}m² | ${detection.inferenceTimeMs}ms';
    final subSpan = TextSpan(
      text: subText,
      style: const TextStyle(
        color: Color(0xFFE2E8F0),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );

    final subPainter = TextPainter(
      text: subSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final subBadgeWidth = subPainter.width + 12;
    const subBadgeHeight = 18.0;
    final subBadgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left, rect.bottom + 4, subBadgeWidth, subBadgeHeight),
      const Radius.circular(3),
    );

    final subBgPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(subBadgeRect, subBgPaint);
    subPainter.paint(canvas, Offset(rect.left + 6, rect.bottom + 6));
  }

  @override
  bool shouldRepaint(covariant YoloViewfinderPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.scanLineOffset != scanLineOffset;
  }
}
