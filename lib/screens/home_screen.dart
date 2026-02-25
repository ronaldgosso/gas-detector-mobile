import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/gas_data_provider.dart';
import '../widgets/gas_level_card.dart';
import '../widgets/incident_card.dart';
import '../widgets/theme_toggle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<GasDataProvider>(context, listen: false).initialize();
    });
  }

  void _onRefresh() async {
    await Provider.of<GasDataProvider>(context, listen: false).refreshAllData();
    _refreshController.refreshCompleted();
  }

  GasDataProvider? gasData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas Guard Monitor'),
        centerTitle: true,
        actions: [
          ThemeToggle(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: Consumer<GasDataProvider>(
          builder: (context, gasData, child) {
            this.gasData = gasData;
            if (!gasData.isConnected) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    const Text(
                      'No Connection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Unable to connect to server',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => gasData.initialize(),
                      child: const Text('Retry Connection'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gas Level Card
                  const GasLevelCard(),
                  const SizedBox(height: 20),

                  // Quick Stats
                  _buildQuickStats(gasData),

                  const SizedBox(height: 20),

                  // Recent Incidents Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Incidents',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/incidents');
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Incidents List
                  ...gasData.incidents
                      .take(5)
                      .map((incident) => IncidentCard(incident: incident)),
                  if (gasData.incidents.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No incidents recorded',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => gasData?.refreshAllData(),
        backgroundColor: Colors.blue,
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildQuickStats(GasDataProvider gasData) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'Total',
              value: '${gasData.statistics['totalRecords'] ?? 0}',
              icon: Icons.dvr,
            ),
            _StatItem(
              label: 'Alerts Today',
              value: '${gasData.statistics['alertsToday'] ?? 0}',
              icon: Icons.warning_amber,
              color: Colors.orange,
            ),
            _StatItem(
              label: 'Avg Level',
              value: '${gasData.statistics['avgGasLevel'] ?? 0}',
              icon: Icons.show_chart,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color ?? Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
