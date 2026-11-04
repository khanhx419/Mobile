import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Color accentColor;
  final bool isGridView;
  final String defaultSort;

  AppSettings({
    this.themeMode = ThemeMode.system,
    this.accentColor = const Color(0xFF2563EB),
    this.isGridView = false,
    this.defaultSort = 'Mới nhất',
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    bool? isGridView,
    String? defaultSort,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      isGridView: isGridView ?? this.isGridView,
      defaultSort: defaultSort ?? this.defaultSort,
    );
  }
}
