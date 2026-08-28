import 'package:flutter/material.dart';
import '../models/report_item.dart';
import '../theme/app_theme.dart';
import 'risk_score_indicator.dart';
import 'verification_sheet.dart';

class ReportCard extends StatelessWidget {
  final ReportItem report;
  final VoidCallback? onTap;

  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.slate200, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap ?? () => VerificationSheet.show(context, report),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Ticket ID, Time, Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${report.id}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: AppTheme.slate800,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildSeverityChip(report.severity),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time,
                          size: 11,
                          color: AppTheme.slate400,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          report.timeAgo,
                          style: const TextStyle(
                            color: AppTheme.slate500,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: report.statusBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        report.statusLabel,
                        style: TextStyle(
                          color: report.statusTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Category & Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.slate100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        report.categoryIcon,
                        size: 16,
                        color: AppTheme.slate800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slate900,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: AppTheme.slate400,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  report.locationName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.slate600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (report.isDuplicateGroup) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.slate100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_outlined, size: 12, color: AppTheme.slate600),
                        const SizedBox(width: 4),
                        Text(
                          'Merged Cluster: ${report.duplicateCount} citizen reports (FR2.5)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.slate700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Bottom Meta Row: Risk Score Pill, Department, SLA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Bold Risk Score badge container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: report.severityColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: report.severityColor.withOpacity(0.2), width: 0.8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.analytics_outlined, size: 11, color: report.severityColor),
                              const SizedBox(width: 4),
                              Text(
                                'Risk Score: ${report.riskScore}',
                                style: TextStyle(
                                  color: report.severityColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppTheme.slate100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            report.department.split(' ')[0], // Short department tag
                            style: const TextStyle(
                              color: AppTheme.slate700,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: report.slaHoursRemaining <= 2.0 && report.slaHoursRemaining > 0
                              ? AppTheme.criticalRed
                              : AppTheme.slate400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.slaHoursRemaining > 0
                              ? '${report.slaHoursRemaining.toStringAsFixed(1)}h SLA'
                              : 'Resolved',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: report.slaHoursRemaining <= 2.0 && report.slaHoursRemaining > 0
                                ? AppTheme.criticalRed
                                : AppTheme.slate600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityChip(SeverityLevel level) {
    Color color = AppTheme.slate500;
    Color bg = AppTheme.slate100;
    switch (level) {
      case SeverityLevel.critical:
        color = AppTheme.criticalRed;
        bg = AppTheme.criticalRedBg;
        break;
      case SeverityLevel.high:
        color = AppTheme.warningAmber;
        bg = AppTheme.warningAmberBg;
        break;
      case SeverityLevel.medium:
        color = const Color(0xFFEAB308);
        bg = const Color(0xFFFEF08A).withOpacity(0.2);
        break;
      case SeverityLevel.low:
        color = AppTheme.verifiedGreen;
        bg = AppTheme.verifiedGreenBg;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
