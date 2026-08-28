import 'package:flutter/material.dart';
import '../models/report_item.dart';
import '../theme/app_theme.dart';

class RiskScoreIndicator extends StatelessWidget {
  final int score;
  final SeverityLevel severity;
  final bool compact;

  const RiskScoreIndicator({
    super.key,
    required this.score,
    required this.severity,
    this.compact = false,
  });

  Color get _scoreColor {
    if (score >= 85) return AppTheme.criticalRed;
    if (score >= 70) return const Color(0xFFEA580C);
    if (score >= 40) return AppTheme.warningAmber;
    return AppTheme.verifiedGreen;
  }

  Color get _scoreBgColor {
    if (score >= 85) return AppTheme.criticalRedBg;
    if (score >= 70) return const Color(0xFFFFF7ED);
    if (score >= 40) return AppTheme.warningAmberBg;
    return AppTheme.verifiedGreenBg;
  }

  Color get _scoreBorderColor {
    if (score >= 85) return AppTheme.criticalRedBorder;
    if (score >= 70) return const Color(0xFFFED7AA);
    if (score >= 40) return AppTheme.warningAmberBorder;
    return AppTheme.verifiedGreenBorder;
  }

  String get _severityName {
    switch (severity) {
      case SeverityLevel.critical:
        return 'Critical';
      case SeverityLevel.high:
        return 'High';
      case SeverityLevel.medium:
        return 'Moderate';
      case SeverityLevel.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: _scoreBgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _scoreBorderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _scoreColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Risk $score',
              style: TextStyle(
                color: _scoreColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _scoreBgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _scoreBorderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: _scoreColor),
          const SizedBox(width: 6),
          Text(
            'Risk Score: $score/100',
            style: TextStyle(
              color: _scoreColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _scoreColor,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              _severityName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
