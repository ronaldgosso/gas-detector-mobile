import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

class BluetoothService extends ChangeNotifier {
  BluetoothConnection? _connection;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _deviceName;
  String? _deviceAddress;
  DateTime? _lastDataReceived;

  final _dataStreamController = StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataStreamController.stream;

  // Connection timeout (prevents hanging)
  static const Duration _connectionTimeout = Duration(seconds: 10);
  // Data timeout (detects stale connections)
  static const Duration _dataTimeout = Duration(seconds: 15);

  Timer? _dataTimeoutTimer;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get deviceName => _deviceName;
  String? get deviceAddress => _deviceAddress;

  // List bonded (paired) devices filtered for HC-05/HC-06
  Future<List<BluetoothDevice>> getPairedDevices() async {
    final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    
    // Filter for gas sensors (HC-05/HC-06 typically named "HC-05" or similar)
    return devices.where((device) {
      final name = device.name?.toLowerCase() ?? '';
      return name.contains('hc-05') || 
             name.contains('hc-06') || 
             name.contains('gas') || 
             name.contains('sensor');
    }).toList();
  }

  // Connect to device with timeout
  Future<bool> connect(String address) async {
    if (_isConnecting || _isConnected) return false;
    
    _isConnecting = true;
    _deviceAddress = address;
    notifyListeners();

    try {
      // Set timeout for connection attempt
      final connectionFuture = BluetoothConnection.toAddress(address);
      final connection = await Future.any([
        connectionFuture,
        Future.delayed(_connectionTimeout).then((_) => throw TimeoutException('Connection timeout')),
      ]);

      _connection = connection;
      _isConnected = true;
      _isConnecting = false;

      // Get device name from paired list
      final devices = await getPairedDevices();
      final device = devices.firstWhere((d) => d.address == address, orElse: () => BluetoothDevice(address: address, name: 'Unknown Sensor'));
      _deviceName = device.name;

      _listenToStream();
      
      // Start data timeout monitoring
      _resetDataTimeout();
      
      debugPrint('✅ Bluetooth connected to $_deviceName ($address)');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Bluetooth connection failed: $e');
      _isConnected = false;
      _isConnecting = false;
      _deviceName = null;
      _deviceAddress = null;
      notifyListeners();
      return false;
    }
  }

  // Disconnect cleanly
  Future<void> disconnect() async {
    _dataTimeoutTimer?.cancel();
    
    try {
      await _connection?.close();
    } catch (e) {
      debugPrint('Error closing connection: $e');
    } finally {
      _connection?.dispose();
      _connection = null;
      _isConnected = false;
      _isConnecting = false;
      _deviceName = null;
      _deviceAddress = null;
      _lastDataReceived = null;
      notifyListeners();
    }
  }

  // Internal listener for the serial stream
  void _listenToStream() {
    _connection?.input?.listen((Uint8List data) {
      // Reset data timeout on receipt
      _resetDataTimeout();
      
      // Decode data (Arduino typically uses UTF-8)
      String incoming;
      try {
        incoming = utf8.decode(data, allowMalformed: true).trim();
      } catch (e) {
        debugPrint('⚠️ Failed to decode Bluetooth data: $e');
        return;
      }
      
      if (incoming.isNotEmpty) {
        _lastDataReceived = DateTime.now();
        _dataStreamController.add(incoming);
        debugPrint('📡 BT Data: "$incoming"');
      }
    }).onDone(() {
      debugPrint('⚠️ Bluetooth stream closed');
      _handleDisconnection();
    });
  }

  // Reset data timeout timer (detects stale connections)
  void _resetDataTimeout() {
    _dataTimeoutTimer?.cancel();
    _dataTimeoutTimer = Timer(_dataTimeout, () {
      if (_isConnected && _lastDataReceived != null) {
        final elapsed = DateTime.now().difference(_lastDataReceived!);
        if (elapsed > _dataTimeout) {
          debugPrint('⚠️ Bluetooth data timeout (${elapsed.inSeconds}s)');
          _handleDisconnection();
        }
      }
    });
  }

  // Handle disconnection cleanly
  void _handleDisconnection() {
    _isConnected = false;
    _dataTimeoutTimer?.cancel();
    notifyListeners();
    
    // Optional: Auto-reconnect logic (commented for manual control)
    // if (_deviceAddress != null) {
    //   Future.delayed(Duration(seconds: 5), () => connect(_deviceAddress!));
    // }
  }

  @override
  void dispose() {
    _dataTimeoutTimer?.cancel();
    disconnect();
    _dataStreamController.close();
    super.dispose();
  }
}