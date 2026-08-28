import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum IssueCategory {
  pothole,
  garbage,
  streetlight,
  waterLeak,
  damagedSidewalk,
  fallenHazard,
}

enum SeverityLevel {
  critical,
  high,
  medium,
  low,
}

enum ReportStatus {
  reported,
  routed,
  inProgress,
  aiVerified,
  closed,
}

enum UserRole {
  citizen,
  officer,
  fieldWorker,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.officer:
        return 'Municipal Officer';
      case UserRole.fieldWorker:
        return 'Field Worker';
    }
  }
}

class ReportItem {
  final String id;
  final String title;
  final IssueCategory category;
  final SeverityLevel severity;
  final int riskScore; // 0 - 100
  final String department;
  final String locationName;
  final String coordinates;
  final DateTime reportedAt;
  final double slaHoursRemaining;
  final ReportStatus status;
  final String citizenName;
  final String? assignedWorker;
  final double aiConfidence;
  final int yoloDetectionsCount;
  final String? beforeEvidenceNote;
  final String? afterEvidenceNote;
  final double? verificationScore;
  final bool isDuplicateGroup;
  final int duplicateCount;

  const ReportItem({
    required this.id,
    required this.title,
    required this.category,
    required this.severity,
    required this.riskScore,
    required this.department,
    required this.locationName,
    required this.coordinates,
    required this.reportedAt,
    required this.slaHoursRemaining,
    required this.status,
    required this.citizenName,
    this.assignedWorker,
    required this.aiConfidence,
    this.yoloDetectionsCount = 1,
    this.beforeEvidenceNote,
    this.afterEvidenceNote,
    this.verificationScore,
    this.isDuplicateGroup = false,
    this.duplicateCount = 1,
  });

  String get categoryLabel {
    switch (category) {
      case IssueCategory.pothole:
        return 'Pothole';
      case IssueCategory.garbage:
        return 'Garbage Overflow (Phase 2)';
      case IssueCategory.streetlight:
        return 'Broken Streetlight (Phase 2)';
      case IssueCategory.waterLeak:
        return 'Water Pipe Leak (Phase 2)';
      case IssueCategory.damagedSidewalk:
        return 'Damaged Sidewalk (Phase 2)';
      case IssueCategory.fallenHazard:
        return 'Fallen Tree/Hazard (Phase 2)';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case IssueCategory.pothole:
        return Icons.car_crash_outlined;
      case IssueCategory.garbage:
        return Icons.delete_outline_rounded;
      case IssueCategory.streetlight:
        return Icons.lightbulb_outline_rounded;
      case IssueCategory.waterLeak:
        return Icons.water_drop_outlined;
      case IssueCategory.damagedSidewalk:
        return Icons.handyman_outlined;
      case IssueCategory.fallenHazard:
        return Icons.warning_amber_rounded;
    }
  }

  String get statusLabel {
    switch (status) {
      case ReportStatus.reported:
        return 'Reported';
      case ReportStatus.routed:
        return 'Routed';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.aiVerified:
        return 'AI Verified';
      case ReportStatus.closed:
        return 'Closed';
    }
  }

  Color get statusBgColor {
    switch (status) {
      case ReportStatus.reported:
        return AppTheme.slate100;
      case ReportStatus.routed:
        return AppTheme.primaryBlueBg;
      case ReportStatus.inProgress:
        return AppTheme.inProgressIndigoBg;
      case ReportStatus.aiVerified:
      case ReportStatus.closed:
        return AppTheme.verifiedGreenBg;
    }
  }

  Color get statusTextColor {
    switch (status) {
      case ReportStatus.reported:
        return AppTheme.slate700;
      case ReportStatus.routed:
        return AppTheme.primaryBlue;
      case ReportStatus.inProgress:
        return AppTheme.inProgressIndigo;
      case ReportStatus.aiVerified:
      case ReportStatus.closed:
        return AppTheme.verifiedGreen;
    }
  }

  Color get severityColor {
    switch (severity) {
      case SeverityLevel.critical:
        return AppTheme.criticalRed;
      case SeverityLevel.high:
        return AppTheme.warningAmber;
      case SeverityLevel.medium:
        return const Color(0xFFEAB308);
      case SeverityLevel.low:
        return AppTheme.verifiedGreen;
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(reportedAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  // Realistic sample reports - Filtered for Pothole-first Interactive Prototype
  static List<ReportItem> get sampleReports => [
        ReportItem(
          id: 'CV-9402',
          title: 'Deep Asphalt Pothole Cluster (Lane 2)',
          category: IssueCategory.pothole,
          severity: SeverityLevel.critical,
          riskScore: 92,
          department: 'Roads & Infrastructure',
          locationName: 'North Ring Road, Crossroad 4 (Ward 14)',
          coordinates: '28.6139° N, 77.2090° E',
          reportedAt: DateTime.now().subtract(const Duration(minutes: 18)),
          slaHoursRemaining: 3.5,
          status: ReportStatus.inProgress,
          citizenName: 'Dev Sharma',
          assignedWorker: 'Crew Bravo-4 (Lead: R. Verma)',
          aiConfidence: 0.942,
          yoloDetectionsCount: 2,
          beforeEvidenceNote: '2x Potholes detected. Depth >8cm. High traffic risk.',
          isDuplicateGroup: true,
          duplicateCount: 3,
        ),
        ReportItem(
          id: 'CV-9385',
          title: 'Main Arterial Pothole Patch Repair',
          category: IssueCategory.pothole,
          severity: SeverityLevel.critical,
          riskScore: 89,
          department: 'Roads & Infrastructure',
          locationName: 'Outer Ring Junction, Pillar 42 (Ward 12)',
          coordinates: '28.6012° N, 77.2001° E',
          reportedAt: DateTime.now().subtract(const Duration(hours: 4)),
          slaHoursRemaining: 0.0,
          status: ReportStatus.aiVerified,
          citizenName: 'Sameer Khan',
          assignedWorker: 'Crew Alpha-1 (Lead: M. Singh)',
          aiConfidence: 0.960,
          yoloDetectionsCount: 1,
          beforeEvidenceNote: 'Severe surface cavity (1.2m diameter).',
          afterEvidenceNote: 'Cold bitumen patch applied and steam-rolled.',
          verificationScore: 0.948,
        ),
        ReportItem(
          id: 'CV-9322',
          title: 'Cracked Pedestrian Pavement Paver Slab',
          category: IssueCategory.pothole, // Using pothole logic for interaction
          severity: SeverityLevel.low,
          riskScore: 32,
          department: 'Roads & Infrastructure',
          locationName: 'Heritage Walkway, Gate 2',
          coordinates: '28.6080° N, 77.2050° E',
          reportedAt: DateTime.now().subtract(const Duration(days: 1)),
          slaHoursRemaining: 42.0,
          status: ReportStatus.closed,
          citizenName: 'Rohit Bansal',
          assignedWorker: 'Masonry Unit 4',
          aiConfidence: 0.890,
          verificationScore: 0.972,
          beforeEvidenceNote: 'Displaced concrete paver blocks.',
          afterEvidenceNote: 'Re-leveled and mortared paver blocks.',
        ),
      ];
}
