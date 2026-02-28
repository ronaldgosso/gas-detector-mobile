import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

class BluetoothService extends ChangeNotifier {
  BluetoothConnection? _connection;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _deviceName;

  final _dataStreamController = StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataStreamController.stream;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get deviceName => _deviceName;

  // List bonded (paired) devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  // Connect to device
  Future<bool> connect(String address) async {
    _isConnecting = true;
    notifyListeners();

    try {
      _connection = await BluetoothConnection.toAddress(address);
      _isConnected = true;
      _isConnecting = false;

      // Get device name from paired list
      final devices = await getPairedDevices();
      final device = devices.firstWhere((d) => d.address == address);
      _deviceName = device.name;

      _listenToStream();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Bluetooth connection failed: $e');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  // Disconnect
  Future<void> disconnect() async {
    await _connection?.close();
    _connection?.dispose();
    _connection = null;
    _isConnected = false;
    _deviceName = null;
    notifyListeners();
  }

  // Internal listener for the serial stream
  void _listenToStream() {
    _connection?.input
        ?.listen((Uint8List data) {
          // Data from Arduino is usually sent as strings followed by \r\n
          String incoming = utf8.decode(data);
          _dataStreamController.add(incoming);
          debugPrint("Incoming BT data $incoming");
        })
        .onDone(() {
          _isConnected = false;
          _deviceName = null;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    disconnect();
    _dataStreamController.close();
    super.dispose();
  }
}
