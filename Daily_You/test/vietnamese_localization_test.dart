import 'dart:convert';
import 'dart:io';

import 'package:daily_you/app_locale.dart';
import 'package:daily_you/config_provider.dart';
import 'package:daily_you/custom_locale_delegates.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Vietnamese covers every message and preserves ICU arguments', () {
    final english = jsonDecode(File('lib/l10n/intl_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    final vietnamese =
        jsonDecode(File('lib/l10n/intl_vi.arb').readAsStringSync())
            as Map<String, dynamic>;
    final keys = english.keys.where((key) => !key.startsWith('@')).toSet();
    expect(vietnamese.keys.where((key) => !key.startsWith('@')).toSet(), keys);
    final arguments = RegExp(r'\{(\w+)(?=[},])');
    for (final key in keys) {
      final translation = vietnamese[key] as String;
      expect(translation.trim(), isNotEmpty, reason: key);
      expect(
        arguments.allMatches(translation).map((m) => m[1]).toSet(),
        arguments.allMatches(english[key] as String).map((m) => m[1]).toSet(),
        reason: key,
      );
    }
  });

  test('fresh installation uses Vietnamese even on an English device', () {
    expect(ConfigProvider.instance.getOverrideLanguage(), const Locale('vi'));
    expect(resolveAppLocale(const Locale('en', 'US')), const Locale('vi'));
  });

  testWidgets('Vietnamese text and system controls fit a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...appLocalizationsDelegates,
      ],
      home: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.pageSettingsTitle)),
          body: ListView(children: [
            ListTile(title: Text(l10n.settingsOverrideAppLanguageTitle)),
            ListTile(title: Text(l10n.settingsSecurityBiometricUnlock)),
            Text(l10n.logCount(12)),
            Text(l10n.creatingBackupStatus(50)),
            Text(l10n.flashbackMonth(3)),
            Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ]),
        );
      }),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('12 nhật ký'), findsOneWidget);
    expect(find.text('Đang tạo bản sao lưu… 50%'), findsOneWidget);
    expect(find.text('3 tháng trước'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
