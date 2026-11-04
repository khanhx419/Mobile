import 'dart:math';

class Lesson {
  final String title, text, meaning, focus;
  const Lesson(this.title, this.text, this.meaning, this.focus);
  String get ipa => tokens(text).map((w) => lexicon[w]!.join(' ')).join(' | ');
}

const lessons = [
  Lesson(
    '01 · Làm quen',
    'hello world',
    'Xin chào thế giới',
    'Âm /h/ và phụ âm cuối /d/',
  ),
  Lesson(
    '02 · Lời cảm ơn',
    'thank you',
    'Cảm ơn bạn',
    'Đầu lưỡi chạm nhẹ giữa hai hàm răng: /θ/',
  ),
  Lesson(
    '03 · Mỗi ngày',
    'i practice english every day',
    'Tôi luyện tiếng Anh mỗi ngày',
    'Giữ rõ phụ âm cuối và nhịp câu',
  ),
  Lesson(
    '04 · Âm dễ nhầm',
    'three green trees',
    'Ba cây xanh',
    'Phân biệt /θ/ và /t/, /ɹ/ và /l/',
  ),
  Lesson(
    '05 · Nguyên âm',
    'the ship is big',
    'Con tàu lớn',
    'Phân biệt /ɪ/ ngắn và /iː/ dài',
  ),
  Lesson(
    '06 · Tự tin',
    'i think you can speak english',
    'Tôi nghĩ bạn có thể nói tiếng Anh',
    'Luyện /θ/, /ŋ/ và cụm /sp/',
  ),
  Lesson(
    '07 · Giao tiếp',
    'please speak slowly',
    'Làm ơn nói chậm',
    'Giữ /s/ trong cụm phụ âm /sp/ và /sl/',
  ),
  Lesson(
    '08 · Mục tiêu',
    'we learn together',
    'Chúng ta cùng học',
    'Luyện /ð/ hữu thanh trong together',
  ),
];

// Curated broad American-English IPA. Never infer phonemes for unknown words.
const Map<String, List<String>> lexicon = {
  'hello': ['h', 'ə', 'l', 'oʊ'],
  'world': ['w', 'ɝ', 'l', 'd'],
  'thank': ['θ', 'æ', 'ŋ', 'k'],
  'you': ['j', 'uː'],
  'i': ['aɪ'],
  'practice': ['p', 'ɹ', 'æ', 'k', 't', 'ɪ', 's'],
  'english': ['ɪ', 'ŋ', 'ɡ', 'l', 'ɪ', 'ʃ'],
  'every': ['ɛ', 'v', 'ɹ', 'i'],
  'day': ['d', 'eɪ'],
  'three': ['θ', 'ɹ', 'iː'],
  'green': ['ɡ', 'ɹ', 'iː', 'n'],
  'trees': ['t', 'ɹ', 'iː', 'z'],
  'the': ['ð', 'ə'],
  'ship': ['ʃ', 'ɪ', 'p'],
  'is': ['ɪ', 'z'],
  'big': ['b', 'ɪ', 'ɡ'],
  'think': ['θ', 'ɪ', 'ŋ', 'k'],
  'can': ['k', 'æ', 'n'],
  'speak': ['s', 'p', 'iː', 'k'],
  'please': ['p', 'l', 'iː', 'z'],
  'slowly': ['s', 'l', 'oʊ', 'l', 'i'],
  'we': ['w', 'iː'],
  'learn': ['l', 'ɝ', 'n'],
  'together': ['t', 'ə', 'ɡ', 'ɛ', 'ð', 'ɚ'],
  'tree': ['t', 'ɹ', 'iː'],
  'free': ['f', 'ɹ', 'iː'],
  'tank': ['t', 'æ', 'ŋ', 'k'],
  'sink': ['s', 'ɪ', 'ŋ', 'k'],
  'sheep': ['ʃ', 'iː', 'p'],
  'she': ['ʃ', 'iː'],
  'it': ['ɪ', 't'],
  'a': ['ə'],
  'word': ['w', 'ɝ', 'd'],
  'work': ['w', 'ɝ', 'k'],
  'very': ['v', 'ɛ', 'ɹ', 'i'],
  'then': ['ð', 'ɛ', 'n'],
  'tin': ['t', 'ɪ', 'n'],
  'dis': ['d', 'ɪ', 's'],
};

List<String> tokens(String s) =>
    RegExp(r"[a-z]+(?:'[a-z]+)?")
        .allMatches(s.toLowerCase())
        .map((m) => m.group(0)!)
        .toList();

class PhonePair {
  final String? expected, heard;
  const PhonePair(this.expected, this.heard);
  bool get correct => expected == heard;
  Map<String, dynamic> toJson() => {'expected': expected, 'heard': heard};
}

List<PhonePair> align(List<String> expected, List<String> heard) {
  final d = List.generate(
    expected.length + 1,
    (i) =>
        List.generate(heard.length + 1, (j) => i == 0 ? j : (j == 0 ? i : 0)),
  );
  for (var i = 1; i <= expected.length; i++) {
    for (var j = 1; j <= heard.length; j++) {
      d[i][j] = min(
        d[i - 1][j] + 1,
        min(
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + (expected[i - 1] == heard[j - 1] ? 0 : 1),
        ),
      );
    }
  }
  var i = expected.length, j = heard.length;
  final result = <PhonePair>[];
  while (i > 0 || j > 0) {
    if (i > 0 &&
        j > 0 &&
        d[i][j] ==
            d[i - 1][j - 1] + (expected[i - 1] == heard[j - 1] ? 0 : 1)) {
      result.add(PhonePair(expected[--i], heard[--j]));
    } else if (i > 0 && d[i][j] == d[i - 1][j] + 1) {
      result.add(PhonePair(expected[--i], null));
    } else {
      result.add(PhonePair(null, heard[--j]));
    }
  }
  return result.reversed.toList();
}

class Assessment {
  final int? score;
  final List<PhonePair> pairs;
  final List<String> unknown;
  final List<String> tips;
  Assessment(this.score, this.pairs, this.unknown, this.tips);
}

Assessment assess(String reference, String transcript) {
  final expected = tokens(reference), heard = tokens(transcript);
  if (expected.isEmpty || heard.isEmpty) {
    return Assessment(null, [], [], [
      'Chưa nhận được lời nói. Hãy thử lại ở nơi yên tĩnh.',
    ]);
  }
  final unknown = {
    ...expected,
    ...heard,
  }.where((w) => !lexicon.containsKey(w)).toList();
  if (unknown.isNotEmpty) {
    return Assessment(null, [], unknown, [
      'Từ ngoài từ điển: ${unknown.join(', ')}. Chưa đủ dữ liệu âm vị để chấm; hãy đọc lại câu mẫu.',
    ]);
  }
  final a = expected.expand((w) => lexicon[w]!).toList();
  final b = heard.expand((w) => lexicon[w]!).toList();
  final pairs = align(a, b);
  final errors = pairs.where((p) => !p.correct).length;
  final score = (100 * (1 - errors / max(a.length, b.length))).round().clamp(
    0,
    100,
  );
  final missed = pairs.where((p) => !p.correct).map((p) => p.expected).toSet();
  final tips = <String>[];
  if (missed.contains('θ') || missed.contains('ð')) {
    tips.add(
      'Đặt đầu lưỡi nhẹ giữa hai hàm răng; thổi /θ/ trong three, rung dây thanh /ð/ trong the. Lặp thank–tank 5 lần.',
    );
  }
  if (missed.contains('ɪ') || missed.contains('iː')) {
    tips.add(
      'Đọc ship–sheep 5 lần: /ɪ/ ngắn, thả lỏng; /iː/ dài hơn, kéo nhẹ khóe miệng.',
    );
  }
  if (missed.contains('ɹ') || missed.contains('l')) {
    tips.add(
      'Luyện green–learn: /ɹ/ không chạm vòm miệng; /l/ chạm đầu lưỡi vào lợi trên.',
    );
  }
  if (errors == 0) {
    tips.add(
      'Nội dung nhận dạng khớp câu mẫu. Nghe lại giọng chuẩn và luyện nhịp, trọng âm; kết quả này chưa xác nhận âm thanh chính xác.',
    );
  } else {
    tips.add(
      'Nghe mẫu chậm, đọc từng từ rồi nối câu 3 lần. Các âm đánh dấu là sai khác SUY RA từ văn bản nhận dạng, cần nghe lại để xác nhận.',
    );
  }
  return Assessment(score, pairs, [], tips);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
int streak(Iterable<String> dates, DateTime now) {
  final days = dates.toSet();
  var cursor = dateOnly(now);
  if (!days.contains(dayKey(cursor))) {
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  var count = 0;
  while (days.contains(dayKey(cursor))) {
    count++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return count;
}
