import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/app_settings.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // In test environments or unsupported headless channels
    }
  }

  static void setMockPreferences(SharedPreferences prefs) {
    _prefs = prefs;
  }

  static AppSettings loadSettings() {
    if (_prefs == null) return AppSettings();

    final themeStr = _prefs!.getString(AppConstants.prefThemeMode);
    ThemeMode themeMode = ThemeMode.system;
    if (themeStr == 'light') themeMode = ThemeMode.light;
    if (themeStr == 'dark') themeMode = ThemeMode.dark;

    final colorValue = _prefs!.getInt(AppConstants.prefAccentColor) ?? AppColors.primaryBlue.value;
    final isGrid = _prefs!.getBool(AppConstants.prefViewMode) ?? false;
    final sort = _prefs!.getString(AppConstants.prefDefaultSort) ?? AppConstants.sortDateDesc;

    return AppSettings(
      themeMode: themeMode,
      accentColor: Color(colorValue),
      isGridView: isGrid,
      defaultSort: sort,
    );
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    if (_prefs == null) return;
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await _prefs!.setString(AppConstants.prefThemeMode, val);
  }

  static Future<void> saveAccentColor(Color color) async {
    if (_prefs == null) return;
    await _prefs!.setInt(AppConstants.prefAccentColor, color.value);
  }

  static Future<void> saveViewMode(bool isGridView) async {
    if (_prefs == null) return;
    await _prefs!.setBool(AppConstants.prefViewMode, isGridView);
  }

  static Future<void> saveDefaultSort(String sort) async {
    if (_prefs == null) return;
    await _prefs!.setString(AppConstants.prefDefaultSort, sort);
  }
}
