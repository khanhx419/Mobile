import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:english_discipline/main.dart';
import 'package:english_discipline/platform.dart';

void main() {
  testWidgets('learner completes practice, sees feedback and saved history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Each widget test uses a fresh isolated database directory.
    await tester.runAsync(() async {
      await databaseFactory.setDatabasesPath(
        '${(await databaseFactory.getDatabasesPath())}/widget_th3',
      );
      await databaseFactory.deleteDatabase(
        '${await databaseFactory.getDatabasesPath()}/english_th3.db',
      );
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SpeechPlatform.channel, (call) async {
          if (call.method == 'listen') {
            return {'text': 'hello world', 'seconds': 5, 'confidence': 0.9};
          }
          return null;
        });
    await tester.pumpWidget(const EnglishApp());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();
    expect(find.text('Mục tiêu hôm nay'), findsOneWidget);
    await tester.tap(find.text('Luyện nói'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Bắt đầu thu âm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu thu âm'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Phản hồi lượt luyện'));
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
    await tester.tap(find.text('Tiến độ'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Lịch sử luyện tập'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('hello world'));
    await tester.pumpAndSettle();
    expect(find.text('hello world'), findsOneWidget);
    await tester.tap(find.text('hello world'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết lượt luyện'), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
  });
}
