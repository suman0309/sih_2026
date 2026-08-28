import 'package:flutter/material.dart';
import '../models/report_item.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'camera/camera_detection_screen.dart';
import 'report/report_dashboard_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final UserRole initialRole;

  const MainNavigationShell({
    super.key,
    this.initialRole = UserRole.citizen,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  late UserRole _currentRole;
  late List<ReportItem> _reports;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
    _reports = List.from(ReportItem.sampleReports);
  }

  void _onReportCreated(ReportItem newReport) {
    setState(() {
      _reports.insert(0, newReport);
      _currentIndex = 0; // Jump to Report feed to see the newly submitted report
    });
  }

  void _onRoleChanged(UserRole newRole) {
    setState(() {
      _currentRole = newRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ReportDashboardScreen(
        userRole: _currentRole,
        reports: _reports,
        onRoleChanged: _onRoleChanged,
      ),
      CameraDetectionScreen(
        userRole: _currentRole,
        onReportCreated: _onReportCreated,
      ),
      _buildAccountView(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          border: Border(top: BorderSide(color: AppTheme.slate200, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          elevation: 0,
          backgroundColor: AppTheme.white,
          selectedItemColor: AppTheme.slate900,
          unselectedItemColor: AppTheme.slate400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Reports Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'AI Scanner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune_outlined),
              activeIcon: Icon(Icons.tune),
              label: 'Settings / Role',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountView() {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Platform Profile & System'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.slate900,
                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _roleDisplayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ward 14 • Session: Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.verifiedGreenBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.verifiedGreenBorder),
                  ),
                  child: const Text(
                    'ONLINE',
                    style: TextStyle(
                      color: AppTheme.verifiedGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Role Switcher Section
          const Text(
            'Active User Perspective',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: RadioGroup<UserRole>(
              groupValue: _currentRole,
              onChanged: (val) {
                if (val != null) _onRoleChanged(val);
              },
              child: Column(
                children: [
                  RadioListTile<UserRole>(
                    value: UserRole.citizen,
                    title: const Text('Citizen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Geotagged hazard submissions and status checking', style: TextStyle(fontSize: 12)),
                  ),
                  const Divider(height: 1),
                  RadioListTile<UserRole>(
                    value: UserRole.officer,
                    title: const Text('Municipal Officer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Operational queue triage, map GIS details, worker assignments', style: TextStyle(fontSize: 12)),
                  ),
                  const Divider(height: 1),
                  RadioListTile<UserRole>(
                    value: UserRole.fieldWorker,
                    title: const Text('Field Worker', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Queue of assigned work orders, status timelines, image proof upload', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // PRD Architecture & Telemetry Specs
          const Text(
            'Model & Telemetry Specifications',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: const Column(
              children: [
                _SpecRow(label: 'Detection System', value: 'AI-assisted detection'),
                Divider(height: 16),
                _SpecRow(label: 'Verification System', value: 'Prototype estimate'),
                Divider(height: 16),
                _SpecRow(label: 'Location Accuracy', value: 'Location captured'),
                Divider(height: 16),
                _SpecRow(label: 'Routing SLA', value: 'Standard routing'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout, size: 16, color: AppTheme.criticalRed),
            label: const Text(
              'Sign Out to Login Page',
              style: TextStyle(color: AppTheme.criticalRed),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String get _roleDisplayName {
    switch (_currentRole) {
      case UserRole.citizen:
        return 'Citizen (Dev Sharma)';
      case UserRole.officer:
        return 'Municipal Officer (Badge #8821)';
      case UserRole.fieldWorker:
        return 'Field Worker (Crew Alpha-4)';
    }
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.slate500, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppTheme.slate800, fontWeight: FontWeight.w600, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
