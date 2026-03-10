import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/gas_data_provider.dart';
import 'screens/home_screen.dart';
import 'screens/incidents_screen.dart';
import 'screens/settings_screen.dart';
import 'themes/light_theme.dart'; // Import light theme
import 'themes/dark_theme.dart'; // Import dark theme

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GasDataProvider(),
      child: Consumer<GasDataProvider>(
        builder: (context, gasData, child) {
          return MaterialApp(
            title: 'Gas Guard Monitor',
            debugShowCheckedModeBanner: false,

            // Use imported theme files
            theme: lightTheme, // Light theme definition
            darkTheme: darkTheme, // Dark theme definition
            // Switch between themes based on provider state
            themeMode: gasData.isDarkMode ? ThemeMode.dark : ThemeMode.light,

            // Routes
            initialRoute: '/',
            routes: {
              '/': (context) => const HomeScreen(),
              '/incidents': (context) => const IncidentsScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
