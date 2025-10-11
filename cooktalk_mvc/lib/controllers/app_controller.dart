import 'package:flutter/material.dart';

class AppController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  int _tabIndex = 0;

  ThemeMode get themeMode => _themeMode;
  int get tabIndex => _tabIndex;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setTab(int index) {
    _tabIndex = index;
    notifyListeners();
  }
}
