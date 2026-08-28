import 'package:flutter/material.dart';
import '../models/report_item.dart';
import '../theme/app_theme.dart';
import 'risk_score_indicator.dart';

class VerificationSheet extends StatelessWidget {
  final ReportItem report;

  const VerificationSheet({
    super.key,
    required this.report,
  });

  static void show(BuildContext context, ReportItem report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VerificationSheet(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.slate300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${report.id}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: AppTheme.slate900,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        RiskScoreIndicator(
                          score: report.riskScore,
                          severity: report.severity,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.categoryLabel,
                      style: const TextStyle(
                        color: AppTheme.slate500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.slate600, size: 20),
                ),
              ],
            ),
          ),

          const Divider(height: 20),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Issue Title & Location
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.slate500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.locationName,
                        style: const TextStyle(color: AppTheme.slate600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // AI Verification Comparison Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: report.verificationScore != null ? AppTheme.verifiedGreenBg : AppTheme.primaryBlueBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: report.verificationScore != null ? AppTheme.verifiedGreenBorder : AppTheme.primaryBlueBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        report.verificationScore != null ? Icons.verified_outlined : Icons.auto_awesome,
                        color: report.verificationScore != null ? AppTheme.verifiedGreen : AppTheme.primaryBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.verificationScore != null
                                  ? 'AI Resolution Verified (${(report.verificationScore! * 100).toStringAsFixed(1)}% Match)'
                                  : 'Active SLA Tracking (${report.slaHoursRemaining}h remaining)',
                              style: TextStyle(
                                color: report.verificationScore != null ? AppTheme.verifiedGreen : AppTheme.primaryBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              report.verificationScore != null
                                  ? 'Comparison CV model confirmed complete issue resolution against original capture coordinates.'
                                  : 'Field team dispatched. Verification required prior to ticket closure.',
                              style: const TextStyle(
                                color: AppTheme.slate600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Before / After Comparison Cards
                const Text(
                  'Visual Evidence Loop (PRD Feature 7)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Before Capture
                    Expanded(
                      child: _buildEvidenceBox(
                        context,
                        title: '1. Incident Capture (Before)',
                        badgeText: 'YOLO Detected',
                        badgeColor: AppTheme.criticalRed,
                        badgeBg: AppTheme.criticalRedBg,
                        notes: report.beforeEvidenceNote ?? 'Initial citizen submission with GPS tag.',
                        icon: Icons.camera_alt_outlined,
                        gradientColor: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // After Capture
                    Expanded(
                      child: _buildEvidenceBox(
                        context,
                        title: '2. Repair Proof (After)',
                        badgeText: report.afterEvidenceNote != null ? 'Verified' : 'Pending',
                        badgeColor: report.afterEvidenceNote != null ? AppTheme.verifiedGreen : AppTheme.slate500,
                        badgeBg: report.afterEvidenceNote != null ? AppTheme.verifiedGreenBg : AppTheme.slate100,
                        notes: report.afterEvidenceNote ?? 'Awaiting field worker upload from site.',
                        icon: report.afterEvidenceNote != null ? Icons.task_alt : Icons.hourglass_empty,
                        gradientColor: report.afterEvidenceNote != null ? const Color(0xFF065F46) : AppTheme.slate400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Metadata & Audit Timeline
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: Column(
                    children: [
                      _buildMetaRow('Assigned Department', report.department),
                      const Divider(height: 16),
                      _buildMetaRow('Reported By', report.citizenName),
                      const Divider(height: 16),
                      _buildMetaRow('Assigned Field Crew', report.assignedWorker ?? 'Auto-routing in progress'),
                      const Divider(height: 16),
                      _buildMetaRow('GPS Coordinates', report.coordinates),
                      const Divider(height: 16),
                      _buildMetaRow('AI Detection Confidence', '${(report.aiConfidence * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: const Text('Share Ticket'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ticket #${report.id} audit confirmed.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Acknowledge'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceBox(
    BuildContext context, {
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required String notes,
    required IconData icon,
    required Color gradientColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulated photo view with CV framing
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: gradientColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 36),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.slate900,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notes,
                  style: const TextStyle(
                    color: AppTheme.slate600,
                    fontSize: 11,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.slate500, fontSize: 12),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppTheme.slate900,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
