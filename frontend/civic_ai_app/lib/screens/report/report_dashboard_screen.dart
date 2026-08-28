import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/report_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/report_card.dart';
import 'field_worker_dashboard.dart';
import 'officer_command_dashboard.dart';

class ReportDashboardScreen extends StatefulWidget {
  final UserRole userRole;
  final List<ReportItem> reports;
  final Function(UserRole)? onRoleChanged;

  const ReportDashboardScreen({
    super.key,
    required this.userRole,
    required this.reports,
    this.onRoleChanged,
  });

  @override
  State<ReportDashboardScreen> createState() => _ReportDashboardScreenState();
}

class _ReportDashboardScreenState extends State<ReportDashboardScreen> {
  String _selectedCategoryFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Mock UI state triggers
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReportItem> get _filteredReports {
    return widget.reports.where((item) {
      // For prototype, only potholes are interactive.
      if (item.category != IssueCategory.pothole && _selectedCategoryFilter == 'All') {
        return false;
      }
      
      // Category filter
      if (_selectedCategoryFilter == 'Potholes' && item.category != IssueCategory.pothole) {
        return false;
      }
      if (_selectedCategoryFilter.contains('Sanitation') && item.category != IssueCategory.garbage) {
        return false;
      }
      if (_selectedCategoryFilter.contains('Streetlights') && item.category != IssueCategory.streetlight) {
        return false;
      }
      if (_selectedCategoryFilter.contains('Water') && item.category != IssueCategory.waterLeak) {
        return false;
      }
      if (_selectedCategoryFilter == 'Critical' && item.severity != SeverityLevel.critical) {
        return false;
      }
      if (_selectedCategoryFilter == 'AI Verified' && item.status != ReportStatus.aiVerified && item.status != ReportStatus.closed) {
        return false;
      }

      // Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(q);
        final matchesId = item.id.toLowerCase().contains(q);
        final matchesLoc = item.locationName.toLowerCase().contains(q);
        final matchesDept = item.department.toLowerCase().contains(q);
        return matchesTitle || matchesId || matchesLoc || matchesDept;
      }

      return true;
    }).toList();
  }

  void _triggerMockLoading() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _triggerMockError() {
    setState(() {
      _hasError = true;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Role-based Dashboard Branching
    if (widget.userRole == UserRole.fieldWorker) {
      return Scaffold(
        backgroundColor: AppTheme.slate50,
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Field Work Orders', overflow: TextOverflow.ellipsis),
              Text('Operational queue & verification timeline',
                  style: TextStyle(fontSize: 11, color: AppTheme.slate500, fontWeight: FontWeight.normal),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Switch User Role Perspective',
              icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.slate700),
              onPressed: () => _showRoleSwitchDialog(context),
            ),
          ],
        ),
        body: SafeArea(child: FieldWorkerDashboard(reports: widget.reports)),
      );
    }

    if (widget.userRole == UserRole.officer) {
      return Scaffold(
        backgroundColor: AppTheme.slate50,
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Triage Command Console', overflow: TextOverflow.ellipsis),
              Text('Real-time incident dispatch & GIS routing override',
                  style: TextStyle(fontSize: 11, color: AppTheme.slate500, fontWeight: FontWeight.normal),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Switch User Role Perspective',
              icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.slate700),
              onPressed: () => _showRoleSwitchDialog(context),
            ),
          ],
        ),
        body: SafeArea(child: OfficerCommandDashboard(reports: widget.reports)),
      );
    }

    // 2. Default Citizen Perspective Dashboard
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Flexible(
                  child: Text(
                    'Civic Reports',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.slate100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: Text(
                    widget.userRole.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate700,
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              'Ward 14 - North Zone Jurisdiction',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.slate500,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Mock testing controls
          PopupMenuButton<String>(
            tooltip: 'Trigger UI Mock States',
            icon: const Icon(Icons.build_outlined, color: AppTheme.slate700),
            onSelected: (val) {
              if (val == 'loading') _triggerMockLoading();
              if (val == 'error') _triggerMockError();
              if (val == 'reset') {
                setState(() {
                  _hasError = false;
                  _isLoading = false;
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'loading', child: Text('Trigger Mock Loading')),
              const PopupMenuItem(value: 'error', child: Text('Trigger Mock Error')),
              const PopupMenuItem(value: 'reset', child: Text('Restore Clean Feed')),
            ],
          ),
          IconButton(
            tooltip: 'Switch Role Perspective',
            icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.slate700),
            onPressed: () => _showRoleSwitchDialog(context),
          ),
        ],
      ),
      body: SafeArea(child: _buildCitizenBody()),
    );
  }

  Widget _buildCitizenBody() {
    // Error View State
    if (_hasError) {
      return _buildErrorView();
    }

    final filtered = _filteredReports;
    final int openCount = widget.reports.where((r) => r.status != ReportStatus.closed).length;
    final int criticalCount = widget.reports.where((r) => r.severity == SeverityLevel.critical).length;

    return CustomScrollView(
      slivers: [
        // 1. Operational Summary Metrics
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Row(
                children: [
                  _buildStatMetric('Active Queue', '$openCount', AppTheme.slate900),
                  _buildStatDivider(),
                  _buildStatMetric('Critical Risk', '$criticalCount', AppTheme.criticalRed),
                  _buildStatDivider(),
                  _buildStatMetric('Avg Triage', 'SLA Standard', AppTheme.primaryBlue),
                  _buildStatDivider(),
                  _buildStatMetric('AI Verified', '96.4%', AppTheme.verifiedGreen),
                ],
              ),
            ),
          ),
        ),

        // 2. Search & Search Filter Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by Ticket #ID, street, or hazard type...',
                prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.slate400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),

        // 3. Category Filter Chips (Responsive Layout)
        SliverToBoxAdapter(
          child: _buildFilterChipsContainer(context),
        ),

        // 4. Incident Reports Feed with Mock loading / empty states
        if (_isLoading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSkeletonCard(),
                childCount: 3,
              ),
            ),
          )
        else if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final report = filtered[index];
                  return ReportCard(report: report);
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChipsContainer(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final List<Widget> chips = [
      _buildFilterChip('All'),
      _buildFilterChip('Critical'),
      _buildFilterChip('Potholes'),
      _buildFilterChip('Sanitation (Soon)'),
      _buildFilterChip('Streetlights (Soon)'),
      _buildFilterChip('Water (Soon)'),
      _buildFilterChip('AI Verified'),
    ];

    if (screenWidth > 640) {
      // Grid/wrap chips on wider tablet or landscape screens to prevent horizontal cutoffs
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
      );
    }

    // Scrollable row with side-fades on standard narrow mobile views
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: chips.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: c,
              )).toList(),
            ),
          ),
          // Left Fade indicator
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 24,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppTheme.slate50, AppTheme.slate50.withOpacity(0.0)],
                  ),
                ),
              ),
            ),
          ),
          // Right Fade indicator
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 24,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [AppTheme.slate50, AppTheme.slate50.withOpacity(0.0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 80, height: 14, decoration: BoxDecoration(color: AppTheme.slate100, borderRadius: BorderRadius.circular(3))),
              Container(width: 60, height: 18, decoration: BoxDecoration(color: AppTheme.slate100, borderRadius: BorderRadius.circular(3))),
            ],
          ),
          const SizedBox(height: 14),
          // Title skeleton
          Container(width: double.infinity, height: 16, decoration: BoxDecoration(color: AppTheme.slate100, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 8),
          // Location skeleton
          Container(width: 180, height: 12, decoration: BoxDecoration(color: AppTheme.slate100, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.slate100),
          const SizedBox(height: 12),
          // Bottom row skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 70, height: 20, decoration: BoxDecoration(color: AppTheme.slate100, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Container(width: 50, height: 20, decoration: BoxDecoration(color: AppTheme.slate100, borderRadius: BorderRadius.circular(3))),
                ],
              ),
              Container(width: 50, height: 14, decoration: BoxDecoration(color: AppTheme.slate100, borderRadius: BorderRadius.circular(3))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppTheme.criticalRedBg, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppTheme.criticalRed),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to sync reports database',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'A network error occurred while updating the municipal telemetry stream. Please check connection and try again.',
              style: TextStyle(fontSize: 12, color: AppTheme.slate500, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _triggerMockLoading();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppTheme.slate100, shape: BoxShape.circle),
              child: const Icon(Icons.inbox_outlined, size: 40, color: AppTheme.slate400),
            ),
            const SizedBox(height: 16),
            const Text(
              'No active reports found',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.slate900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting search keywords or category filters, or capture new hazard reports via the AI Scanner tab.',
              style: TextStyle(fontSize: 12, color: AppTheme.slate500, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_selectedCategoryFilter != 'All' || _searchQuery.isNotEmpty)
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategoryFilter = 'All';
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                child: const Text('Reset Queue Filters'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.slate500,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 28,
      width: 1,
      color: AppTheme.slate200,
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategoryFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedCategoryFilter = label);
      },
      selectedColor: AppTheme.slate900,
      backgroundColor: AppTheme.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppTheme.white : AppTheme.slate700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected ? AppTheme.slate900 : AppTheme.slate200,
        ),
      ),
      showCheckmark: false,
    );
  }

  void _showRoleSwitchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Switch User Perspective',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Citizen'),
              subtitle: const Text('Geotagged hazard submissions and status checking'),
              selected: widget.userRole == UserRole.citizen,
              onTap: () {
                Navigator.pop(ctx);
                widget.onRoleChanged?.call(UserRole.citizen);
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Municipal Officer'),
              subtitle: const Text('Operational queue triage, map GIS details, worker assignments'),
              selected: widget.userRole == UserRole.officer,
              onTap: () {
                Navigator.pop(ctx);
                widget.onRoleChanged?.call(UserRole.officer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.engineering_outlined),
              title: const Text('Field Worker'),
              subtitle: const Text('Queue of assigned work orders, status timelines, image proof upload'),
              selected: widget.userRole == UserRole.fieldWorker,
              onTap: () {
                Navigator.pop(ctx);
                widget.onRoleChanged?.call(UserRole.fieldWorker);
              },
            ),
          ],
        ),
      ),
    );
  }
}
