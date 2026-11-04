import 'package:sqflite/sqflite.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class InitialData {
  static Future<void> seed(Database db) async {
    final now = DateTime.now().toIso8601String();

    // 1. Initial Categories
    final categories = [
      {
        'categoryId': 'cat_lecture',
        'name': 'Bài giảng',
        'description': 'Slide bài giảng, tài liệu lý thuyết chính khóa',
        'color': AppColors.lectureColor.value,
        'icon': 'slideshow',
        'sortOrder': 1,
        'dateTimeModified': now,
      },
      {
        'categoryId': 'cat_assignment',
        'name': 'Bài tập & Đồ án',
        'description': 'Đề bài tập lớn, bài thực hành và đồ án môn học',
        'color': AppColors.assignmentColor.value,
        'icon': 'assignment',
        'sortOrder': 2,
        'dateTimeModified': now,
      },
      {
        'categoryId': 'cat_reference',
        'name': 'Tài liệu tham khảo',
        'description': 'Sách giáo trình, bài báo khoa học, ebook chuyên ngành',
        'color': AppColors.referenceColor.value,
        'icon': 'menu_book',
        'sortOrder': 3,
        'dateTimeModified': now,
      },
      {
        'categoryId': 'cat_exam',
        'name': 'Đề cương & Đề thi',
        'description': 'Đề thi giữa kỳ, cuối kỳ các năm và đề cương ôn tập',
        'color': AppColors.examColor.value,
        'icon': 'quiz',
        'sortOrder': 4,
        'dateTimeModified': now,
      },
      {
        'categoryId': 'cat_notes',
        'name': 'Ghi chú & Code mẫu',
        'description': 'Ghi chép nhanh, cheat-sheets, mã nguồn mẫu',
        'color': AppColors.notesColor.value,
        'icon': 'note_alt',
        'sortOrder': 5,
        'dateTimeModified': now,
      },
    ];

    for (final cat in categories) {
      await db.insert('categories', cat, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // 2. Initial Subjects
    final subjects = [
      {
        'subjectId': 'sub_mob',
        'code': 'INT3105',
        'name': 'Lập trình Thiết bị Di động',
        'lecturer': 'TS. Trần Quang Huy',
        'color': AppColors.presetColors[0].value, // Blue
        'icon': 'computer',
        'sortOrder': 1,
        'dateCreated': now,
        'dateTimeModified': now,
      },
      {
        'subjectId': 'sub_db',
        'code': 'INT2204',
        'name': 'Hệ Quản trị Cơ sở Dữ liệu',
        'lecturer': 'PGS.TS. Lê Đình Khang',
        'color': AppColors.presetColors[1].value, // Indigo
        'icon': 'analytics',
        'sortOrder': 2,
        'dateCreated': now,
        'dateTimeModified': now,
      },
      {
        'subjectId': 'sub_dsa',
        'code': 'INT2202',
        'name': 'Cấu trúc Dữ liệu & Giải thuật',
        'lecturer': 'ThS. Nguyễn Hoàng Nam',
        'color': AppColors.presetColors[2].value, // Purple
        'icon': 'code',
        'sortOrder': 3,
        'dateCreated': now,
        'dateTimeModified': now,
      },
      {
        'subjectId': 'sub_ai',
        'code': 'INT3401',
        'name': 'Trí tuệ Nhân tạo',
        'lecturer': 'TS. Phạm Minh Tuấn',
        'color': AppColors.presetColors[7].value, // Teal
        'icon': 'science',
        'sortOrder': 4,
        'dateCreated': now,
        'dateTimeModified': now,
      },
      {
        'subjectId': 'sub_net',
        'code': 'INT2208',
        'name': 'Mạng Máy tính',
        'lecturer': 'ThS. Vũ Đức Trung',
        'color': AppColors.presetColors[5].value, // Amber
        'icon': 'language',
        'sortOrder': 5,
        'dateCreated': now,
        'dateTimeModified': now,
      },
    ];

    for (final sub in subjects) {
      await db.insert('subjects', sub, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // 3. Initial Sample Documents
    final documents = [
      {
        'documentId': 'doc_01',
        'title': 'Slide Chương 1 - Kiến trúc ứng dụng Flutter & Local-First',
        'description': 'Tổng quan kiến trúc phân tầng, Local-First Storage và Reactive State Management.',
        'subjectFk': 'sub_mob',
        'categoryFk': 'cat_lecture',
        'fileType': AppConstants.fileTypePpt,
        'fileName': 'Chuong1_KienTruc_Flutter.pptx',
        'fileUri': 'https://drive.google.com/file/d/sample_lecture_1',
        'fileSizeBytes': 5242880, // 5 MB
        'tags': 'Flutter, Kiến trúc, Slide, Mobile',
        'isFavorite': 1,
        'isCompleted': 1,
        'dateCreated': now,
        'dateTimeModified': now,
      },
      {
        'documentId': 'doc_02',
        'title': 'Đề bài tập lớn: Thiết kế ứng dụng theo Kiến trúc Cashew',
        'description': 'Yêu cầu phân tách các lớp xử lý, module hóa SQLite DAOs và viết báo cáo giải trình.',
        'subjectFk': 'sub_mob',
        'categoryFk': 'cat_assignment',
        'fileType': AppConstants.fileTypePdf,
        'fileName': 'DeBaiTapLon_Cashew_2026.pdf',
        'fileUri': 'file:///assets/docs/DeBaiTapLon_Cashew_2026.pdf',
        'fileSizeBytes': 1048576, // 1 MB
        'tags': 'Bài tập lớn, Cashew, SQLite, DAOs',
        'isFavorite': 1,
        'isCompleted': 0,
        'dateCreated': now,
        'dateTimeModified': now,
      },
      {
        'documentId': 'doc_03',
        'title': 'Sách giáo trình: Database System Concepts (Silberschatz)',
        'description': 'Tài liệu tham khảo tiêu chuẩn cho môn CSDL, chương 14-16 về Giao dịch ACID và Indexing B+ Tree.',
        'subjectFk': 'sub_db',
        'categoryFk': 'cat_reference',
        'fileType': AppConstants.fileTypePdf,
        'fileName': 'Database_System_Concepts_7th.pdf',
        'fileUri': 'file:///assets/docs/Database_Concepts.pdf',
        'fileSizeBytes': 25165824, // 24 MB
        'tags': 'Database, SQL, ACID, Ebook',
        'isFavorite': 0,
        'isCompleted': 1,
        'dateCreated': now,
        'dateTimeModified': now,
      },
      {
        'documentId': 'doc_04',
        'title': 'Đề cương ôn thi và Tổng hợp đề thi cuối kỳ CSDL 2024-2025',
        'description': 'Bộ 10 đề thi cuối kỳ có đáp án chi tiết về chuẩn hóa 3NF/BCNF và tối ưu hóa truy vấn SQL.',
        'subjectFk': 'sub_db',
        'categoryFk': 'cat_exam',
        'fileType': AppConstants.fileTypeDoc,
        'fileName': 'DeCuong_DeThi_CSDL.docx',
        'fileUri': 'file:///assets/docs/DeCuong_CSDL.docx',
        'fileSizeBytes': 3145728, // 3 MB
        'tags': 'Đề thi, Ôn tập, Chuẩn hóa, SQL',
        'isFavorite': 1,
        'isCompleted': 0,
        'dateCreated': now,
        'dateTimeModified': now,
      },
      {
        'documentId': 'doc_05',
        'title': 'Mã nguồn thuật toán Dijkstra và A* tìm đường đi ngắn nhất',
        'description': 'Cài đặt bằng C++ và Python kèm đồ thị minh họa cấu trúc dữ liệu Priority Queue.',
        'subjectFk': 'sub_dsa',
        'categoryFk': 'cat_notes',
        'fileType': AppConstants.fileTypeTxt,
        'fileName': 'dijkstra_astar_implementation.cpp',
        'fileUri': 'https://github.com/algorithms/dijkstra',
        'fileSizeBytes': 20480, // 20 KB
        'tags': 'DSA, Graph, Dijkstra, A*, Code mẫu',
        'isFavorite': 0,
        'isCompleted': 1,
        'dateCreated': now,
        'dateTimeModified': now,
      },
      {
        'documentId': 'doc_06',
        'title': 'Slide Bài giảng Mạng Máy tính: Tầng Giao vận TCP & UDP',
        'description': 'Cơ chế bắt tay 3 bước, kiểm soát luồng Flow Control và điều khiển tắc nghẽn Congestion Control.',
        'subjectFk': 'sub_net',
        'categoryFk': 'cat_lecture',
        'fileType': AppConstants.fileTypePpt,
        'fileName': 'Chuong3_Transport_Layer_TCP_UDP.pptx',
        'fileUri': 'file:///assets/docs/Transport_Layer.pptx',
        'fileSizeBytes': 8388608, // 8 MB
        'tags': 'TCP, UDP, Socket, Slide',
        'isFavorite': 0,
        'isCompleted': 0,
        'dateCreated': now,
        'dateTimeModified': now,
      },
    ];

    for (final doc in documents) {
      await db.insert('documents', doc, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
