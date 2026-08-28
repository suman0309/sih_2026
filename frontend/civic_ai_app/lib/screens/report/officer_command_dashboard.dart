import 'package:flutter/material.dart';
import '../../models/report_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/risk_score_indicator.dart';

class OfficerCommandDashboard extends StatefulWidget {
  final List<ReportItem> reports;

  const OfficerCommandDashboard({
    super.key,
    required this.reports,
  });

  @override
  State<OfficerCommandDashboard> createState() => _OfficerCommandDashboardState();
}

class _OfficerCommandDashboardState extends State<OfficerCommandDashboard> {
  late List<ReportItem> _localReports;
  ReportItem? _focusedReport;

  @override
  void initState() {
    super.initState();
    _localReports = List.from(widget.reports);
    // Sort initially by risk score descending
    _localReports.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    if (_localReports.isNotEmpty) {
      _focusedReport = _localReports.first;
    }
  }

  // Summary counts
  int get _totalCount => _localReports.length;
  int get _criticalCount => _localReports.where((r) => r.severity == SeverityLevel.critical).length;
  int get _inProgressCount => _localReports.where((r) => r.status == ReportStatus.inProgress).length;
  int get _verifiedCount => _localReports.where((r) => r.status == ReportStatus.aiVerified || r.status == ReportStatus.closed).length;

  void _showAssignWorkerSheet(ReportItem report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Assign Repair Crew — #${report.id}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.slate900),
            ),
            const SizedBox(height: 2),
            const Text(
              'Select municipal team based on hazard classification & SLA urgency',
              style: TextStyle(fontSize: 11, color: AppTheme.slate500),
            ),
            const SizedBox(height: 16),
            
            // Available crews list
            _buildCrewListTile(
              name: 'Crew Alpha-1 (Roads Department)',
              specialty: 'Bitumen and road cavity patching',
              availability: 'ACTIVE • Ward 12 Zone',
              onTap: () => _assignCrew(report, 'Crew Alpha-1 (Lead: M. Singh)'),
            ),
            const Divider(height: 12),
            _buildCrewListTile(
              name: 'Crew Bravo-4 (Emergency Infrastructure)',
              specialty: 'High-severity structural hazards',
              availability: 'ACTIVE • Ward 14 Zone',
              onTap: () => _assignCrew(report, 'Crew Bravo-4 (Lead: R. Verma)'),
            ),
            const Divider(height: 12),
            _buildCrewListTile(
              name: 'Emergency Hydro-Unit 2',
              specialty: 'Pressurized water pipe repairs',
              availability: 'ACTIVE • North Zone',
              onTap: () => _assignCrew(report, 'Emergency Hydro-Unit 2'),
            ),
            const Divider(height: 12),
            _buildCrewListTile(
              name: 'Sanitation Team 3 (Solid Waste)',
              specialty: 'Municipal landfill & garbage overflows',
              availability: 'ACTIVE • Central Zone',
              onTap: () => _assignCrew(report, 'Sanitation Team 3'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCrewListTile({
    required String name,
    required String specialty,
    required String availability,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.slate100,
              child: Icon(Icons.engineering_outlined, size: 18, color: AppTheme.slate700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate800)),
                  Text('$specialty • $availability', style: const TextStyle(fontSize: 10, color: AppTheme.slate500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.slate400),
          ],
        ),
      ),
    );
  }

  void _assignCrew(ReportItem report, String crewName) {
    Navigator.pop(context);
    setState(() {
      final index = _localReports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        final r = _localReports[index];
        _localReports[index] = ReportItem(
          id: r.id,
          title: r.title,
          category: r.category,
          severity: r.severity,
          riskScore: r.riskScore,
          department: r.department,
          locationName: r.locationName,
          coordinates: r.coordinates,
          reportedAt: r.reportedAt,
          slaHoursRemaining: r.slaHoursRemaining,
          status: ReportStatus.inProgress, // Shift status to In Progress on assignment
          citizenName: r.citizenName,
          assignedWorker: crewName,
          aiConfidence: r.aiConfidence,
          beforeEvidenceNote: r.beforeEvidenceNote,
        );
        
        // Update focused report if it was the edited one
        if (_focusedReport?.id == report.id) {
          _focusedReport = _localReports[index];
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dispatched $crewName to Ticket #${report.id}'),
        backgroundColor: AppTheme.slate900,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            if (isMobile) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildKPISection(isMobile: true),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildMapView(height: 260),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildPriorityQueueList(isMobile: true),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            }

            // Tablet / Desktop split screen
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildKPISection(isMobile: false),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                          child: _buildMapView(),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                          child: _buildPriorityQueueList(isMobile: false),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildKPISection({required bool isMobile}) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                _buildKPICard('Total Reports', '$_totalCount', Icons.folder_open_outlined, AppTheme.slate900),
                const SizedBox(width: 8),
                _buildKPICard('Critical Risks', '$_criticalCount', Icons.report_problem_outlined, AppTheme.criticalRed),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildKPICard('In Progress', '$_inProgressCount', Icons.trending_up_rounded, AppTheme.inProgressIndigo),
                const SizedBox(width: 8),
                _buildKPICard('Verified', '$_verifiedCount', Icons.task_alt_outlined, AppTheme.verifiedGreen),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          _buildKPICard('Total Reports', '$_totalCount', Icons.folder_open_outlined, AppTheme.slate900),
          const SizedBox(width: 8),
          _buildKPICard('Critical Risks', '$_criticalCount', Icons.report_problem_outlined, AppTheme.criticalRed),
          const SizedBox(width: 8),
          _buildKPICard('In Progress', '$_inProgressCount', Icons.trending_up_rounded, AppTheme.inProgressIndigo),
          const SizedBox(width: 8),
          _buildKPICard('Verified', '$_verifiedCount', Icons.task_alt_outlined, AppTheme.verifiedGreen),
        ],
      ),
    );
  }

  Widget _buildMapView({double height = 300}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.slate900,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.slate800, width: 1.5),
      ),
      child: Stack(
        children: [
          // Grid backdrop lines to look like technical map
          Positioned.fill(child: _buildMapGridLines()),

          // Map Title banner
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.map, size: 12, color: Colors.white70),
                  SizedBox(width: 6),
                  Text(
                    'GIS HEATMAP PERSPECTIVE',
                    style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),

          // Dynamic pins representing the reports
          ..._buildMapPins(),

          // Map legend
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendRow('Critical Risk', AppTheme.criticalRed),
                  _buildLegendRow('High Risk', AppTheme.warningAmber),
                  _buildLegendRow('Medium Risk', const Color(0xFFEAB308)),
                  _buildLegendRow('Resolved', AppTheme.verifiedGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityQueueList({required bool isMobile}) {
    final listWidget = ListView.builder(
      shrinkWrap: isMobile,
      physics: isMobile ? const NeverScrollableScrollPhysics() : null,
      itemCount: _localReports.length,
      itemBuilder: (context, index) {
        final report = _localReports[index];
        final isFocused = !isMobile && _focusedReport?.id == report.id;

        return Container(
          decoration: BoxDecoration(
            color: isFocused ? AppTheme.slate50 : Colors.transparent,
            border: const Border(bottom: BorderSide(color: AppTheme.slate100)),
          ),
          child: ListTile(
            onTap: () {
              setState(() => _focusedReport = report);
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            title: Row(
              children: [
                Text(
                  '#${report.id}',
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.slate600),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.slate900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Text(report.locationName, style: const TextStyle(fontSize: 10, color: AppTheme.slate500), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    RiskScoreIndicator(score: report.riskScore, severity: report.severity, compact: true),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(color: report.statusBgColor, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          report.statusLabel,
                          style: TextStyle(color: report.statusTextColor, fontSize: 8, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    if (report.assignedWorker != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.engineering_outlined, size: 10, color: AppTheme.slate500),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          report.assignedWorker!.split(' ')[0], // short crew name
                          style: const TextStyle(fontSize: 9, color: AppTheme.slate500, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: () => _showAssignWorkerSheet(report),
                style: ElevatedButton.styleFrom(
                  backgroundColor: report.status == ReportStatus.reported || report.status == ReportStatus.routed 
                      ? AppTheme.slate900 
                      : AppTheme.slate100,
                  foregroundColor: report.status == ReportStatus.reported || report.status == ReportStatus.routed 
                      ? AppTheme.white 
                      : AppTheme.slate700,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  report.assignedWorker == null ? 'Assign' : 'Reassign',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
      },
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // Ranked header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: AppTheme.slate200)),
            ),
            child: const Row(
              children: [
                Icon(Icons.sort_rounded, size: 14, color: AppTheme.slate800),
                SizedBox(width: 8),
                Text(
                  'PRIORITY QUEUE (BY RISK SCORE)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate800, letterSpacing: 0.2),
                ),
              ],
            ),
          ),
          isMobile 
              ? listWidget 
              : Expanded(child: listWidget),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color highlightColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: AppTheme.slate500, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Icon(icon, size: 14, color: AppTheme.slate400),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: highlightColor,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapGridLines() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _MapGridPainter(),
        );
      },
    );
  }

  List<Widget> _buildMapPins() {
    final List<Widget> pins = [];
    if (_localReports.isEmpty) return pins;

    // Hardcode position coordinates relative to canvas for deterministic heatmap layout
    final mockOffsets = [
      const Offset(0.35, 0.28), // CV-9402
      const Offset(0.68, 0.42), // CV-9398
      const Offset(0.18, 0.65), // CV-9385
      const Offset(0.55, 0.72), // CV-9371
      const Offset(0.82, 0.22), // CV-9350
      const Offset(0.42, 0.85), // CV-9322
    ];

    for (int i = 0; i < _localReports.length; i++) {
      if (i >= mockOffsets.length) break;
      final report = _localReports[i];
      final offset = mockOffsets[i];
      final isFocused = _focusedReport?.id == report.id;

      pins.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final x = offset.dx * constraints.maxWidth;
            final y = offset.dy * constraints.maxHeight;

            return Positioned(
              left: x - 12,
              top: y - 12,
              child: GestureDetector(
                onTap: () {
                  setState(() => _focusedReport = report);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isFocused ? 28 : 22,
                    height: isFocused ? 28 : 22,
                    decoration: BoxDecoration(
                      color: report.severityColor.withOpacity(0.24),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFocused ? Colors.white : report.severityColor,
                        width: isFocused ? 2.5 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: report.severityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return pins;
  }

  Widget _buildLegendRow(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final ringPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw technical grid lines
    const int gridRows = 8;
    const int gridCols = 8;

    for (int i = 1; i < gridRows; i++) {
      final y = i * (size.height / gridRows);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (int i = 1; i < gridCols; i++) {
      final x = i * (size.width / gridCols);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Draw mock city zone ring coordinates
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.3, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.15, ringPaint);

    // Subtle outline for city borders mock
    final borderPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..lineTo(size.width * 0.4, size.height * 0.15)
      ..lineTo(size.width * 0.8, size.height * 0.25)
      ..lineTo(size.width * 0.95, size.height * 0.6)
      ..lineTo(size.width * 0.7, size.height * 0.85)
      ..lineTo(size.width * 0.25, size.height * 0.75)
      ..lineTo(size.width * 0.05, size.height * 0.4)
      ..close();

    canvas.drawPath(borderPath, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
