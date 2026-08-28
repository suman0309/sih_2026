import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Connects the Flutter prototype to the CivicAI Node backend.
///
/// For an Android emulator the default address works.  For a real phone, pass
/// your laptop's Wi-Fi IP when running Flutter, for example:
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3001
class CivicApiService {
  CivicApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001',
  );

  final http.Client _client;

  Future<CivicScanResult> createReport({
    required File image,
    required double latitude,
    required double longitude,
    String description = 'Pothole reported from CivicAI mobile app.',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/reports'),
    )
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..fields['description'] = description
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamed = await _client.send(request).timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
    final Map<String, dynamic> body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CivicApiException(
        body['error']?.toString() ?? body['message']?.toString() ?? 'Could not analyse this image.',
      );
    }

    return CivicScanResult.fromJson(body, await image.readAsBytes());
  }
}

class CivicApiException implements Exception {
  CivicApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CivicScanResult {
  CivicScanResult({
    required this.report,
    required this.detections,
    required this.imageBytes,
  });

  final Map<String, dynamic> report;
  final List<Map<String, dynamic>> detections;
  final Uint8List imageBytes;

  factory CivicScanResult.fromJson(Map<String, dynamic> json, Uint8List imageBytes) {
    final reportValue = json['report'];
    final report = reportValue is Map<String, dynamic>
        ? reportValue
        : Map<String, dynamic>.from(json);
    final rawDetections = json['detections'] ?? report['detections'] ?? const [];
    final detections = rawDetections is List
        ? rawDetections.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
        : <Map<String, dynamic>>[];
    return CivicScanResult(report: report, detections: detections, imageBytes: imageBytes);
  }
}
