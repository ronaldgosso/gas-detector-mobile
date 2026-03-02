import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incident_model.dart';
import '../services/api_service.dart';
import '../services/bluetooth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CHANGES FROM ORIGINAL:
//  1. Removed `flutter_bluetooth_serial` import — no longer needed.
//     bluetooth_classic is fully managed inside BluetoothService.
//  2. connectBluetooth() now accepts optional `deviceName` parameter and
//     passes it through to BluetoothService.connect().
//  3. Removed FlutterBluetoothSerial.instance.requestEnable() and
//     FlutterBluetoothSerial.instance.state calls — bluetooth_classic
//     handles permissions via BluetoothService.initPermissions() in main.dart.
//  4. _startBluetoothBridging() buffer logic removed — BluetoothService
//     already emits complete \n-terminated lines on its dataStream, so
//     double-buffering here would corrupt data.
//  5. All business logic preserved: rolling average, critical threshold,
//     retry queue with exponential backoff, local stats, chart data.
// ─────────────────────────────────────────────────────────────────────────────

class GasDataProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Incident? _latestReading;
  List<Incident> _incidents = [];
  List<Incident> _chartData = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  bool _isConnected = false;       // Server connection status
  bool _isBluetoothConnected = false;
  int _currentPage = 1;
  String _filterStatus = 'all';

  // Server settings
  String _serverIp = 'https://gas-detector-api.vercel.app';
  String _serverPort = '3500';
  int _refreshInterval = 5;
  bool _autoRefresh = true;

  // Bluetooth bridge
  final BluetoothService _bluetoothService = BluetoothService();
  StreamSubscription<String>? _bluetoothSubscription;

  // Rolling buffer — last 3 readings for averaging
  final List<int> _recentGasLevels = [];
  static const int _bufferSize = 3;
  static const int _criticalThreshold = 800; // PPM

  // Retry queue for failed server sends
  final List<PendingIncident> _pendingSends = [];
  Timer? _retryTimer;
  Timer? _autoRefreshTimer;

  // ── Getters ──────────────────────────────────────────────────────────────

  BluetoothService get bluetoothService => _bluetoothService;

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

  // ── Setters ──────────────────────────────────────────────────────────────

  set filterStatus(String value) {
    _filterStatus = value;
    notifyListeners();
  }

  // ── Theme ────────────────────────────────────────────────────────────────

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    _savePreferences();
  }

  // ── Preferences ──────────────────────────────────────────────────────────

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
    _serverIp =
        prefs.getString('serverIp') ?? 'https://gas-detector-api.vercel.app';
    _serverPort = prefs.getString('serverPort') ?? '3000';
    _refreshInterval = prefs.getInt('refreshInterval') ?? 5;
    _autoRefresh = prefs.getBool('autoRefresh') ?? true;

    ApiService.updateBaseUrl(
      _serverIp == 'https://gas-detector-api.vercel.app'
          ? 'https://gas-detector-api.vercel.app'
          : 'http://$_serverIp:$_serverPort',
    );
    notifyListeners();
  }

  // ── Settings ─────────────────────────────────────────────────────────────

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
      _serverIp == 'https://gas-detector-api.vercel.app'
          ? 'https://gas-detector-api.vercel.app'
          : 'http://$_serverIp:$_serverPort',
    );
    await _savePreferences();
    await testConnection();

    if (_autoRefresh && _isConnected) {
      startAutoRefresh(interval: _refreshInterval);
    } else {
      stopAutoRefresh();
    }

    notifyListeners();
  }

  // ── Bluetooth ────────────────────────────────────────────────────────────

  /// Connect to an HC-05 device by MAC address.
  /// [deviceName] is optional but shown in the UI and incident location.
  Future<void> connectBluetooth(
    String address, {
    String? deviceName,
  }) async {
    // Clean up any existing connection first
    if (_isBluetoothConnected) {
      disconnectBluetooth();
    }

    // bluetooth_classic: permissions are handled in main.dart via
    // bluetoothService.initPermissions() — no manual enable request needed.
    final success = await _bluetoothService.connect(
      address,
      deviceName: deviceName,
    );

    _isBluetoothConnected = success;

    if (success) {
      _startBluetoothBridging();
      debugPrint('✅ Bluetooth bridge active for ${deviceName ?? address}');
    } else {
      debugPrint('❌ Bluetooth connection failed for $address');
    }

    notifyListeners();
  }

  /// Listens to the already-buffered line stream from BluetoothService.
  /// BluetoothService emits complete \n-terminated lines so NO extra
  /// buffering is needed here — doing so would corrupt multi-chunk messages.
  void _startBluetoothBridging() {
    _bluetoothSubscription?.cancel();

    _bluetoothSubscription = _bluetoothService.dataStream.listen(
      (line) {
        // Each emission is already a complete, trimmed line
        if (line.isNotEmpty) {
          _processBluetoothData(line);
        }
      },
      onError: (error) {
        debugPrint('❌ Bluetooth stream error in provider: $error');
        _isBluetoothConnected = false;
        notifyListeners();
      },
      onDone: () {
        debugPrint('⚠️ Bluetooth stream done in provider');
        _isBluetoothConnected = false;
        notifyListeners();
      },
    );
  }

  /// Parses a complete line from the HC-05 and triggers UI + server logic.
  /// Supports two Arduino formats:
  ///   "GAS:512,ALERT"  — structured with status
  ///   "512"            — raw integer PPM value
  void _processBluetoothData(String data) {
    debugPrint('📡 Raw BT line: "$data"');

    int? gasLevel;
    String status = 'NORMAL';

    if (data.startsWith('GAS:')) {
      // Format: "GAS:512,ALERT"
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
    } else {
      // Format: raw integer "512"
      gasLevel = int.tryParse(data.trim());
    }

    // Validate
    if (gasLevel == null || gasLevel < 0 || gasLevel > 1023) {
      debugPrint('⚠️ Invalid gas level: "$data" → $gasLevel');
      return;
    }

    // Auto-derive status if Arduino didn't send one
    if (status == 'NORMAL' && gasLevel > 400) {
      status = 'ALERT';
    }

    final incident = Incident(
      gasLevel: gasLevel,
      status: status,
      timestamp: DateTime.now(),
      location:
          'Mobile Sensor (${_bluetoothService.deviceName ?? "HC-05"})',
    );

    // 1. Update UI immediately
    _latestReading = incident;
    _addToLocalIncidents(incident);
    notifyListeners();

    // 2. Add to rolling buffer
    _recentGasLevels.add(gasLevel);
    if (_recentGasLevels.length > _bufferSize) {
      _recentGasLevels.removeAt(0);
    }

    // 3. Only send to server when rolling average crosses critical threshold
    if (_recentGasLevels.length >= _bufferSize) {
      final avgLevel =
          _recentGasLevels.reduce((a, b) => a + b) / _bufferSize;
      debugPrint(
        '📊 Rolling avg (last $_bufferSize): ${avgLevel.toStringAsFixed(1)} PPM',
      );

      if (avgLevel > _criticalThreshold) {
        _queueForServerSend(
          incident.copyWith(
            gasLevel: avgLevel.round(),
            status: 'ALERT',
            location: '${incident.location} (Avg)',
          ),
        );
      }
    }
  }

  void disconnectBluetooth() {
    _bluetoothSubscription?.cancel();
    _bluetoothSubscription = null;
    _bluetoothService.disconnect();
    _isBluetoothConnected = false;
    _recentGasLevels.clear();
    notifyListeners();
  }

  // ── Local data ───────────────────────────────────────────────────────────

  void _addToLocalIncidents(Incident incident) {
    // Newest first
    _incidents.insert(0, incident);

    // Rolling chart window (last 50 points)
    _chartData.add(incident);
    if (_chartData.length > 50) {
      _chartData.removeAt(0);
    }

    // Running statistics
    final total = ((_statistics['totalRecords'] as int?) ?? 0) + 1;
    _statistics['totalRecords'] = total;

    if (incident.isAlert) {
      _statistics['alertsToday'] =
          ((_statistics['alertsToday'] as int?) ?? 0) + 1;
    }

    final prevAvg = (_statistics['avgGasLevel'] as int?) ?? 0;
    _statistics['avgGasLevel'] =
        ((prevAvg * (total - 1)) + incident.gasLevel) ~/ total;

    notifyListeners();
  }

  // ── Server retry queue ───────────────────────────────────────────────────

  void _queueForServerSend(Incident incident) {
    // Skip near-duplicate timestamps (within 1 second)
    if (_pendingSends.any(
      (p) =>
          p.incident.timestamp
              .difference(incident.timestamp)
              .inSeconds
              .abs() <
          1,
    )) {
      debugPrint('⏭️ Skipping duplicate incident send');
      return;
    }

    _pendingSends.add(PendingIncident(incident));
    debugPrint(
      '📤 Queued critical incident (avg=${incident.gasLevel} PPM)',
    );

    _retryTimer ??= _startRetryTimer();
  }

  Timer _startRetryTimer() {
    return Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pendingSends.isEmpty) {
        timer.cancel();
        _retryTimer = null;
        return;
      }

      final pending = _pendingSends.first;
      final elapsed = DateTime.now().difference(pending.lastAttempt);
      final nextDelay = Duration(seconds: min(1 << pending.retryCount, 30));

      if (elapsed < nextDelay) return;

      pending.lastAttempt = DateTime.now();
      pending.retryCount++;

      debugPrint(
        '⟳ Retry #${pending.retryCount} for incident ${pending.incident.id} '
        '(backoff: ${nextDelay.inSeconds}s)',
      );

      ApiService.createIncident(pending.incident).then((success) {
        if (success) {
          debugPrint(
            '✅ Server send successful: ${pending.incident.id}',
          );
          _pendingSends.remove(pending);
        } else {
          debugPrint(
            '❌ Server send failed: ${pending.incident.id} '
            '(attempt ${pending.retryCount}/5)',
          );
          if (pending.retryCount >= 5) {
            debugPrint(
              '⚠️ Giving up on ${pending.incident.id} after 5 retries',
            );
            _pendingSends.remove(pending);
          }
        }
        notifyListeners();
      }).catchError((error) {
        debugPrint('❌ Exception during server send: $error');
      });
    });
  }

  // ── Server data fetching ─────────────────────────────────────────────────

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

  Future<void> fetchIncidents({int page = 1, bool loadMore = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentPage = loadMore ? page : 1;

      final serverIncidents = await ApiService.getIncidents(
        page: _currentPage,
        limit: 20,
        status: _filterStatus,
      );

      if (!loadMore) {
        // Merge: keep local-only incidents (no server ID) alongside server data
        final serverIds = serverIncidents.map((i) => i.id).toSet();
        final localOnly = _incidents
            .where((i) => i.id == null || !serverIds.contains(i.id))
            .toList();
        _incidents = [...serverIncidents, ...localOnly];
      } else {
        _incidents.addAll(serverIncidents);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch incidents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreIncidents() async {
    await fetchIncidents(page: _currentPage + 1, loadMore: true);
  }

  Future<void> fetchStatistics() async {
    try {
      _statistics = await ApiService.getStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Failed to fetch statistics: $e');
    }
  }

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

  Future<void> refreshAllData() async {
    await Future.wait([
      fetchLatestReading(),
      fetchIncidents(),
      fetchStatistics(),
      fetchChartData(),
    ]);
  }

  Future<void> testConnection() async {
    _isConnected = await ApiService.testConnection();
    notifyListeners();
  }

  // ── Initialisation ───────────────────────────────────────────────────────

  Future<void> initialize() async {
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

  // ── Auto-refresh ─────────────────────────────────────────────────────────

  void startAutoRefresh({int interval = 2}) {
    stopAutoRefresh();
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: interval),
      (_) => _isConnected ? refreshAllData() : testConnection(),
    );
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  // ── Cleanup ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    stopAutoRefresh();
    _retryTimer?.cancel();
    _bluetoothSubscription?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending incident with retry state
// ─────────────────────────────────────────────────────────────────────────────

class PendingIncident {
  final Incident incident;
  int retryCount = 0;
  DateTime lastAttempt = DateTime.now();

  PendingIncident(this.incident);

  Duration get nextRetryDelay =>
      Duration(seconds: (1 << retryCount).clamp(1, 30));
}