import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Check the platform brightness
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return _themeMode == ThemeMode.dark;
    }
  }

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notify listeners about the change
  }
}
