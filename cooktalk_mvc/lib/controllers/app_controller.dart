import 'package:flutter/material.dart';

class AppController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  int _tabIndex = 0;

  ThemeMode get themeMode => _themeMode;
  int get tabIndex => _tabIndex;

  /// 초기화 메서드 (필요 시 SharedPreferences 등에서 설정 로드)
  Future<void> initialize() async {
    // TODO: SharedPreferences에서 테마 설정 로드
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setTab(int index) {
    _tabIndex = index;
    notifyListeners();
  }
}
