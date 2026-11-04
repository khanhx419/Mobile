import 'dart:convert';

import 'package:daily_you/main_web.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/web/journal_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BrowserJournalStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = BrowserJournalStore(await SharedPreferences.getInstance());
    await initializeDateFormatting('vi');
  });
  final sample = BrowserEntry(
      title: 'Một ngày đáng nhớ',
      tags: 'Gia đình',
      entry: Entry(
          id: 1,
          text: 'Biết ơn những điều nhỏ bé.',
          mood: 1,
          timeCreate: DateTime(2026, 10, 26),
          timeModified: DateTime(2026, 10, 26)));

  test('save, reload and backup restore preserve Vietnamese and dates',
      () async {
    await store.save([sample]);
    final reloaded = BrowserJournalStore(store.preferences)..load();
    expect(reloaded.entries.single.toJson(), sample.toJson());
    expect(BrowserJournalStore.decode(store.encode()).single.toJson(),
        sample.toJson());
  });
  test('invalid backup is rejected without changing the existing journal',
      () async {
    await store.save([sample]);
    for (final raw in [
      '{}',
      '{bad json',
      jsonEncode({
        'format': 'nhat-ky-viet-web',
        'version': 1,
        'entries': [sample.toJson(), sample.toJson()]
      })
    ]) {
      expect(() => BrowserJournalStore.decode(raw),
          throwsA(isA<FormatException>()));
      expect(store.entries.single.toJson(), sample.toJson());
    }
  });
  testWidgets('create, search, edit and delete a diary entry in Vietnamese',
      (tester) async {
    await tester.pumpWidget(WebJournalApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Viết nhật ký'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Ngày bình yên');
    await tester.enterText(
        find.byType(TextField).at(2), 'Hôm nay tôi thấy rất vui.');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(store.entries.single.title, 'Ngày bình yên');
    await tester.enterText(find.byType(TextField), 'không tồn tại');
    await tester.pumpAndSettle();
    expect(find.text('Ngày bình yên'), findsNothing);
    await tester.enterText(find.byType(TextField), 'bình yên');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ngày bình yên'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Ngày thật bình yên');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(store.entries.single.title, 'Ngày thật bình yên');
    await tester.tap(find.byTooltip('Tùy chọn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa nhật ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(store.entries, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('navigation and Vietnamese layout work at 320 px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await store.save([sample]);
    await tester.pumpWidget(WebJournalApp(store: store));
    await tester.pumpAndSettle();
    for (final page in ['Thư viện', 'Thống kê', 'Cài đặt', 'Trang chủ']) {
      await tester.tap(find.text(page).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('failed save keeps the draft available for retry',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: JournalEditor(onSave: (_) async => false)));
    await tester.enterText(find.byType(TextField).at(0), 'Nội dung chưa lưu');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Nội dung chưa lưu'), findsOneWidget);
    expect(
        find.text(
            'Chưa lưu được. Nội dung vẫn ở đây; hãy giảm số ảnh và thử lại.'),
        findsOneWidget);
  });
}
