import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incident_model.dart';
import '../services/api_service.dart';

class GasDataProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Incident? _latestReading;
  List<Incident> _incidents = [];
  List<Incident> _chartData = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  bool _isConnected = false;
  int _currentPage = 1;
  String _filterStatus = 'all';

  //TODO Change IP Settings
  String _serverIp = '127.0.0.1';
  String _serverPort = '3000';
  int _refreshInterval = 2;
  bool _autoRefresh = true;

  // Getters
  Incident? get latestReading => _latestReading;
  List<Incident> get incidents => _incidents;
  List<Incident> get chartData => _chartData;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  int get currentPage => _currentPage;
  String get filterStatus => _filterStatus;
  int get gasLevel => _latestReading?.gasLevel ?? 0;
  String get currentStatus => _latestReading?.status ?? 'NORMAL';
  bool get isAlert => _latestReading?.isAlert ?? false;

  String get serverIp => _serverIp;
  String get serverPort => _serverPort;
  int get refreshInterval => _refreshInterval;
  bool get autoRefresh => _autoRefresh;

  // Setters
  set filterStatus(String value) {
    _filterStatus = value;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    // Save to shared preferences
    _savePreferences();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setString('serverIp', _serverIp);
    await prefs.setString('serverPort', _serverPort);
    await prefs.setInt('refreshInterval', _refreshInterval);
    await prefs.setBool('autoRefresh', _autoRefresh);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _serverIp = prefs.getString('serverIp') ?? '127.0.0.1';
    _serverPort = prefs.getString('serverPort') ?? '3000';
    _refreshInterval = prefs.getInt('refreshInterval') ?? 2;
    _autoRefresh = prefs.getBool('autoRefresh') ?? true;

    // Update API Service
    ApiService.updateBaseUrl('http://$_serverIp:$_serverPort');
    notifyListeners();
  }

  // Update Settings
  Future<void> updateSettings({
    required String ip,
    required String port,
    required int interval,
    required bool autoRefresh,
  }) async {
    _serverIp = ip;
    _serverPort = port;
    _refreshInterval = interval;
    _autoRefresh = autoRefresh;

    ApiService.updateBaseUrl('http://$_serverIp:$_serverPort');
    await _savePreferences();

    // Re-test connection with new settings
    await testConnection();

    if (_autoRefresh && _isConnected) {
      startAutoRefresh(interval: _refreshInterval);
    } else {
      stopAutoRefresh();
    }

    notifyListeners();
  }

  // Fetch latest reading
  Future<void> fetchLatestReading() async {
    _latestReading = await ApiService.getLatestReading();
    notifyListeners();
  }

  // Fetch incidents
  Future<void> fetchIncidents({int page = 1, bool loadMore = false}) async {
    _isLoading = true;
    notifyListeners();

    if (!loadMore) {
      _currentPage = 1;
      _incidents.clear();
    } else {
      _currentPage = page;
    }

    final incidents = await ApiService.getIncidents(
      page: _currentPage,
      limit: 20,
      status: _filterStatus,
    );

    if (!loadMore) {
      _incidents = incidents;
    } else {
      _incidents.addAll(incidents);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load more incidents
  Future<void> loadMoreIncidents() async {
    await fetchIncidents(page: _currentPage + 1, loadMore: true);
  }

  // Fetch statistics
  Future<void> fetchStatistics() async {
    _statistics = await ApiService.getStatistics();
    notifyListeners();
  }

  // Fetch chart data
  Future<void> fetchChartData() async {
    _chartData = await ApiService.getChartData(limit: 50);
    notifyListeners();
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      fetchLatestReading(),
      fetchIncidents(),
      fetchStatistics(),
      fetchChartData(),
    ]);
  }

  // Test connection
  Future<void> testConnection() async {
    _isConnected = await ApiService.testConnection();
    notifyListeners();
  }

  // Initialize
  Future<void> initialize() async {
    // Load saved preferences
    await _loadPreferences();
    await testConnection();
    if (_isConnected) {
      await refreshAllData();
    }
    if (_autoRefresh) {
      startAutoRefresh(interval: _refreshInterval);
    }
    notifyListeners();
  }

  Timer? _autoRefreshTimer;

  void startAutoRefresh({int interval = 2}) {
    stopAutoRefresh();
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: interval),
      (_) => refreshAllData(),
    );
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
