import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/hive_service.dart';
import 'utils/theme_helper.dart';
import 'utils/app_restart.dart';

/// Main entry point of the application
///
/// Initializes:
/// - Hive database for offline caching
/// - Material app with theme management
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive database for offline storage
  await HiveService.initialize();

  // Run the app with restart wrapper
  runApp(
    const AppRestartWidget(
      child: ChemicalInventoryApp(),
    ),
  );
}

/// Root widget of the application
class ChemicalInventoryApp extends StatefulWidget {
  const ChemicalInventoryApp({super.key});

  @override
  State<ChemicalInventoryApp> createState() => _ChemicalInventoryAppState();
}

class _ChemicalInventoryAppState extends State<ChemicalInventoryApp> {
  final HiveService _hiveService = HiveService();

  @override
  Widget build(BuildContext context) {
    // Get dark mode preference from Hive
    final isDarkMode = _hiveService.getDarkMode();

    return MaterialApp(
      title: 'Chemical Inventory',
      debugShowCheckedModeBanner: false,

      // Apply theme based on saved preference
      theme: ThemeHelper.lightTheme,
      darkTheme: ThemeHelper.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Home screen with bottom navigation
      home: const HomeScreen(),
    );
  }
}