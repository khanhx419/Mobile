import 'package:flutter/material.dart';
import '../../models/app_settings.dart';
import '../../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();

  SettingsProvider() {
    _settings = StorageService.loadSettings();
  }

  AppSettings get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  Color get accentColor => _settings.accentColor;
  bool get isGridView => _settings.isGridView;
  String get defaultSort => _settings.defaultSort;

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await StorageService.saveThemeMode(mode);
  }

  Future<void> setAccentColor(Color color) async {
    _settings = _settings.copyWith(accentColor: color);
    notifyListeners();
    await StorageService.saveAccentColor(color);
  }

  Future<void> setViewMode(bool isGridView) async {
    _settings = _settings.copyWith(isGridView: isGridView);
    notifyListeners();
    await StorageService.saveViewMode(isGridView);
  }

  Future<void> setDefaultSort(String sort) async {
    _settings = _settings.copyWith(defaultSort: sort);
    notifyListeners();
    await StorageService.saveDefaultSort(sort);
  }
}
