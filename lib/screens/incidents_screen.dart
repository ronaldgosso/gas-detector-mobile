import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/gas_data_provider.dart';
import '../widgets/incident_card.dart';
import '../widgets/theme_toggle.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({super.key});

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<GasDataProvider>(context, listen: false).fetchIncidents();
    });
  }

  void _onRefresh() async {
    await Provider.of<GasDataProvider>(context, listen: false).fetchIncidents();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    await Provider.of<GasDataProvider>(
      context,
      listen: false,
    ).loadMoreIncidents();
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident History'),
        actions: [ThemeToggle()],
      ),
      body: Consumer<GasDataProvider>(
        builder: (context, gasData, child) {
          return SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            enablePullUp: true,
            child: Column(
              children: [
                // Filter Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FilterButton(
                        label: 'All',
                        isActive: _filterStatus == 'all',
                        onPressed: () => _setFilter('all', gasData),
                      ),
                      _FilterButton(
                        label: 'Alerts',
                        isActive: _filterStatus == 'ALERT',
                        onPressed: () => _setFilter('ALERT', gasData),
                        activeColor: Colors.red,
                      ),
                      _FilterButton(
                        label: 'Normal',
                        isActive: _filterStatus == 'NORMAL',
                        onPressed: () => _setFilter('NORMAL', gasData),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),

                // Incidents List
                Expanded(
                  child: gasData.isLoading && gasData.incidents.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : gasData.incidents.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 60,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No incidents recorded',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Gas readings will appear here',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: gasData.incidents.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return IncidentCard(
                              incident: gasData.incidents[index],
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _setFilter(String status, GasDataProvider gasData) {
    setState(() {
      _filterStatus = status;
    });
    gasData.filterStatus = status;
    gasData.fetchIncidents();
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;
  final Color? activeColor;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final activeBgColor = activeColor ?? Colors.blue;
    final textColor = isActive
        ? Colors.white
        : (isDark ? Colors.grey[300] : Colors.grey[700]);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? activeBgColor
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
