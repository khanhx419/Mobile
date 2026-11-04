class FileHelper {
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static String getExtension(String fileName) {
    if (!fileName.contains('.')) return '';
    return fileName.split('.').last.toLowerCase();
  }

  static String detectFileType(String fileName) {
    final ext = getExtension(fileName);
    switch (ext) {
      case 'pdf':
        return 'PDF';
      case 'doc':
      case 'docx':
        return 'Word (DOCX)';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint (PPTX)';
      case 'xls':
      case 'xlsx':
      case 'csv':
        return 'Excel (XLSX)';
      case 'txt':
      case 'md':
      case 'dart':
      case 'py':
      case 'java':
      case 'cpp':
      case 'js':
      case 'html':
      case 'css':
        return 'Văn bản (TXT/MD)';
      case 'mp4':
      case 'mkv':
      case 'mov':
        return 'Video';
      default:
        return 'Khác';
    }
  }
}
