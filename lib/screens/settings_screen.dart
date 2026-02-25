import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gas_data_provider.dart';
import '../widgets/theme_toggle.dart';

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

  bool _autoRefresh = true;
  bool _notificationsEnabled = true;
  String _themeMode = 'light';

  @override
  void initState() {
    super.initState();
    // Load current values from Provider
    Future.delayed(Duration.zero, () {
      final gasData = Provider.of<GasDataProvider>(context, listen: false);
      _serverIpController.text = gasData.serverIp;
      _serverPortController.text = gasData.serverPort;
      _refreshIntervalController.text = gasData.refreshInterval.toString();
      setState(() {
        _autoRefresh = gasData.autoRefresh;
      });
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
                        hintText: '192.168.1.100',
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
                    SwitchListTile(
                      title: const Text('Notifications'),
                      subtitle: const Text('Enable alert notifications'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      secondary: const Icon(Icons.notifications_active),
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
