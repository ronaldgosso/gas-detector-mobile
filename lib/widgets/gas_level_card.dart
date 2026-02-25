import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gas_data_provider.dart';

class GasLevelCard extends StatelessWidget {
  const GasLevelCard({super.key});

  @override
  Widget build(BuildContext context) {
    final gasData = Provider.of<GasDataProvider>(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Gas Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                StatusIndicator(status: gasData.currentStatus, size: 12),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '${gasData.gasLevel}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: gasData.isAlert ? Colors.red : Colors.blue,
                shadows: [
                  Shadow(
                    color: gasData.isAlert
                        ? Colors.red.withValues(alpha: 0.5)
                        : Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PPM',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: gasData.isAlert
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                gasData.isAlert ? 'ALERT - High Gas Level' : 'NORMAL',
                style: TextStyle(
                  color: gasData.isAlert ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: gasData.gasLevel / 1023,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                gasData.gasLevel > 800
                    ? Colors.red
                    : gasData.gasLevel > 400
                    ? Colors.orange
                    : Colors.green,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0 PPM',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  '1023 PPM',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final String status;
  final double size;

  const StatusIndicator({super.key, required this.status, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final color = status == 'ALERT' ? Colors.red : Colors.green;
    final label = status == 'ALERT' ? 'Danger' : 'Safe';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
