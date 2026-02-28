import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gas_data_provider.dart';
import '../widgets/theme_toggle.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serverIpController;
  late TextEditingController _serverPortController;
  late TextEditingController _refreshIntervalController;
  List<BluetoothDevice> _pairedDevices = [];
  BluetoothDevice? _selectedDevice;

  bool _autoRefresh = true;
  String _themeMode = 'light';

  @override
  void initState() {
    super.initState();
    final gasData = Provider.of<GasDataProvider>(context, listen: false);
    _serverIpController = TextEditingController(text: gasData.serverIp);
    _serverPortController = TextEditingController(text: gasData.serverPort);
    _refreshIntervalController = TextEditingController(
      text: gasData.refreshInterval.toString(),
    );
    _autoRefresh = gasData.autoRefresh;
    _getBluetoothDevices();
  }

  void _getBluetoothDevices() async {
    final gasData = Provider.of<GasDataProvider>(context, listen: false);
    final devices = await gasData.bluetoothService.getPairedDevices();
    setState(() {
      _pairedDevices = devices;
    });
  }

  @override
  void dispose() {
    _serverIpController.dispose();
    _serverPortController.dispose();
    _refreshIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), actions: [ThemeToggle()]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server Configuration Card
              _SettingsCard(
                title: 'Server Configuration',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _serverIpController,
                      decoration: const InputDecoration(
                        labelText: 'Server IP Address',
                        hintText: '127.0.0.0',
                        prefixIcon: Icon(Icons.cloud),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter server IP';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _serverPortController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Server Port',
                        hintText: '3000',
                        prefixIcon: Icon(Icons.network_check),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter port number';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid port number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Monitoring Settings Card
              _SettingsCard(
                title: 'Monitoring Settings',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _refreshIntervalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Auto-refresh Interval (seconds)',
                        hintText: '2',
                        prefixIcon: Icon(Icons.refresh),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter refresh interval';
                        }
                        final interval = int.tryParse(value);
                        if (interval == null || interval < 1 || interval > 60) {
                          return 'Interval must be between 1-60 seconds';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('Auto-refresh'),
                      subtitle: const Text('Automatically refresh data'),
                      value: _autoRefresh,
                      onChanged: (value) {
                        setState(() {
                          _autoRefresh = value;
                        });
                      },
                      secondary: const Icon(Icons.autorenew),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Bluetooth Configuration Card
              _SettingsCard(
                title: 'Bluetooth Pulse Bridge (HC-05)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select your HC-05 module to start bridging data to your PC server in real-time.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BluetoothDevice>(
                      value: _selectedDevice,
                      hint: const Text('Select Bluetooth Device'),
                      decoration: const InputDecoration(
                        labelText: 'HC-05 Device',
                        prefixIcon: Icon(Icons.bluetooth),
                      ),
                      items: _pairedDevices.map((device) {
                        return DropdownMenuItem(
                          value: device,
                          child: Text(device.name ?? device.address),
                        );
                      }).toList(),
                      onChanged: (device) {
                        setState(() {
                          _selectedDevice = device;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer<GasDataProvider>(
                      builder: (context, gasData, child) {
                        final isBtConnected =
                            gasData.bluetoothService.isConnected;
                        final isConnecting =
                            gasData.bluetoothService.isConnecting;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _selectedDevice == null ||
                                            isBtConnected ||
                                            isConnecting
                                        ? null
                                        : () => gasData.connectBluetooth(
                                            _selectedDevice!.address,
                                          ),
                                    icon: isConnecting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.link),
                                    label: Text(
                                      isConnecting
                                          ? 'Connecting...'
                                          : 'Connect Pulse',
                                    ),
                                  ),
                                ),
                                if (isBtConnected) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          gasData.disconnectBluetooth(),
                                      icon: const Icon(Icons.link_off),
                                      label: const Text('Disconnect'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isBtConnected
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isBtConnected
                                        ? Icons.bluetooth_connected
                                        : Icons.bluetooth_disabled,
                                    color: isBtConnected
                                        ? Colors.blue
                                        : Colors.grey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isBtConnected
                                        ? 'Bridging data from ${gasData.bluetoothService.deviceName}'
                                        : 'Bluetooth Bridge Offline',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isBtConnected
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Theme Settings Card
              _SettingsCard(
                title: 'Appearance',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _themeMode,
                      decoration: const InputDecoration(
                        labelText: 'Theme Mode',
                        prefixIcon: Icon(Icons.palette),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'light',
                          child: Text('Light Mode'),
                        ),
                        DropdownMenuItem(
                          value: 'dark',
                          child: Text('Dark Mode'),
                        ),
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('System Default'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _themeMode = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _testConnection,
                      icon: const Icon(Icons.cloud_done),
                      label: const Text('Test Connection'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Connection Status
              Consumer<GasDataProvider>(
                builder: (context, gasData, child) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: gasData.isConnected
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: gasData.isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          gasData.isConnected
                              ? Icons.check_circle
                              : Icons.error,
                          color: gasData.isConnected
                              ? Colors.green
                              : Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          gasData.isConnected
                              ? 'Connected to server'
                              : 'Not connected to server',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _testConnection() async {
    final gasData = Provider.of<GasDataProvider>(context, listen: false);
    await gasData.testConnection();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            gasData.isConnected
                ? 'Connection successful!'
                : 'Connection failed. Check server settings.',
          ),
          backgroundColor: gasData.isConnected ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final gasData = Provider.of<GasDataProvider>(context, listen: false);

      await gasData.updateSettings(
        ip: _serverIpController.text,
        port: _serverPortController.text,
        interval: int.parse(_refreshIntervalController.text),
        autoRefresh: _autoRefresh,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: dividerColor, height: 1),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
