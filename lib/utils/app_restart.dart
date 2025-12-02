import 'package:flutter/material.dart';

/// Utility class to restart the app
///
/// This creates a widget that rebuilds the entire app tree
/// when the rebuild method is called
class AppRestartWidget extends StatefulWidget {
  final Widget child;

  const AppRestartWidget({
    super.key,
    required this.child,
  });

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_AppRestartWidgetState>()?.restartApp();
  }

  @override
  State<AppRestartWidget> createState() => _AppRestartWidgetState();
}

class _AppRestartWidgetState extends State<AppRestartWidget> {
  Key _key = UniqueKey();

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}