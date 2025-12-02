import 'package:flutter/material.dart';
import 'chemical_list_screen.dart';
import 'camera_screen.dart';
import 'data_entry_screen.dart';
import 'settings_screen.dart';
import '../services/hive_service.dart';

/// Main home screen with bottom navigation bar
///
/// Features:
/// - Bottom navigation to switch between screens
/// - Smooth fade transitions between tabs
/// - Dark mode toggle (with restart prompt)
/// - Clean singleton usage of HiveService
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Animation for smooth fade transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Properly initialized HiveService singleton
  final HiveService _hiveService = HiveService();

  // List of screens for bottom navigation
  static const List<Widget> _screens = [
    ChemicalListScreen(),
    CameraScreen(),
    DataEntryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize fade animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start fade-in on first load
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Handle bottom navigation tap with smooth fade transition
  void _onNavigationItemSelected(int index) {
    if (index == _currentIndex) return;

    // Fade out → change screen → fade in
    _animationController.reverse().then((_) {
      setState(() {
        _currentIndex = index;
      });
      _animationController.forward();
    });
  }

  /// Toggle dark/light mode
  void _toggleTheme() {
    final bool currentMode = _hiveService.getDarkMode();
    final bool newMode = !currentMode;

    _hiveService.setDarkMode(newMode);

    // Update UI immediately (optional visual feedback)
    setState(() {});

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newMode ? 'Dark mode enabled' : 'Light mode enabled'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Show restart dialog
    _showRestartDialog();
  }

  /// Show dialog informing user to restart app for theme to take effect
  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline),
        title: const Text('Theme Changed'),
        content: const Text(
          'The app needs to be restarted for the theme change to take full effect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      // Main content with fade transition
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _screens[_currentIndex],
      ),

      // Modern Material 3 Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavigationItemSelected,
        animationDuration: const Duration(milliseconds: 600),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, size: 28),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt, size: 28),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box, size: 28),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, size: 28),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}