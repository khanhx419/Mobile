import 'dart:convert';

import 'package:daily_you/models/entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrowserEntry {
  const BrowserEntry(
      {required this.entry,
      this.title = '',
      this.tags = '',
      this.images = const []});
  final Entry entry;
  final String title;
  final String tags;
  final List<String> images;

  Map<String, Object?> toJson() =>
      {...entry.toJson(), 'title': title, 'tags': tags, 'images': images};

  factory BrowserEntry.fromJson(Map<String, dynamic> json) {
    final entry = Entry.fromJson(json);
    if (entry.id == null ||
        (entry.mood != null && (entry.mood! < -2 || entry.mood! > 2))) {
      throw const FormatException('Dữ liệu nhật ký không hợp lệ.');
    }
    final images = (json['images'] as List? ?? []).cast<String>();
    if (images.any((image) =>
        !RegExp(r'^data:image/(png|jpeg|webp|gif);base64,').hasMatch(image))) {
      throw const FormatException('Định dạng hình ảnh không hợp lệ.');
    }
    if (images.length > 3 ||
        images.any(
            (image) => base64Decode(image.split(',').last).length > 1500000)) {
      throw const FormatException('Hình ảnh vượt quá giới hạn dung lượng.');
    }
    return BrowserEntry(
        entry: entry,
        title: json['title'] as String? ?? '',
        tags: json['tags'] as String? ?? '',
        images: images);
  }
}

class BrowserJournalStore {
  BrowserJournalStore(this.preferences);
  final SharedPreferences preferences;
  static const storageKey = 'nhat_ky_viet_web_v1';
  List<BrowserEntry> entries = [];

  void load() {
    final raw = preferences.getString(storageKey);
    if (raw != null) entries = decode(raw);
  }

  static List<BrowserEntry> decode(String raw) {
    final document = jsonDecode(raw);
    if (document is! Map ||
        document['format'] != 'nhat-ky-viet-web' ||
        document['version'] != 1 ||
        document['entries'] is! List) {
      throw const FormatException(
          'Tệp không phải bản sao lưu web được hỗ trợ.');
    }
    final parsed = (document['entries'] as List)
        .map((e) => BrowserEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    if (parsed.map((e) => e.entry.id).toSet().length != parsed.length) {
      throw const FormatException('Bản sao lưu có mã nhật ký trùng nhau.');
    }
    return parsed;
  }

  String encode([List<BrowserEntry>? values]) => jsonEncode({
        'format': 'nhat-ky-viet-web',
        'version': 1,
        'entries': (values ?? entries).map((e) => e.toJson()).toList(),
      });

  Future<void> save(List<BrowserEntry> next) async {
    final saved = await preferences.setString(storageKey, encode(next));
    if (!saved) throw StateError('Không thể lưu dữ liệu trong trình duyệt.');
    entries = List.of(next);
  }
}
