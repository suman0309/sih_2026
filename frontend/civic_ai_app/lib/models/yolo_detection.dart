import 'package:flutter/material.dart';
import 'report_item.dart';

class YoloDetection {
  final String label;
  final double confidence; // 0.0 - 1.0
  final Rect normalizedRect; // 0.0 to 1.0 relative to camera canvas
  final SeverityLevel severity;
  final double estimatedAreaSqM;
  final int inferenceTimeMs;
  final String description;

  const YoloDetection({
    required this.label,
    required this.confidence,
    required this.normalizedRect,
    required this.severity,
    required this.estimatedAreaSqM,
    required this.inferenceTimeMs,
    required this.description,
  });

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';

  Color get boxColor {
    switch (severity) {
      case SeverityLevel.critical:
        return const Color(0xFFDC2626); // Crisp red
      case SeverityLevel.high:
        return const Color(0xFFEA580C); // Crisp orange
      case SeverityLevel.medium:
        return const Color(0xFFD97706); // Amber
      case SeverityLevel.low:
        return const Color(0xFF059669); // Emerald
    }
  }

  // Pre-configured realistic YOLO detections for live scanner mock
  static List<YoloDetection> get defaultPotholeDetections => [
        const YoloDetection(
          label: 'Pothole (Cluster A)',
          confidence: 0.942,
          normalizedRect: Rect.fromLTWH(0.18, 0.42, 0.64, 0.28),
          severity: SeverityLevel.critical,
          estimatedAreaSqM: 1.45,
          inferenceTimeMs: 14,
          description: 'Cavity depth >7.5cm | Edge deterioration active',
        ),
      ];

  static List<YoloDetection> get multiHazardDetections => [
        const YoloDetection(
          label: 'Pothole #1',
          confidence: 0.958,
          normalizedRect: Rect.fromLTWH(0.12, 0.38, 0.42, 0.24),
          severity: SeverityLevel.critical,
          estimatedAreaSqM: 0.85,
          inferenceTimeMs: 14,
          description: 'Main wheel track impact',
        ),
        const YoloDetection(
          label: 'Road Edge Cavity #2',
          confidence: 0.884,
          normalizedRect: Rect.fromLTWH(0.56, 0.50, 0.36, 0.20),
          severity: SeverityLevel.high,
          estimatedAreaSqM: 0.60,
          inferenceTimeMs: 16,
          description: 'Asphalt crumbling near kerb',
        ),
      ];

  static List<YoloDetection> get garbageDetections => [
        const YoloDetection(
          label: 'Solid Waste Overflow',
          confidence: 0.916,
          normalizedRect: Rect.fromLTWH(0.20, 0.36, 0.60, 0.34),
          severity: SeverityLevel.high,
          estimatedAreaSqM: 3.20,
          inferenceTimeMs: 15,
          description: 'Uncontained bio/plastic waste volume',
        ),
      ];
}
