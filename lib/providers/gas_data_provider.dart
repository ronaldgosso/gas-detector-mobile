import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incident_model.dart';
import '../services/api_service.dart';
import '../services/bluetooth_service.dart';

class GasDataProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Incident? _latestReading;
  List<Incident> _incidents = []; // All incidents (local + server)
  List<Incident> _chartData = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  bool _isConnected = false; // Server connection
  bool _isBluetoothConnected = false; // Bluetooth status
  int _currentPage = 1;
  String _filterStatus = 'all';

  // Server Settings
  String _serverIp = 'https://gas-detector-api.onrender.com';
  String _serverPort = '3000';
  int _refreshInterval = 2;
  bool _autoRefresh = true;

  // Bluetooth Bridge
  final BluetoothService _bluetoothService = BluetoothService();
  String _bluetoothBuffer = "";
  StreamSubscription<String>? _bluetoothSubscription;

  // CRITICAL: Local data processing buffer (last 3 readings)
  final List<int> _recentGasLevels = []; // Rolling buffer of last 3 readings
  static const int _bufferSize = 3; // Only keep last 3 readings
  static const int _criticalThreshold = 800; // Only send if avg > 800 PPM

  // Retry queue for failed server sends
  final List<PendingIncident> _pendingSends = [];
  Timer? _retryTimer;

  BluetoothService get bluetoothService => _bluetoothService;

  // Getters
  Incident? get latestReading => _latestReading;
  List<Incident> get incidents => _incidents;
  List<Incident> get chartData => _chartData;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  bool get isBluetoothConnected => _isBluetoothConnected;
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
    _serverIp = prefs.getString('serverIp') ?? 'https://gas-detector-api.onrender.com';
    _serverPort = prefs.getString('serverPort') ?? '3000';
    _refreshInterval = prefs.getInt('refreshInterval') ?? 3;
    _autoRefresh = prefs.getBool('autoRefresh') ?? true;

    // Update API Service
    ApiService.updateBaseUrl(
      serverIp == 'https://gas-detector-api.onrender.com'
          ? 'https://gas-detector-api.onrender.com'
          : 'http://$_serverIp:$_serverPort',
    );
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

    ApiService.updateBaseUrl(
      serverIp == 'https://gas-detector-api.onrender.com'
          ? 'https://gas-detector-api.onrender.com'
          : 'http://$_serverIp:$_serverPort',
    );
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

  // Bluetooth Connection & Bridging
  Future<void> connectBluetooth(String address) async {
    // Disconnect existing connection first
    if (_isBluetoothConnected) {
      disconnectBluetooth();
    }

    final success = await _bluetoothService.connect(address);
    _isBluetoothConnected = success;

    if (success) {
      _startBluetoothBridging();
      debugPrint('✅ Bluetooth connected successfully');
    } else {
      debugPrint('❌ Bluetooth connection failed');
    }

    notifyListeners();
  }

  void _startBluetoothBridging() {
    _bluetoothSubscription?.cancel();
    _bluetoothSubscription = _bluetoothService.dataStream.listen(
      (data) {
        _bluetoothBuffer += data;

        // Process complete lines (Arduino sends \n terminated lines)
        while (_bluetoothBuffer.contains('\n')) {
          final index = _bluetoothBuffer.indexOf('\n');
          String line = _bluetoothBuffer.substring(0, index).trim();
          _bluetoothBuffer = _bluetoothBuffer.substring(index + 1);

          if (line.isNotEmpty) {
            _processBluetoothData(line);
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Bluetooth stream error: $error');
        _isBluetoothConnected = false;
        notifyListeners();
      },
    );
  }

  // CRITICAL: Process Bluetooth data with local intelligence
  void _processBluetoothData(String data) {
    debugPrint('📡 Raw BT data: "$data"');

    // Parse Arduino format: "GAS:512,ALERT" OR raw integer "512"
    int? gasLevel;
    String status = 'NORMAL';

    // Case 1: Arduino sends "GAS:512,ALERT" format
    if (data.startsWith('GAS:')) {
      try {
        final parts = data.substring(4).split(',');
        gasLevel = int.tryParse(parts[0].trim());
        if (parts.length > 1) {
          status = parts[1].trim().toUpperCase();
        }
      } catch (e) {
        debugPrint('⚠️ Parse error for "$data": $e');
        return;
      }
    }
    // Case 2: Arduino sends raw integer
    else {
      gasLevel = int.tryParse(data.trim());
    }

    // Validate reading
    if (gasLevel == null || gasLevel < 0 || gasLevel > 1023) {
      debugPrint('⚠️ Invalid gas level: $gasLevel');
      return;
    }

    // Determine status if not provided
    if (status == 'NORMAL' && gasLevel > 400) {
      status = 'ALERT';
    }

    // Create incident with current timestamp
    final incident = Incident(
      gasLevel: gasLevel,
      status: status,
      timestamp: DateTime.now(),
      location: 'Mobile Sensor (${_bluetoothService.deviceName ?? "HC-05"})',
    );

    // 1. Update UI immediately (real-time feedback)
    _latestReading = incident;
    _addToLocalIncidents(incident); // Store locally for UI
    notifyListeners();

    // 2. Add to rolling buffer for averaging
    _recentGasLevels.add(gasLevel);
    if (_recentGasLevels.length > _bufferSize) {
      _recentGasLevels.removeAt(0); // Maintain only last 3 readings
    }

    // 3. CRITICAL LOGIC: Only send to server if avg of last 3 > 800 PPM
    if (_recentGasLevels.length >= _bufferSize) {
      final avgLevel = _recentGasLevels.reduce((a, b) => a + b) / _bufferSize;
      debugPrint(
        '📊 Rolling avg of last $_bufferSize readings: ${avgLevel.toStringAsFixed(1)} PPM',
      );

      if (avgLevel > _criticalThreshold) {
        _queueForServerSend(
          incident.copyWith(
            gasLevel: avgLevel.round(), // Send averaged value
            status: 'ALERT', // Force alert status for critical avg
            location: '${incident.location} (Avg)',
          ),
        );
      }
    }
  }

  // Add incident to local storage (UI always shows latest data)
  void _addToLocalIncidents(Incident incident) {
    // Add to front of list (newest first)
    _incidents.insert(0, incident);

    // Maintain chart data (last 50 points)
    _chartData.add(incident);
    if (_chartData.length > 50) {
      _chartData.removeAt(0);
    }

    // Update statistics
    _statistics['totalRecords'] =
        (_statistics['totalRecords'] as int?) ?? 0 + 1;
    if (incident.isAlert) {
      _statistics['alertsToday'] =
          (_statistics['alertsToday'] as int?) ?? 0 + 1;
    }
    _statistics['avgGasLevel'] = (_statistics['totalRecords']! > 0)
        ? ((_statistics['avgGasLevel'] as int?) ?? 0 + incident.gasLevel) ~/
              _statistics['totalRecords']!
        : incident.gasLevel;

    notifyListeners();
  }

  // Queue incident for server send with retry logic
  void _queueForServerSend(Incident incident) {
    // Don't queue duplicates (same timestamp within 1 second)
    if (_pendingSends.any(
      (p) =>
          p.incident.timestamp.difference(incident.timestamp).inSeconds.abs() <
          1,
    )) {
      debugPrint('⏭️ Skipping duplicate incident send');
      return;
    }

    final pending = PendingIncident(incident);
    _pendingSends.add(pending);
    debugPrint(
      '📤 Queued critical incident for server send (avg=${incident.gasLevel} PPM)',
    );

    // Start retry timer if not already running
    if (_retryTimer == null) {
      _startRetryTimer();
    }
  }

  // Retry timer with exponential backoff
  void _startRetryTimer() {
    _retryTimer?.cancel();

    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pendingSends.isEmpty) {
        timer.cancel();
        _retryTimer = null;
        return;
      }

      // Process oldest pending incident
      final pending = _pendingSends.first;

      // Check if ready for retry (exponential backoff)
      final elapsed = DateTime.now().difference(pending.lastAttempt);
      final nextDelay = Duration(
        seconds: min(1 << pending.retryCount, 30),
      ); // 1,2,4,8,16,30s max

      if (elapsed < nextDelay) return;

      // Attempt send
      pending.lastAttempt = DateTime.now();
      pending.retryCount++;

      debugPrint(
        '⟳ Retry #${pending.retryCount} for incident ${pending.incident.id} '
        '(next delay: ${nextDelay.inSeconds}s)',
      );

      // Send to server
      ApiService.createIncident(pending.incident)
          .then((success) {
            if (success) {
              debugPrint(
                '✅ Server send successful for incident ${pending.incident.id}',
              );
              _pendingSends.remove(pending);
            } else {
              debugPrint(
                '❌ Server send failed for incident ${pending.incident.id} '
                '(retry ${pending.retryCount}/5)',
              );

              // Stop retrying after 5 attempts
              if (pending.retryCount >= 5) {
                debugPrint(
                  '⚠️ Giving up on incident ${pending.incident.id} after 5 retries',
                );
                _pendingSends.remove(pending);
              }
            }
            notifyListeners();
          })
          .catchError((error) {
            debugPrint('❌ Exception during server send: $error');
            // Keep in queue for next retry
          });
    });
  }

  void disconnectBluetooth() {
    _bluetoothSubscription?.cancel();
    _bluetoothService.disconnect();
    _isBluetoothConnected = false;
    _recentGasLevels.clear();
    notifyListeners();
  }

  // Fetch latest reading FROM SERVER (for historical data sync)
  Future<void> fetchLatestReading() async {
    try {
      final reading = await ApiService.getLatestReading();
      if (reading != null && _latestReading == null) {
        _latestReading = reading;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch latest reading: $e');
    }
  }

  // Fetch incidents FROM SERVER (historical sync)
  Future<void> fetchIncidents({int page = 1, bool loadMore = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!loadMore) {
        _currentPage = 1;
      } else {
        _currentPage = page;
      }

      final incidents = await ApiService.getIncidents(
        page: _currentPage,
        limit: 20,
        status: _filterStatus,
      );

      if (!loadMore) {
        // Merge server incidents with local-only incidents (avoid duplicates)
        final serverIds = incidents.map((i) => i.id).toSet();
        final localOnly = _incidents
            .where((i) => i.id == null || !serverIds.contains(i.id))
            .toList();
        _incidents = [...incidents, ...localOnly];
      } else {
        _incidents.addAll(incidents);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Failed to fetch incidents: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more incidents
  Future<void> loadMoreIncidents() async {
    await fetchIncidents(page: _currentPage + 1, loadMore: true);
  }

  // Fetch statistics FROM SERVER
  Future<void> fetchStatistics() async {
    try {
      _statistics = await ApiService.getStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Failed to fetch statistics: $e');
    }
  }

  // Fetch chart data FROM SERVER
  Future<void> fetchChartData() async {
    try {
      final data = await ApiService.getChartData(limit: 50);
      if (data.isNotEmpty) {
        _chartData = data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch chart data: $e');
    }
  }

  // Refresh all data FROM SERVER (historical sync only)
  Future<void> refreshAllData() async {
    await Future.wait([
      fetchLatestReading(),
      fetchIncidents(),
      fetchStatistics(),
      fetchChartData(),
    ]);
  }

  // Test SERVER connection (not Bluetooth)
  Future<void> testConnection() async {
    _isConnected = await ApiService.testConnection();
    notifyListeners();
  }

  // Initialize provider
  Future<void> initialize() async {
    // Load saved preferences
    await _loadPreferences();

    // Test server connection
    await testConnection();

    // Load historical data if connected
    if (_isConnected) {
      await refreshAllData();
    }

    // Start auto-refresh if enabled
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
      (_) => _isConnected ? refreshAllData() : testConnection(),
    );
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    _retryTimer?.cancel();
    disconnectBluetooth();
    super.dispose();
  }
}

// Pending incident with retry state
class PendingIncident {
  final Incident incident;
  int retryCount = 0;
  DateTime lastAttempt = DateTime.now();

  PendingIncident(this.incident);

  Duration get nextRetryDelay {
    return Duration(
      seconds: (1 << retryCount).clamp(1, 30),
    ); // 1, 2, 4, 8, 16, 30s max
  }
}
