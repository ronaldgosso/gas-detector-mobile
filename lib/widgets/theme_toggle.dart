import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gas_data_provider.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final gasData = Provider.of<GasDataProvider>(context, listen: false);

    return Consumer<GasDataProvider>(
      builder: (context, provider, child) {
        return IconButton(
          icon: Icon(
            provider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            size: 24,
          ),
          onPressed: () {
            gasData.toggleTheme();

            // Show feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  provider.isDarkMode
                      ? 'Switched to Dark Mode'
                      : 'Switched to Light Mode',
                ),
                duration: const Duration(milliseconds: 800),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          tooltip: provider.isDarkMode ? 'Light Mode' : 'Dark Mode',
        );
      },
    );
  }
}
