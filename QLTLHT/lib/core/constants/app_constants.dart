class AppConstants {
  static const String appName = 'Quản Lý Tài Liệu Học Tập';
  static const String appVersion = '1.0.0';
  static const String dbName = 'qltlht_database.db';
  static const int dbVersion = 1;

  // Key-values for SharedPreferences
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefAccentColor = 'pref_accent_color';
  static const String prefViewMode = 'pref_view_mode'; // 'list' or 'grid'
  static const String prefDefaultSort = 'pref_default_sort';

  // Sort Options
  static const String sortDateDesc = 'Mới nhất';
  static const String sortDateAsc = 'Cũ nhất';
  static const String sortTitleAsc = 'Tiêu đề A-Z';
  static const String sortTitleDesc = 'Tiêu đề Z-A';
  static const String sortSizeDesc = 'Dung lượng lớn nhất';

  // Common File Types
  static const String fileTypePdf = 'PDF';
  static const String fileTypeDoc = 'Word (DOCX)';
  static const String fileTypePpt = 'PowerPoint (PPTX)';
  static const String fileTypeXls = 'Excel (XLSX)';
  static const String fileTypeTxt = 'Văn bản (TXT/MD)';
  static const String fileTypeVideo = 'Video';
  static const String fileTypeLink = 'Đường dẫn Web';
  static const String fileTypeOther = 'Khác';

  static const List<String> supportedFileTypes = [
    fileTypePdf,
    fileTypeDoc,
    fileTypePpt,
    fileTypeXls,
    fileTypeTxt,
    fileTypeVideo,
    fileTypeLink,
    fileTypeOther,
  ];
}
