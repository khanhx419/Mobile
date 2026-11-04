import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qltlht/core/constants/app_colors.dart';
import 'package:qltlht/models/document.dart';
import 'package:qltlht/widgets/document_card.dart';
import 'package:qltlht/widgets/empty_state_widget.dart';
import 'package:qltlht/widgets/stat_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('1. Kiểm thử hiển thị StatSummaryCard', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatSummaryCard(
            title: 'Tổng số tài liệu',
            value: '42',
            icon: Icons.description_rounded,
            color: AppColors.primaryBlue,
            subtitle: '10 đã hoàn thành',
          ),
        ),
      ),
    );

    expect(find.text('Tổng số tài liệu'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('10 đã hoàn thành'), findsOneWidget);
    expect(find.byIcon(Icons.description_rounded), findsOneWidget);
  });

  testWidgets('2. Kiểm thử hiển thị DocumentCard với đầy đủ thông tin', (WidgetTester tester) async {
    final doc = Document(
      documentId: 'doc_card_test',
      title: 'Tài liệu Thử nghiệm UI',
      description: 'Mô tả tóm tắt nội dung tài liệu',
      subjectFk: 'sub_mob',
      categoryFk: 'cat_lecture',
      fileType: 'PDF',
      fileName: 'test.pdf',
      fileSizeBytes: 1048576,
      subjectName: 'Lập trình Di động',
      subjectCode: 'INT3105',
      subjectColor: AppColors.primaryBlue.value,
      categoryName: 'Bài giảng',
      categoryColor: AppColors.lectureColor.value,
      isFavorite: true,
      isCompleted: false,
      dateCreated: DateTime.now(),
      dateTimeModified: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocumentCard(
            document: doc,
            onTap: () {},
            onToggleFavorite: () {},
            onToggleCompleted: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('Tài liệu Thử nghiệm UI'), findsOneWidget);
    expect(find.text('Mô tả tóm tắt nội dung tài liệu'), findsOneWidget);
    expect(find.text('INT3105 - Lập trình Di động'), findsOneWidget);
    expect(find.text('Bài giảng'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('1.0 MB'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('3. Kiểm thử EmptyStateWidget', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            title: 'Chưa có tài liệu',
            message: 'Hãy nhấn vào nút thêm mới',
            actionText: 'Thêm tài liệu',
            onAction: () {},
          ),
        ),
      ),
    );

    expect(find.text('Chưa có tài liệu'), findsOneWidget);
    expect(find.text('Hãy nhấn vào nút thêm mới'), findsOneWidget);
    expect(find.text('Thêm tài liệu'), findsOneWidget);
  });
}
