import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/incident_model.dart';

class ApiService {
  static String baseUrl = 'https://gas-detector-api.onrender.com';

  static void updateBaseUrl(String url) {
    // Clean URL before assignment
    baseUrl = url.trim().replaceAll(RegExp(r'\s+'), ' ');
    debugPrint('📡 API Base URL updated to: $baseUrl');
  }

  static const String apiPrefix = '/api';

  // ===== GET LATEST SENSOR DATA =====
  static Future<Incident?> getLatestReading() async {
    try {
      Incident? result;
      final response = await http
          .get(Uri.parse('$baseUrl$apiPrefix/sensor/latest'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['success'] == true && data['data'] != null) {
          result = Incident.fromJson(data['data']);
        }
      }
      return result;
    } catch (e) {
      debugPrint('❌ Error fetching latest reading: $e');
      return null;
    }
  }

  // ===== GET INCIDENTS WITH PAGINATION =====
  static Future<List<Incident>> getIncidents({
    int page = 1,
    int limit = 20,
    String status = 'all',
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl$apiPrefix/incidents?page=$page&limit=$limit&status=$status',
            ),
          )
          .timeout(const Duration(seconds: 10));
      List incidentsJson = [];
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['success'] == true && data['data'] != null) {
          final incidentsData = data['data'];

          if (incidentsData is Map && incidentsData['incidents'] != null) {
            incidentsJson = incidentsData['incidents'] as List;
          } else if (incidentsData is List) {
            incidentsJson = incidentsData;
          }
        }
      }
      return incidentsJson.map((json) => Incident.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching incidents: $e');
      return [];
    }
  }

  // ===== GET STATISTICS =====
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$apiPrefix/statistics'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['success'] == true) {
          return data['data'] is Map
              ? Map<String, dynamic>.from(data['data'])
              : {};
        }
      }
      debugPrint('❌ Failed to get statistics: ${response.statusCode}');
      return {};
    } catch (e) {
      debugPrint('❌ Error fetching statistics: $e');
      return {};
    }
  }

  // ===== GET CHART DATA =====
  static Future<List<Incident>> getChartData({int limit = 50}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$apiPrefix/chart/data?limit=$limit'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['success'] == true && data['data'] != null) {
          final chartDataJson = data['data'] as List;
          return chartDataJson.map((json) => Incident.fromJson(json)).toList();
        }
      }
      debugPrint('❌ Failed to get chart data: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching chart data: $e');
      return [];
    }
  }

  // ===== CRITICAL: SEND INCIDENT TO SERVER (Mobile → Cloud) =====
  static Future<bool> createIncident(Incident incident) async {
    // ✅ 2. Prepare payload EXACTLY as server expects
    final body = {
      'gas_level': incident.gasLevel,
      'status': incident.status,
      'location': incident.location,
      // ✅ Mobile-specific sensor ID for analytics
      'sensor_id':
          'MOBILE_${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}',
    };

    final url = Uri.parse('$baseUrl$apiPrefix/incidents');
    debugPrint(
      '📤 Sending critical incident to server: ${incident.gasLevel} PPM (${incident.status})',
    );

    try {
      // ✅ 3. Short timeout (5s) for Tanzania network conditions
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));

      // ✅ 4. Handle success
      if (response.statusCode == 201) {
        debugPrint(
          '✅ Server save successful: ID=${json.decode(response.body)['data']['id']}',
        );
        return true;
      }
      // ✅ 5. Handle server errors (queue for retry)
      else {
        debugPrint(
          '❌ Server rejected incident: ${response.statusCode} - ${response.body.substring(0, 100)}',
        );
        return false; // Queue will retry with exponential backoff
      }
    } on TimeoutException {
      debugPrint('⏱️ Request timed out after 5s (Tanzania network conditions)');
      return false; // Queue will retry
    } catch (e) {
      debugPrint('⚠️ Network error during send: $e');
      return false; // Queue will retry
    }
  }

  // ===== GET SYSTEM SETTINGS =====
  static Future<Map<String, String>> getSettings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$apiPrefix/settings'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Map<String, String>.from(data['data'] ?? {});
        }
      }
      return {};
    } catch (e) {
      debugPrint('❌ Error fetching settings: $e');
      return {};
    }
  }

  // ===== UPDATE SYSTEM SETTINGS =====
  static Future<bool> updateSettings(Map<String, String> settings) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiPrefix/settings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'settings': settings}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error updating settings: $e');
      return false;
    }
  }

  // ===== TEST CONNECTION =====
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$apiPrefix/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return false;
    }
  }
}
