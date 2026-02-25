import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/incident_model.dart';

class ApiService {
  // Default server IP
  static String baseUrl = 'http://192.168.1.100:3000';

  static void updateBaseUrl(String url) {
    baseUrl = url;
  }

  static const String apiPrefix = '/api';

  // Get latest sensor reading
  static Future<Incident?> getLatestReading() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiPrefix/sensor/latest'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          return Incident.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching latest reading: $e');
      return null;
    }
  }

  // Get incidents with pagination
  static Future<List<Incident>> getIncidents({
    int page = 1,
    int limit = 20,
    String status = 'all',
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl$apiPrefix/incidents?page=$page&limit=$limit&status=$status',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          final incidentsJson = data['data']['incidents'] as List;
          return incidentsJson.map((json) => Incident.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching incidents: $e');
      return [];
    }
  }

  // Get statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiPrefix/statistics'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'] ?? {};
        }
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching statistics: $e');
      return {};
    }
  }

  // Get chart data
  static Future<List<Incident>> getChartData({int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiPrefix/chart/data?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['data'] != null) {
          final chartDataJson = data['data'] as List;
          return chartDataJson.map((json) => Incident.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      return [];
    }
  }

  // Post new incident (for testing)
  static Future<bool> createIncident(Incident incident) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiPrefix/incidents'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(incident.toJson()),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating incident: $e');
      return false;
    }
  }

  // Get system settings
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
      debugPrint('Error fetching settings: $e');
      return {};
    }
  }

  // Update system settings
  static Future<bool> updateSettings(Map<String, String> settings) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiPrefix/settings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'settings': settings}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating settings: $e');
      return false;
    }
  }

  // Test connection
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$apiPrefix/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
