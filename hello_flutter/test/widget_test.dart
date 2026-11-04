import 'package:flutter_test/flutter_test.dart';
import 'package:hello_flutter/main.dart';

void main() {
  testWidgets('Portfolio Smoke Test - Home, Navigation, Data Check',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyPortfolioApp());

    // 1. Kiểm tra thông tin màn hình Trang chủ
    expect(find.text(PortfolioData.name), findsWidgets);
    expect(find.text(PortfolioData.title), findsOneWidget);
    expect(find.text(PortfolioData.bio), findsOneWidget);
    expect(find.text('Xem Dự Án'), findsOneWidget);
    expect(find.text('Liên Hệ Ngay'), findsOneWidget);
  });
}
