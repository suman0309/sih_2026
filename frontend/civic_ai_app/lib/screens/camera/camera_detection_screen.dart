import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/report_item.dart';
import '../../models/yolo_detection.dart';
import '../../services/civic_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/risk_score_indicator.dart';

enum CameraScanMode {
  pothole,
  multiHazard,
  garbage,
  afterRepairProof,
  cleanStreet,
}

enum ScannerState {
  readyToScan,
  analysing,
  potholeDetected,
  noHazardDetected,
}

class CameraDetectionScreen extends StatefulWidget {
  final UserRole userRole;
  final Function(ReportItem newReport)? onReportCreated;

  const CameraDetectionScreen({
    super.key,
    this.userRole = UserRole.citizen,
    this.onReportCreated,
  });

  @override
  State<CameraDetectionScreen> createState() => _CameraDetectionScreenState();
}

class _CameraDetectionScreenState extends State<CameraDetectionScreen> with SingleTickerProviderStateMixin {
  CameraScanMode _scanMode = CameraScanMode.pothole;
  ScannerState _scannerState = ScannerState.readyToScan;
  bool _flashEnabled = false;
  bool _isWideLens = false;
  late AnimationController _scanAnimationController;
  Timer? _analysisTimer;
  double _analysisProgress = 0.0;
  Timer? _progressTimer;
  final ImagePicker _imagePicker = ImagePicker();
  final CivicApiService _apiService = CivicApiService();
  File? _selectedImage;
  List<YoloDetection> _apiDetections = [];
  ReportItem? _createdReport;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (widget.userRole == UserRole.fieldWorker) {
      _scanMode = CameraScanMode.afterRepairProof;
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _analysisTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  List<YoloDetection> get _activeDetections {
    if (_apiDetections.isNotEmpty) return _apiDetections;
    switch (_scanMode) {
      case CameraScanMode.pothole:
        return YoloDetection.defaultPotholeDetections;
      case CameraScanMode.multiHazard:
        return YoloDetection.multiHazardDetections;
      case CameraScanMode.garbage:
        return YoloDetection.garbageDetections;
      case CameraScanMode.afterRepairProof:
        return [
          const YoloDetection(
            label: 'Surface Repair Patch',
            confidence: 0.948,
            normalizedRect: Rect.fromLTWH(0.20, 0.40, 0.60, 0.26),
            severity: SeverityLevel.low,
            estimatedAreaSqM: 1.20,
            inferenceTimeMs: 12,
            description: 'Flush asphalt bitumen • 0% cavity remaining',
          ),
        ];
      case CameraScanMode.cleanStreet:
        return [];
    }
  }

  Future<void> _triggerScan() async {
    if (_scannerState == ScannerState.analysing) return;

    if (_scanMode != CameraScanMode.pothole && _scanMode != CameraScanMode.afterRepairProof) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This category is part of Phase 2. Currently, only Pothole workflows are interactive.'),
          backgroundColor: AppTheme.slate700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedImage == null) {
      await _pickImage(ImageSource.camera);
      if (_selectedImage == null || !mounted) return;
    }

    setState(() {
      _scannerState = ScannerState.analysing;
      _analysisProgress = 0.0;
      _scanError = null;
    });

    // Simulate progress bar updates
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        setState(() {
          _analysisProgress += 0.1;
          if (_analysisProgress >= 1.0) {
            _analysisProgress = 1.0;
            _progressTimer?.cancel();
          }
        });
      }
    });

    try {
      final result = await _apiService.createReport(
        image: _selectedImage!,
        latitude: 28.6139,
        longitude: 77.2090,
      );
      if (!mounted) return;
      final detections = await _toYoloDetections(result.detections, result.imageBytes, result.report);
      if (!mounted) return;
      setState(() {
        _apiDetections = detections;
        _createdReport = _reportFromApi(result.report, detections);
        _scannerState = detections.isEmpty
            ? ScannerState.noHazardDetected
            : ScannerState.potholeDetected;
        _analysisProgress = 1.0;
      });
      if (detections.isNotEmpty) _showResultsBottomSheet();
    } on CivicApiException catch (error) {
      _showScanError(error.message);
    } on TimeoutException {
      _showScanError('The server took too long to respond. Check that backend and YOLO are running.');
    } catch (_) {
      _showScanError('Could not reach the backend. Check the API address and your Wi-Fi connection.');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(source: source, imageQuality: 88);
      if (image == null || !mounted) return;
      setState(() {
        _selectedImage = File(image.path);
        _apiDetections = [];
        _createdReport = null;
        _scanError = null;
        _scannerState = ScannerState.readyToScan;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera/gallery permission was not granted.')));
    }
  }

  void _showScanError(String message) {
    if (!mounted) return;
    setState(() {
      _scannerState = ScannerState.readyToScan;
      _scanError = message;
      _analysisProgress = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppTheme.criticalRed));
  }

  Future<List<YoloDetection>> _toYoloDetections(
    List<Map<String, dynamic>> raw,
    List<int> imageBytes,
    Map<String, dynamic> report,
  ) async {
    final image = await decodeImageFromList(Uint8List.fromList(imageBytes));
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    return raw.map((item) {
      final box = item['box'];
      final values = box is List && box.length == 4
          ? box.map((value) => (value as num).toDouble()).toList()
          : <double>[width * .18, height * .42, width * .82, height * .70];
      final confidence = _asDouble(item['confidence']).clamp(0.0, 1.0).toDouble();
      final severity = _severityFromText(report['severity']?.toString());
      return YoloDetection(
        label: item['label']?.toString() ?? 'Pothole',
        confidence: confidence,
        normalizedRect: Rect.fromLTWH(
          (values[0] / width).clamp(0.0, 1.0).toDouble(),
          (values[1] / height).clamp(0.0, 1.0).toDouble(),
          ((values[2] - values[0]) / width).clamp(0.05, 1.0).toDouble(),
          ((values[3] - values[1]) / height).clamp(0.05, 1.0).toDouble(),
        ),
        severity: severity,
        estimatedAreaSqM: 0,
        inferenceTimeMs: 0,
        description: 'Detected by the CivicAI YOLO service.',
      );
    }).toList();
  }

  SeverityLevel _severityFromText(String? value) {
    switch (value?.toLowerCase()) {
      case 'critical': return SeverityLevel.critical;
      case 'high': return SeverityLevel.high;
      case 'medium': return SeverityLevel.medium;
      default: return SeverityLevel.low;
    }
  }

  double _asDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

  ReportItem _reportFromApi(Map<String, dynamic> data, List<YoloDetection> detections) {
    final severity = _severityFromText(data['severity']?.toString());
    final confidence = _asDouble(data['ai_confidence'] ?? data['aiConfidence'] ?? (detections.isEmpty ? 0 : detections.first.confidence));
    final score = _asDouble(data['risk_score'] ?? data['riskScore']);
    final id = data['id']?.toString() ?? 'CV-${DateTime.now().millisecondsSinceEpoch}';
    return ReportItem(
      id: id,
      title: data['title']?.toString() ?? 'Pothole reported by AI scan',
      category: IssueCategory.pothole,
      severity: severity,
      riskScore: score.toInt(),
      department: 'Roads & Infrastructure',
      locationName: data['location_name']?.toString() ?? 'Location captured',
      coordinates: '${data['latitude'] ?? '28.6139'}° N, ${data['longitude'] ?? '77.2090'}° E',
      reportedAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
      slaHoursRemaining: severity == SeverityLevel.high || severity == SeverityLevel.critical ? 4 : 24,
      status: ReportStatus.reported,
      citizenName: 'Active User',
      aiConfidence: confidence,
      yoloDetectionsCount: detections.length,
      beforeEvidenceNote: detections.isEmpty ? 'No pothole detected.' : 'YOLO detected ${detections.length} pothole area(s).',
    );
  }

  void _resetScanner() {
    setState(() {
      _scannerState = ScannerState.readyToScan;
      _analysisProgress = 0.0;
      _apiDetections = [];
      _createdReport = null;
      _selectedImage = null;
      _scanError = null;
    });
  }

  void _showResultsBottomSheet() {
    final detections = _activeDetections;
    final primary = detections.isNotEmpty ? detections.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildTriageConfirmationSheet(primary),
    );
  }

  Widget _buildTriageConfirmationSheet(YoloDetection? detection) {
    final isFieldRepair = _scanMode == CameraScanMode.afterRepairProof;
    final category = _scanMode == CameraScanMode.garbage
        ? IssueCategory.garbage
        : IssueCategory.pothole;
    
    // Structured details for backend integration
    final report = _createdReport;
    final String hazardType = detection?.label ?? 'Pothole';
    final double confidence = detection?.confidence ?? report?.aiConfidence ?? 0;
    final SeverityLevel estimatedSeverity = report?.severity ?? detection?.severity ?? SeverityLevel.low;
    final String locationName = report?.locationName ?? 'Location captured';
    final String coordinates = report?.coordinates ?? '28.6139° N, 77.2090° E';
    final int riskScore = report?.riskScore ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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

          // Header with Title & Confidence Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFieldRepair ? 'Repair Verification Result' : 'AI Detection Result',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate900,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'AI-assisted detection',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.verifiedGreenBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.verifiedGreenBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.verifiedGreen, size: 12),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${(confidence * 100).toStringAsFixed(1)}% Conf',
                          style: const TextStyle(
                            color: AppTheme.verifiedGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Structured Mock Values Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.slate50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(
              children: [
                _buildSheetDetailRow('Hazard Type', hazardType, isBold: true),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                        child: Text('Estimated Severity',
                            style: TextStyle(color: AppTheme.slate500, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: estimatedSeverity == SeverityLevel.critical ? AppTheme.criticalRedBg : AppTheme.verifiedGreenBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          estimatedSeverity.name.toUpperCase(),
                          style: TextStyle(
                            color: estimatedSeverity == SeverityLevel.critical ? AppTheme.criticalRed : AppTheme.verifiedGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                        child: Text('Risk Score Rating',
                            style: TextStyle(color: AppTheme.slate500, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: RiskScoreIndicator(
                        score: riskScore,
                        severity: estimatedSeverity,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                _buildSheetDetailRow('Location Captured', '$locationName ($coordinates)'),
                const Divider(height: 16),
                _buildSheetDetailRow('Jurisdiction Zone', 'Ward 14 North Zone'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Submit Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if (report != null) widget.onReportCreated?.call(report);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Report #${report?.id ?? 'saved'} submitted to municipal dashboard!'),
                    backgroundColor: AppTheme.slate900,
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                _resetScanner();
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('View Submitted Report'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSheetDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.slate500, fontSize: 12)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppTheme.slate800,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Image Preview or Viewfinder Area
          Positioned.fill(
            child: _buildScannerViewport(),
          ),

          // 2. Telemetry HUD Bar (Cleaned of hardcoded FPS/meters claims)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mode tag
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _scannerState == ScannerState.analysing ? Colors.orange : const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Flexible(
                                child: Text(
                                  'AI-assisted detection',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status tag
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: const Text(
                            'Prototype estimate',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Location Tag
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.gps_fixed, size: 12, color: Color(0xFF60A5FA)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'GPS: 28.6139° N, 77.2090° E • Location captured',
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // State Info Overlay
          if (_scannerState != ScannerState.readyToScan)
            Positioned(
              top: 130,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStateColor().withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_scannerState == ScannerState.analysing) ...[
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        Icon(_getStateIcon(), size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        _getStateLabel(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Bottom Control Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: const Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode Selector Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildModeChip('Pothole Sweep', CameraScanMode.pothole),
                        const SizedBox(width: 8),
                        _buildModeChip('Multi-Hazard (Soon)', CameraScanMode.multiHazard),
                        const SizedBox(width: 8),
                        _buildModeChip('Sanitation (Soon)', CameraScanMode.garbage),
                        const SizedBox(width: 8),
                        _buildModeChip('After-Repair Proof', CameraScanMode.afterRepairProof),
                        const SizedBox(width: 8),
                        _buildModeChip('Others (Soon)', CameraScanMode.cleanStreet),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Action Row: Flash, Shutter Capture, Reset/View
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Flash Toggle
                      IconButton(
                        onPressed: () => setState(() => _flashEnabled = !_flashEnabled),
                        icon: Icon(
                          _flashEnabled ? Icons.flash_on : Icons.flash_off,
                          color: _flashEnabled ? const Color(0xFFFBBF24) : Colors.white70,
                          size: 22,
                        ),
                      ),

                      // Shutter Trigger
                      GestureDetector(
                        onTap: _scannerState == ScannerState.analysing ? null : _triggerScan,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _scannerState == ScannerState.analysing 
                                  ? Colors.white24 
                                  : Colors.white, 
                              width: 3,
                            ),
                            color: Colors.transparent,
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _scannerState == ScannerState.analysing 
                                  ? Colors.grey 
                                  : AppTheme.white,
                            ),
                            child: Icon(
                              _scannerState == ScannerState.potholeDetected 
                                  ? Icons.remove_red_eye_outlined
                                  : Icons.camera_alt,
                              color: AppTheme.slate900,
                              size: 26,
                            ),
                          ),
                        ),
                      ),

                      // Gallery Upload/Reset Toggle
                      IconButton(
                        onPressed: () {
                          if (_scannerState != ScannerState.readyToScan) {
                            _resetScanner();
                          } else {
                            _pickImage(ImageSource.gallery);
                          }
                        },
                        icon: Icon(
                          _scannerState != ScannerState.readyToScan 
                              ? Icons.refresh 
                              : Icons.photo_library_outlined,
                          color: Colors.white70,
                          size: 22,
                        ),
                        tooltip: _scannerState != ScannerState.readyToScan ? 'Scan Again' : 'Upload Image',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerViewport() {
    if (_scannerState == ScannerState.readyToScan && _selectedImage == null) {
      // Empty viewfinder look with Corner Brackets & Grid Lines
      return Container(
        color: const Color(0xFF1E293B),
        child: Stack(
          children: [
            _buildGridLines(),
            _buildCornerBrackets(),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.center_focus_weak_rounded, color: Colors.white38, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Align camera with road hazard\nTap Shutter or Upload Photo to analyze',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Image-preview container for analysing/result states
    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_selectedImage != null)
            Image.file(_selectedImage!, fit: BoxFit.cover)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF334155), Color(0xFF1E293B)],
                ),
              ),
              child: _buildGridLines(),
            ),

          // Bounding Box Overlays if pothole is detected
          if (_scannerState == ScannerState.potholeDetected)
            ..._activeDetections.map((detection) => _buildBoundingBoxWidget(detection)),

          // Scan line moving effect when Analysing
          if (_scannerState == ScannerState.analysing)
            AnimatedBuilder(
              animation: _scanAnimationController,
              builder: (context, child) {
                final topOffset = 100 + (MediaQuery.of(context).size.height - 300) * _scanAnimationController.value;
                return Positioned(
                  top: topOffset,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF22C55E),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Analysis Loading Overlay
          if (_scannerState == ScannerState.analysing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 20),
                      const Text(
                        'Analysing image...',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _analysisProgress,
                          color: const Color(0xFF22C55E),
                          backgroundColor: Colors.white12,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBoundingBoxWidget(YoloDetection detection) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = detection.normalizedRect.left * constraints.maxWidth;
        final top = detection.normalizedRect.top * constraints.maxHeight;
        final width = detection.normalizedRect.width * constraints.maxWidth;
        final height = detection.normalizedRect.height * constraints.maxHeight;

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bounding box frame
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: detection.boxColor, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Corner notches
              Positioned(
                top: -2, left: -2,
                child: Container(width: 8, height: 8, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 2), left: BorderSide(color: Colors.white, width: 2)))),
              ),
              Positioned(
                top: -2, right: -2,
                child: Container(width: 8, height: 8, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 2), right: BorderSide(color: Colors.white, width: 2)))),
              ),
              Positioned(
                bottom: -2, left: -2,
                child: Container(width: 8, height: 8, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 2), left: BorderSide(color: Colors.white, width: 2)))),
              ),
              Positioned(
                bottom: -2, right: -2,
                child: Container(width: 8, height: 8, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 2), right: BorderSide(color: Colors.white, width: 2)))),
              ),

              // Bounding box header label tag
              Positioned(
                top: -22,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: detection.boxColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '${detection.label.toUpperCase()} ${detection.confidencePercentage}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Bounding box bottom area spec tag
              Positioned(
                bottom: -20,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'Area: ~${detection.estimatedAreaSqM}m² • Prototype estimate',
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridLines() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Row divisions
            Positioned(top: constraints.maxHeight / 3, left: 16, right: 16, child: Container(height: 0.8, color: Colors.white10)),
            Positioned(top: 2 * constraints.maxHeight / 3, left: 16, right: 16, child: Container(height: 0.8, color: Colors.white10)),
            // Col divisions
            Positioned(left: constraints.maxWidth / 3, top: 16, bottom: 16, child: Container(width: 0.8, color: Colors.white10)),
            Positioned(left: 2 * constraints.maxWidth / 3, top: 16, bottom: 16, child: Container(width: 0.8, color: Colors.white10)),
          ],
        );
      },
    );
  }

  Widget _buildCornerBrackets() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white38, width: 2), left: BorderSide(color: Colors.white38, width: 2)))),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white38, width: 2), right: BorderSide(color: Colors.white38, width: 2)))),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white38, width: 2), left: BorderSide(color: Colors.white38, width: 2)))),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white38, width: 2), right: BorderSide(color: Colors.white38, width: 2)))),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStateColor() {
    switch (_scannerState) {
      case ScannerState.readyToScan:
        return AppTheme.primaryBlue;
      case ScannerState.analysing:
        return AppTheme.warningAmber;
      case ScannerState.potholeDetected:
        return AppTheme.criticalRed;
      case ScannerState.noHazardDetected:
        return AppTheme.verifiedGreen;
    }
  }

  String _getStateLabel() {
    switch (_scannerState) {
      case ScannerState.readyToScan:
        return 'Ready to scan';
      case ScannerState.analysing:
        return 'Analysing image...';
      case ScannerState.potholeDetected:
        return 'Pothole detected';
      case ScannerState.noHazardDetected:
        return 'No hazard detected';
    }
  }

  IconData _getStateIcon() {
    switch (_scannerState) {
      case ScannerState.readyToScan:
        return Icons.camera_enhance_outlined;
      case ScannerState.analysing:
        return Icons.hourglass_top_rounded;
      case ScannerState.potholeDetected:
        return Icons.report_problem_outlined;
      case ScannerState.noHazardDetected:
        return Icons.check_circle_outline_rounded;
    }
  }

  Widget _buildModeChip(String label, CameraScanMode mode) {
    final isSelected = _scanMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _scanMode = mode;
          _resetScanner();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.white : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.slate900 : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}
