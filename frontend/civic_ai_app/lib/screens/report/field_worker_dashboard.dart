import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/report_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/risk_score_indicator.dart';

class FieldWorkerDashboard extends StatefulWidget {
  final List<ReportItem> reports;

  const FieldWorkerDashboard({
    super.key,
    required this.reports,
  });

  @override
  State<FieldWorkerDashboard> createState() => _FieldWorkerDashboardState();
}

class _FieldWorkerDashboardState extends State<FieldWorkerDashboard> {
  ReportItem? _selectedReport;
  // Local state tracking for the mock interactive workflow
  int _workflowStep = 0; // 0: Assigned, 1: In Progress, 2: Before Photo Uploaded, 3: After Photo Uploaded, 4: AI Verified (Closed)
  bool _isUploadingBefore = false;
  bool _isUploadingAfter = false;
  bool _isShowingDetailsMobile = false; // Track active detail view on mobile

  List<ReportItem> get _workerJobs {
    // Filter reports for roads or sanitation to act as work orders
    return widget.reports.where((r) => r.status != ReportStatus.closed).toList();
  }

  @override
  void initState() {
    super.initState();
    final jobs = _workerJobs;
    if (jobs.isNotEmpty) {
      _selectedReport = jobs.first;
      _syncWorkflowStep(_selectedReport!);
    }
  }

  void _syncWorkflowStep(ReportItem report) {
    if (report.status == ReportStatus.reported || report.status == ReportStatus.routed) {
      _workflowStep = 0; // Assigned
    } else if (report.status == ReportStatus.inProgress) {
      _workflowStep = 1; // In Progress
    } else if (report.status == ReportStatus.aiVerified) {
      _workflowStep = 4; // AI Verified
    } else {
      _workflowStep = 1;
    }
  }

  void _selectReport(ReportItem report) {
    setState(() {
      _selectedReport = report;
      _syncWorkflowStep(report);
      _isUploadingBefore = false;
      _isUploadingAfter = false;
      _isShowingDetailsMobile = true;
    });
  }

  void _advanceTimeline() {
    setState(() {
      if (_workflowStep < 4) {
        _workflowStep++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _workerJobs;

    if (jobs.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.slate50,
        body: Center(
          child: Text('No active work orders assigned to your crew.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Interactive Pothole Repair Queue', style: TextStyle(fontSize: 16)),
        backgroundColor: AppTheme.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            if (isMobile) {
              if (_isShowingDetailsMobile && _selectedReport != null) {
                return _buildDetailsPane(_selectedReport!, isMobile: true);
              } else {
                return _buildJobsList(jobs, isMobile: true);
              }
            }

            // Tablet / Desktop side-by-side split screen
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildJobsList(jobs, isMobile: false),
                ),
                Container(width: 1, color: AppTheme.slate200),
                Expanded(
                  flex: 7,
                  child: _buildDetailsPane(_selectedReport ?? jobs.first, isMobile: false),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildJobsList(List<ReportItem> jobs, {required bool isMobile}) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final isSelected = !isMobile && _selectedReport?.id == job.id;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlueBg : AppTheme.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.slate200,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: ListTile(
            onTap: () => _selectReport(job),
            title: Row(
              children: [
                Text(
                  '#${job.id}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.slate800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.categoryLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(job.locationName, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    RiskScoreIndicator(score: job.riskScore, severity: job.severity, compact: true),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _buildBadge(job.statusLabel, job.statusTextColor, job.statusBgColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsPane(ReportItem job, {required bool isMobile}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        if (isMobile) ...[
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.slate800),
                onPressed: () {
                  setState(() {
                    _isShowingDetailsMobile = false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  'Back to Queue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.slate900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        // Card Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Work Order #${job.id}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _buildBadge(
                _getWorkflowStepLabel(),
                _getWorkflowStepColor(),
                _getWorkflowStepColor().withOpacity(0.08),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          job.title,
          style: const TextStyle(fontSize: 13, color: AppTheme.slate600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),

        const Divider(),
        const SizedBox(height: 12),

        // Job Location Info
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.slate400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                job.locationName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            'GPS: ${job.coordinates} • Location captured',
            style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 20),

        // Visual Status Timeline Section
        const Text(
          'Repair Progress Timeline',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate900),
        ),
        const SizedBox(height: 16),
        _buildTimelineProgress(),

        const SizedBox(height: 24),

        // Action Buttons Section
        const Text(
          'Required Site Actions',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate900),
        ),
        const SizedBox(height: 10),
        _buildWorkflowActionsBlock(),
        
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Actions simulate visual timeline steps for mock demonstration.',
            style: TextStyle(fontSize: 10, color: AppTheme.slate400, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBadge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildTimelineProgress() {
    final steps = ['Assigned', 'In Progress', 'Repair Uploaded', 'AI Verification'];
    
    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = _workflowStep > index;
        final isActive = _workflowStep == index;
        
        Color dotColor = AppTheme.slate300;
        if (isCompleted) {
          dotColor = AppTheme.verifiedGreen;
        } else if (isActive) {
          dotColor = AppTheme.primaryBlue;
        }
        
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column for the dots and lines
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: dotColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: dotColor, width: 2),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 10, color: AppTheme.verifiedGreen)
                          : Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.primaryBlue : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isCompleted ? AppTheme.verifiedGreen : AppTheme.slate200,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Text Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w500,
                          color: isActive 
                              ? AppTheme.primaryBlue 
                              : (isCompleted ? AppTheme.slate800 : AppTheme.slate400),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getStepSubtext(index),
                        style: const TextStyle(fontSize: 10, color: AppTheme.slate500),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _getStepSubtext(int index) {
    switch (index) {
      case 0:
        return 'SLA timer started. Crew dispatched.';
      case 1:
        return 'Technician arrived on site. Repairs active.';
      case 2:
        return 'Bitumen/surface patching applied. Verification upload sent.';
      case 3:
        return 'AI comparison models running. Final verification pending.';
      default:
        return '';
    }
  }

  Widget _buildWorkflowActionsBlock() {
    return Column(
      children: [
        // Step 1: Accept Task
        _buildActionRow(
          label: '1. Accept Work Order',
          buttonText: 'Accept Job',
          icon: Icons.assignment_turned_in_outlined,
          isActive: _workflowStep == 0,
          onPressed: () {
            _advanceTimeline();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Job accepted! Status updated to In Progress.'), behavior: SnackBarBehavior.floating),
            );
          },
        ),
        const SizedBox(height: 10),

        // Step 2: Start Work
        _buildActionRow(
          label: '2. Commence Repair',
          buttonText: 'Start Repair Work',
          icon: Icons.play_arrow_outlined,
          isActive: _workflowStep == 1,
          onPressed: () {
            _advanceTimeline();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Repair started! Ready to upload before photo.'), behavior: SnackBarBehavior.floating),
            );
          },
        ),
        const SizedBox(height: 10),

        // Step 3: Before Photo
        _buildActionRow(
          label: '3. Upload Site Before Photo',
          buttonText: _isUploadingBefore ? 'Uploading...' : 'Upload Before Photo',
          icon: Icons.add_a_photo_outlined,
          isActive: _workflowStep == 2,
          isLoading: _isUploadingBefore,
          onPressed: () {
            setState(() => _isUploadingBefore = true);
            Timer(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() => _isUploadingBefore = false);
                _advanceTimeline();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Before photo uploaded! Ready to upload after photo.'), behavior: SnackBarBehavior.floating),
                );
              }
            });
          },
        ),
        const SizedBox(height: 10),

        // Step 4: After Photo
        _buildActionRow(
          label: '4. Upload Completed Repair Photo',
          buttonText: _isUploadingAfter ? 'Uploading...' : 'Upload After Photo',
          icon: Icons.camera_alt_outlined,
          isActive: _workflowStep == 3,
          isLoading: _isUploadingAfter,
          onPressed: () {
            setState(() => _isUploadingAfter = true);
            Timer(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() => _isUploadingAfter = false);
                _advanceTimeline();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('After photo uploaded! Ready for AI Verification.'), behavior: SnackBarBehavior.floating),
                );
              }
            });
          },
        ),
        const SizedBox(height: 10),

        // Step 5: Mark Complete & Verify
        _buildActionRow(
          label: '5. AI Inspection & Closure',
          buttonText: 'Mark Complete',
          icon: Icons.check_circle_outline,
          isActive: _workflowStep == 4,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI verification triggered! Ticket resolved successfully.'),
                backgroundColor: AppTheme.verifiedGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required String label,
    required String buttonText,
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? AppTheme.primaryBlue : AppTheme.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? AppTheme.slate900 : AppTheme.slate500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: isActive && !isLoading ? onPressed : null,
              icon: isLoading
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(icon, size: 14),
              label: Text(
                buttonText,
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? AppTheme.slate900 : AppTheme.slate200,
                foregroundColor: isActive ? AppTheme.white : AppTheme.slate400,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWorkflowStepLabel() {
    switch (_workflowStep) {
      case 0:
        return 'Assigned';
      case 1:
        return 'In Progress';
      case 2:
        return 'Before Uploaded';
      case 3:
        return 'Repair Proof Uploaded';
      case 4:
        return 'AI Verification Verified';
      default:
        return 'Unknown';
    }
  }

  Color _getWorkflowStepColor() {
    switch (_workflowStep) {
      case 0:
        return AppTheme.slate500;
      case 1:
        return AppTheme.inProgressIndigo;
      case 2:
      case 3:
        return AppTheme.primaryBlue;
      case 4:
        return AppTheme.verifiedGreen;
      default:
        return AppTheme.slate500;
    }
  }
}
