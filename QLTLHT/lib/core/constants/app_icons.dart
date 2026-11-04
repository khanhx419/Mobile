import 'package:flutter/material.dart';

class AppIcons {
  // Available Icons for Subjects
  static const List<IconData> availableSubjectIcons = [
    Icons.book_rounded,
    Icons.computer_rounded,
    Icons.code_rounded,
    Icons.calculate_rounded,
    Icons.science_rounded,
    Icons.biotech_rounded,
    Icons.history_edu_rounded,
    Icons.public_rounded,
    Icons.language_rounded,
    Icons.architecture_rounded,
    Icons.psychology_rounded,
    Icons.school_rounded,
    Icons.library_books_rounded,
    Icons.edit_note_rounded,
    Icons.analytics_rounded,
  ];

  static IconData getSubjectIcon(String? iconName) {
    if (iconName == null) return Icons.school_rounded;
    switch (iconName) {
      case 'computer':
        return Icons.computer_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'math':
        return Icons.calculate_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'history':
        return Icons.history_edu_rounded;
      case 'design':
        return Icons.architecture_rounded;
      case 'analytics':
        return Icons.analytics_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  static IconData getFileTypeIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file_rounded;
    final ft = fileType.toUpperCase();
    if (ft.contains('PDF')) return Icons.picture_as_pdf_rounded;
    if (ft.contains('DOC') || ft.contains('WORD')) return Icons.description_rounded;
    if (ft.contains('PPT') || ft.contains('POWERPOINT')) return Icons.slideshow_rounded;
    if (ft.contains('XLS') || ft.contains('EXCEL')) return Icons.table_chart_rounded;
    if (ft.contains('VIDEO')) return Icons.play_circle_fill_rounded;
    if (ft.contains('LINK') || ft.contains('WEB')) return Icons.link_rounded;
    if (ft.contains('TXT') || ft.contains('CODE')) return Icons.terminal_rounded;
    return Icons.insert_drive_file_rounded;
  }
}
