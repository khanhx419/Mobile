import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'learning.dart';
import 'platform.dart';
import 'storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EnglishApp());
}

class EnglishApp extends StatelessWidget {
  const EnglishApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'English Flow',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF356859)),
      scaffoldBackgroundColor: const Color(0xFFF5F7F2),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F7F2),
        centerTitle: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    home: const LearningHome(),
  );
}

class LearningHome extends StatefulWidget {
  const LearningHome({super.key});
  @override
  State<LearningHome> createState() => _LearningHomeState();
}

class _LearningHomeState extends State<LearningHome>
    with WidgetsBindingObserver {
  Store? store;
  List<Map<String, Object?>> users = [], history = [];
  Map<String, Object?>? user;
  String? loadError;
  int tab = 0, lessonIndex = 0;
  bool listening = false, saving = false, settingsBusy = false;
  Assessment? assessment;
  String transcript = '';
  double? confidence;
  DateTime today = DateTime.now();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  Future<void> initialize() async {
    try {
      store ??= await Store.open();
      await reload();
      // AlarmManager already retains its schedule. Do not prompt for permission on launch.
    } catch (e) {
      if (mounted) {
        setState(() => loadError = 'Không mở được cơ sở dữ liệu: $e');
      }
    }
  }

  Future<void> reload() async {
    final all = await store!.users();
    final id = await store!.activeId();
    final records = await store!.history(id);
    if (!mounted) return;
    setState(() {
      users = all;
      user = all.firstWhere((u) => u['id'] == id);
      history = records;
      today = DateTime.now();
      loadError = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && store != null) reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void message(String s) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
    }
  }

  String errorMessage(Object e) =>
      e is PlatformException ? e.message ?? e.code : '$e';
  Future<void> platformAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      message(errorMessage(e));
    }
  }

  bool get busy => listening || saving || settingsBusy;
  int get goalSeconds => (user!['goal_minutes'] as int) * 60;
  int secondsOn(String day) => history
      .where((r) => r['local_day'] == day)
      .fold(0, (n, r) => n + (r['seconds'] as int));
  String duration(int seconds) => '${seconds ~/ 60}p ${seconds % 60}s';
  Future<void> record() async {
    if (busy) return;
    final id = user!['id'] as int;
    final index = lessonIndex;
    setState(() {
      listening = true;
      assessment = null;
      transcript = '';
      confidence = null;
    });
    try {
      final response = await SpeechPlatform.listen();
      if (!mounted || response == null) return;
      final text = response['text'] as String;
      final result = assess(lessons[index].text, text);
      final conf = (response['confidence'] as num?)?.toDouble();
      setState(() {
        listening = false;
        saving = true;
        transcript = text;
        assessment = result;
        confidence = conf;
      });
      try {
        await store!.save(
          userId: id,
          lessonIndex: index,
          transcript: text,
          seconds: response['seconds'] as int,
          result: result,
          confidence: conf,
        );
        await reload();
        message('Đã lưu lượt luyện vào hồ sơ của bạn.');
      } catch (e) {
        message('Chưa lưu được lượt luyện: $e. Kết quả vẫn hiển thị ở đây.');
      }
    } catch (e) {
      message(errorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          listening = false;
          saving = false;
        });
      }
    }
  }

  Future<void> addProfile() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm người học'),
        content: TextField(
          controller: controller,
          maxLength: 40,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tên người học',
            hintText: 'Ví dụ: Minh Anh',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Tạo hồ sơ'),
          ),
        ],
      ),
    );
    // Controller lives until the dialog has finished its closing animation.
    Future.delayed(const Duration(seconds: 1), controller.dispose);
    if (name == null) return;
    try {
      // One daily notification schedule per device, following the selected profile.
      await SpeechPlatform.reminder(false, 20, 0);
      await store!.addUser(name);
      await reload();
      if (mounted) {
        setState(() {
          assessment = null;
          transcript = '';
        });
      }
    } catch (e) {
      message(errorMessage(e));
    }
  }

  Future<void> switchUser(int id) async {
    if (busy || id == user!['id']) return;
    setState(() => settingsBusy = true);
    try {
      final selected = users.firstWhere((u) => u['id'] == id);
      await SpeechPlatform.reminder(false, 20, 0);
      await store!.activate(id);
      await reload();
      if (mounted) {
        setState(() {
          assessment = null;
          transcript = '';
        });
      }
      if (selected['reminder_enabled'] == 1) {
        try {
          await SpeechPlatform.reminder(
            true,
            selected['reminder_hour'] as int,
            selected['reminder_minute'] as int,
          );
        } catch (e) {
          await store!.updateUser(id, {'reminder_enabled': 0});
          await reload();
          message(errorMessage(e));
        }
      }
    } catch (e) {
      message(errorMessage(e));
    } finally {
      if (mounted) setState(() => settingsBusy = false);
    }
  }

  Future<void> setReminder(bool enabled, {TimeOfDay? time}) async {
    setState(() => settingsBusy = true);
    final hour = time?.hour ?? user!['reminder_hour'] as int;
    final minute = time?.minute ?? user!['reminder_minute'] as int;
    try {
      await SpeechPlatform.reminder(enabled, hour, minute);
      await store!.updateUser(user!['id'] as int, {
        'reminder_enabled': enabled ? 1 : 0,
        'reminder_hour': hour,
        'reminder_minute': minute,
      });
      await reload();
    } catch (e) {
      message(errorMessage(e));
    } finally {
      if (mounted) setState(() => settingsBusy = false);
    }
  }

  Widget card(Widget child) => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
  Widget title(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 10),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget stat(String value, String label, IconData icon) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (user == null || loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: loadError == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(loadError!),
                      FilledButton(
                        onPressed: initialize,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ENGLISH FLOW',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Một chút mỗi ngày.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              child: Text(
                (user!['name'] as String).characters.first.toUpperCase(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: switch (tab) {
                0 => dashboard(),
                1 => practice(),
                2 => progress(),
                _ => settings(),
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Hôm nay',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none),
            selectedIcon: Icon(Icons.mic),
            label: 'Luyện nói',
          ),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Tiến độ'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Cá nhân'),
        ],
      ),
    );
  }

  List<Widget> dashboard() {
    final seconds = secondsOn(dayKey(today));
    return [
      title('Chào ${user!['name']} 👋'),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF244F46),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TIẾNG ANH LÀ MỘT THÓI QUEN',
              style: TextStyle(
                color: Color(0xFFBFDFB9),
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tự tin hơn,\ntừng câu nói.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mục tiêu hôm nay: ${user!['goal_minutes']} phút luyện tập',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => setState(() => tab = 1),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Bắt đầu luyện nói'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      card(
        Row(
          children: [
            stat(
              '${streak(history.map((r) => r['local_day'] as String), today)}',
              'ngày liên tiếp',
              Icons.local_fire_department_outlined,
            ),
            stat('${history.length}', 'lượt luyện', Icons.mic_none),
            stat(duration(seconds), 'hôm nay', Icons.timer_outlined),
          ],
        ),
      ),
      title('Mục tiêu hôm nay'),
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seconds >= goalSeconds
                  ? 'Hoàn thành! Hãy giữ nhịp vào ngày mai.'
                  : 'Mỗi lượt luyện đều là một bước tiến.',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (seconds / goalSeconds).clamp(0, 1),
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text('${duration(seconds)} / ${user!['goal_minutes']} phút'),
            const SizedBox(height: 8),
            const Text(
              'Thời gian tính theo phiên micro có kết quả; không cộng thời gian chỉ mở ứng dụng.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
      title('Lộ trình 8 bài luyện'),
      ...lessons.indexed.map(
        (entry) => Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                history.any((r) => r['lesson_index'] == entry.$1)
                    ? Icons.check
                    : Icons.play_arrow,
              ),
            ),
            title: Text(entry.$2.title),
            subtitle: Text(entry.$2.text),
            trailing: const Icon(Icons.chevron_right),
            onTap: busy
                ? null
                : () => setState(() {
                    lessonIndex = entry.$1;
                    assessment = null;
                    transcript = '';
                    tab = 1;
                  }),
          ),
        ),
      ),
    ];
  }

  List<Widget> practice() {
    final lesson = lessons[lessonIndex];
    return [
      title('Phòng luyện phát âm'),
      DropdownButtonFormField<int>(
        initialValue: lessonIndex,
        key: ValueKey(lessonIndex),
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Bài học'),
        items: lessons.indexed
            .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2.title)))
            .toList(),
        onChanged: busy
            ? null
            : (v) => setState(() {
                lessonIndex = v!;
                assessment = null;
                transcript = '';
              }),
      ),
      const SizedBox(height: 12),
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.text,
              style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              '/${lesson.ipa}/',
              style: TextStyle(
                fontSize: 19,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(lesson.meaning),
            const Divider(height: 28),
            Text(lesson.focus),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () =>
                        platformAction(() => SpeechPlatform.speak(lesson.text)),
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('Nghe giọng mẫu · en-US'),
            ),
          ],
        ),
      ),
      card(
        Column(
          children: [
            Icon(
              listening ? Icons.graphic_eq : Icons.mic_none,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              listening
                  ? 'Đang nghe… Đọc câu mẫu bằng tiếng Anh.'
                  : 'Nghe mẫu, rồi đến lượt bạn.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: listening
                  ? () => platformAction(SpeechPlatform.stop)
                  : (busy ? null : record),
              icon: Icon(listening ? Icons.stop : Icons.mic),
              label: Text(
                listening
                    ? 'Kết thúc câu'
                    : saving
                    ? 'Đang lưu…'
                    : 'Bắt đầu thu âm',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cần quyền micro và dịch vụ nhận dạng tiếng Anh trên Android. Dịch vụ có thể gửi âm thanh đến nhà cung cấp và cần Internet. Ứng dụng không lưu tệp âm thanh.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      if (assessment != null)
        ...resultWidgets(assessment!, transcript, confidence),
      const SizedBox(height: 12),
      const Text(
        'Cách chấm: nhận dạng giọng nói → tra IPA → căn chỉnh âm vị bằng khoảng cách chỉnh sửa. Đây là điểm đối chiếu văn bản, chưa đo trực tiếp chất lượng âm thanh, trọng âm hay ngữ điệu. Nhận dạng đúng câu vẫn có thể bỏ sót lỗi phát âm.',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
    ];
  }

  List<Widget> resultWidgets(Assessment result, String text, double? conf) => [
    title('Phản hồi lượt luyện'),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                result.score == null ? '—' : '${result.score}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Điểm đối chiếu IPA /100\nSuy ra từ văn bản nhận dạng',
                ),
              ),
            ],
          ),
          const Divider(),
          Text('Máy nghe được: “$text”'),
          const SizedBox(height: 8),
          Text(
            conf == null
                ? 'Dịch vụ không cung cấp độ tin cậy.'
                : 'Độ tin cậy nhận dạng: ${(conf * 100).round()}% · không phải điểm phát âm',
            style: const TextStyle(fontSize: 12),
          ),
          if (conf != null && conf < .6)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Độ tin cậy thấp: nên thu lại trước khi kết luận.'),
            ),
          if (result.pairs.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Âm chuẩn → âm suy ra · đỏ: khác / thiếu / thừa'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.pairs
                  .map(
                    (p) => Chip(
                      backgroundColor: p.correct
                          ? const Color(0xFFE8F2E7)
                          : const Color(0xFFFFE4DD),
                      label: Text(
                        p.correct
                            ? p.expected!
                            : '${p.expected ?? '∅'} → ${p.heard ?? '∅'}',
                      ),
                      avatar: Icon(
                        p.correct ? Icons.check : Icons.priority_high,
                        size: 15,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          ...result.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('• $tip'),
            ),
          ),
        ],
      ),
    ),
  ];
  List<Widget> progress() {
    final total = history.fold(0, (n, r) => n + (r['seconds'] as int));
    final scores = history.map((r) => r['score']).whereType<int>().toList();
    return [
      title('Tiến độ của ${user!['name']}'),
      card(
        Row(
          children: [
            stat(duration(total), 'tổng thời gian', Icons.schedule),
            stat(
              scores.isEmpty
                  ? '—'
                  : '${(scores.reduce((a, b) => a + b) / scores.length).round()}',
              'điểm IPA TB',
              Icons.insights,
            ),
            stat(
              '${history.map((r) => r['local_day']).toSet().length}',
              'ngày đã học',
              Icons.calendar_today_outlined,
            ),
          ],
        ),
      ),
      title('7 ngày gần nhất'),
      card(
        Column(
          children: List.generate(7, (i) {
            final day = DateTime(today.year, today.month, today.day - 6 + i);
            final seconds = secondsOn(dayKey(day));
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(width: 55, child: Text('${day.day}/${day.month}')),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (seconds / goalSeconds).clamp(0, 1),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: Text(duration(seconds), textAlign: TextAlign.right),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Thanh tiến độ so với mục tiêu hiện tại. Streak tính ngày có ít nhất một lượt thu âm nhận dạng thành công; mục tiêu phút là chỉ số riêng.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
      title('Lịch sử luyện tập'),
      if (history.isEmpty)
        card(const Text('Chưa có lượt luyện nào. Mở Luyện nói để bắt đầu.')),
      ...history.map(
        (r) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(r['score']?.toString() ?? '—')),
            title: Text(r['reference'] as String),
            subtitle: Text(
              '${r['local_day']} · ${duration(r['seconds'] as int)}\n${r['transcript']}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showHistory(r),
          ),
        ),
      ),
    ];
  }

  void showHistory(Map<String, Object?> r) {
    final data =
        jsonDecode(r['analysis_json'] as String) as Map<String, dynamic>;
    final result = Assessment(
      r['score'] as int?,
      (data['pairs'] as List)
          .map(
            (p) => PhonePair(p['expected'] as String?, p['heard'] as String?),
          )
          .toList(),
      List<String>.from(data['unknown']),
      List<String>.from(data['tips']),
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: .85,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chi tiết lượt luyện',
                    style: TextStyle(fontSize: 22),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text('${r['practiced_at']}\n${r['reference']}'),
            ...resultWidgets(
              result,
              r['transcript'] as String,
              (r['confidence'] as num?)?.toDouble(),
            ),
            Text(
              'Phương pháp: ${r['engine']}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> settings() => [
    title('Hồ sơ & thói quen'),
    card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            initialValue: user!['id'] as int,
            key: ValueKey(user!['id']),
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Người học trên thiết bị',
            ),
            items: users
                .map(
                  (u) => DropdownMenuItem(
                    value: u['id'] as int,
                    child: Text(u['name'] as String),
                  ),
                )
                .toList(),
            onChanged: busy ? null : (v) => switchUser(v!),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : addProfile,
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Thêm người học'),
          ),
          const Text(
            'Mỗi hồ sơ có mục tiêu, lịch sử và streak riêng. Đây là hồ sơ cục bộ, không có đăng nhập hoặc đồng bộ đám mây.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
    title('Mục tiêu hàng ngày'),
    card(
      DropdownButtonFormField<int>(
        initialValue: user!['goal_minutes'] as int,
        key: ValueKey('goal-${user!['id']}-${user!['goal_minutes']}'),
        decoration: const InputDecoration(labelText: 'Số phút luyện nói'),
        items: [1, 3, 5, 10, 15, 20, 30]
            .map(
              (v) => DropdownMenuItem(value: v, child: Text('$v phút / ngày')),
            )
            .toList(),
        onChanged: busy
            ? null
            : (v) async {
                try {
                  await store!.updateUser(user!['id'] as int, {
                    'goal_minutes': v,
                  });
                  await reload();
                } catch (e) {
                  message('Chưa lưu được mục tiêu: $e');
                }
              },
      ),
    ),
    title('Nhắc luyện tập'),
    card(
      Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nhắc tôi mỗi ngày'),
            subtitle: const Text('Theo hồ sơ đang được chọn'),
            value: user!['reminder_enabled'] == 1,
            onChanged: busy ? null : (v) => setReminder(v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alarm),
            title: const Text('Giờ nhắc học'),
            trailing: Text(
              '${(user!['reminder_hour'] as int).toString().padLeft(2, '0')}:${(user!['reminder_minute'] as int).toString().padLeft(2, '0')}',
            ),
            onTap: busy
                ? null
                : () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: user!['reminder_hour'] as int,
                        minute: user!['reminder_minute'] as int,
                      ),
                    );
                    if (time != null && mounted) {
                      await setReminder(
                        user!['reminder_enabled'] == 1,
                        time: time,
                      );
                    }
                  },
          ),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () => platformAction(SpeechPlatform.testReminder),
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Thử thông báo ngay'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Android có thể giao thông báo muộn khi tiết kiệm pin. Lịch tự khôi phục sau khởi động lại hoặc đổi múi giờ. Chỉ một lịch nhắc hoạt động trên thiết bị.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
    title('Về bài thực hành 3'),
    card(
      const Text(
        'English Flow kết hợp kỷ luật học tập và đối chiếu phát âm. Dữ liệu hồ sơ, lịch sử và phản hồi được lưu trong SQLite trên thiết bị. Gỡ ứng dụng sẽ xóa dữ liệu.\n\nĐiểm IPA là ước lượng từ kết quả speech-to-text, chưa phải đánh giá âm học chuyên dụng. Không dùng độ tin cậy nhận dạng làm điểm phát âm.',
      ),
    ),
  ];
}
