// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Share locale selection between the UI and initial journal content.
Locale resolveAppLocale(Locale? deviceLocale) {
  final override = ConfigProvider.instance.getOverrideLanguage();
  if (override != null) return override;
  if (deviceLocale != null) {
    if (AppLocalizations.supportedLocales.contains(deviceLocale)) {
      return deviceLocale;
    }
    for (final supported in AppLocalizations.supportedLocales) {
      if (supported.languageCode == deviceLocale.languageCode) return supported;
    }
  }
  return const Locale('vi');
}
