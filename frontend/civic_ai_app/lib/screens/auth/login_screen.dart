import 'package:flutter/material.dart';
import '../../models/report_item.dart';
import '../../theme/app_theme.dart';
import '../main_navigation_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.citizen;
  final TextEditingController _identifierController = TextEditingController(text: '+1 (555) 019-2834');
  final TextEditingController _secretController = TextEditingController(text: '482910');
  String _selectedWard = 'Ward 14 - North Zone';
  String _selectedDepartment = 'Roads & Infrastructure';

  @override
  void dispose() {
    _identifierController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      if (role == UserRole.citizen) {
        _identifierController.text = '+1 (555) 019-2834';
        _secretController.text = '482910';
      } else if (role == UserRole.officer) {
        _identifierController.text = 'OFF-8821-ND';
        _secretController.text = '••••••••••••';
      } else {
        _identifierController.text = 'CREW-BRAVO-4';
        _secretController.text = 'ZONE-14-ACTIVE';
      }
    });
  }

  void _handleLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainNavigationShell(initialRole: _selectedRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.slate900,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: AppTheme.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CivicAI',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.slate900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Municipal Intelligence Platform',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.slate500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Minimal Role Segmented Selector
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.slate200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRoleTab('Citizen', UserRole.citizen),
                          _buildRoleTab('Officer', UserRole.officer),
                          _buildRoleTab('Worker', UserRole.fieldWorker),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _roleHeading,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slate900,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _roleDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.slate500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),

                        // Dynamic Fields based on Role
                        if (_selectedRole == UserRole.citizen) ...[
                          const Text(
                            'Mobile Number (Demo Pre-filled)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _identifierController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.phone_outlined, size: 18, color: AppTheme.slate400),
                              hintText: '+1 (555) 000-0000',
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Select Ward / Locality (Demo Pre-filled)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedWard,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.location_city_outlined, size: 18, color: AppTheme.slate400),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Ward 14 - North Zone', child: Text('Ward 14 - North Zone', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'Ward 12 - Central Zone', child: Text('Ward 12 - Central Zone', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'Ward 08 - Civil Lines', child: Text('Ward 08 - Civil Lines', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedWard = val);
                            },
                          ),
                        ] else if (_selectedRole == UserRole.officer) ...[
                          const Text(
                            'Department & Jurisdiction (Demo Pre-filled)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedDepartment,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.apartment_outlined, size: 18, color: AppTheme.slate400),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Roads & Infrastructure', child: Text('Roads & Infrastructure', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'Sanitation & Solid Waste', child: Text('Sanitation (Phase 2)', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'Electrical & Public Lighting', child: Text('Electrical (Phase 2)', overflow: TextOverflow.ellipsis)),
                              DropdownMenuItem(value: 'Water Supply & Sewerage', child: Text('Water Supply (Phase 2)', overflow: TextOverflow.ellipsis)),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDepartment = val);
                            },
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Officer Badge / ID (Demo Pre-filled)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _identifierController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.badge_outlined, size: 18, color: AppTheme.slate400),
                              hintText: 'OFF-XXXX-XX',
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'Field Worker ID (Demo Pre-filled)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _identifierController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.engineering_outlined, size: 18, color: AppTheme.slate400),
                              hintText: 'CREW-ID',
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Assigned Shift & Zone (Demo Pre-filled)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _secretController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.schedule_outlined, size: 18, color: AppTheme.slate400),
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        // Instant Demo Access Button (Primary Visual CTA)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.slate900,
                              foregroundColor: AppTheme.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bolt_rounded, size: 18, color: AppTheme.warningAmber),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Instant Demo Access as ${_selectedRole.displayName}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Login Action Button (Secondary Visual CTA)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _handleLogin,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    _loginButtonText,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Minimal footer
                  const Center(
                    child: Text(
                      'CivicAI Platform • Prototype Mode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.slate400,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String title, UserRole role) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onRoleChanged(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.slate900 : AppTheme.slate600,
            ),
          ),
        ),
      ),
    );
  }

  String get _roleHeading {
    switch (_selectedRole) {
      case UserRole.citizen:
        return 'Citizen Incident Reporting';
      case UserRole.officer:
        return 'Municipal Officer Command';
      case UserRole.fieldWorker:
        return 'Field Worker Task Verification';
    }
  }

  String get _roleDescription {
    switch (_selectedRole) {
      case UserRole.citizen:
        return 'Submit geotagged civic issues with real-time YOLO verification.';
      case UserRole.officer:
        return 'Triage department queues, assign crews, and audit SLA performance.';
      case UserRole.fieldWorker:
        return 'Receive repair tasks and capture AI-verified resolution photos.';
    }
  }

  String get _loginButtonText {
    switch (_selectedRole) {
      case UserRole.citizen:
        return 'Enter Citizen Portal';
      case UserRole.officer:
        return 'Authenticate Officer Access';
      case UserRole.fieldWorker:
        return 'Access Work Orders';
    }
  }
}
