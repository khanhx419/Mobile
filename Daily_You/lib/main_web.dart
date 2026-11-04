// Web edition based on Daily You, copyright Demizo and contributors.
// SPDX-License-Identifier: GPL-3.0-only
import 'dart:convert';

import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/models/entry.dart';
import 'package:daily_you/web/download.dart';
import 'package:daily_you/web/journal_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi');
  try {
    final store = BrowserJournalStore(await SharedPreferences.getInstance());
    store.load();
    runApp(WebJournalApp(store: store));
  } catch (_) {
    runApp(const MaterialApp(
        home: Scaffold(
            body: Center(
                child: Padding(
      padding: EdgeInsets.all(24),
      child: SelectableText(
          'Không thể đọc dữ liệu nhật ký. Dữ liệu hiện có chưa bị thay đổi. '
          'Hãy kiểm tra quyền lưu trữ của trình duyệt rồi tải lại trang.'),
    )))));
  }
}

class WebJournalApp extends StatefulWidget {
  const WebJournalApp({super.key, required this.store});
  final BrowserJournalStore store;
  @override
  State<WebJournalApp> createState() => _WebJournalAppState();
}

class _WebJournalAppState extends State<WebJournalApp> {
  bool get dark => widget.store.preferences.getBool('web_dark') ?? false;
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Nhật Ký Việt',
        debugShowCheckedModeBanner: false,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        theme: ThemeData(
            colorScheme:
                ColorScheme.fromSeed(seedColor: const Color(0xff416b57)),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xfff8faf7)),
        darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xff8cb69b),
                brightness: Brightness.dark),
            useMaterial3: true),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: JournalHome(
            store: widget.store,
            toggleTheme: () async {
              await widget.store.preferences.setBool('web_dark', !dark);
              setState(() {});
            }),
      );
}

const moods = ['😔', '😕', '😐', '🙂', '☺️'];
const moodNames = ['Rất buồn', 'Buồn', 'Bình thường', 'Vui', 'Rất vui'];

class JournalHome extends StatefulWidget {
  const JournalHome(
      {super.key, required this.store, required this.toggleTheme});
  final BrowserJournalStore store;
  final VoidCallback toggleTheme;
  @override
  State<JournalHome> createState() => _JournalHomeState();
}

class _JournalHomeState extends State<JournalHome> {
  int page = 0;
  String query = '';
  DateTime? selectedDate;
  bool busy = false;
  List<BrowserEntry> get entries => widget.store.entries;
  List<BrowserEntry> get filtered => entries
      .where((e) =>
          '${e.title} ${e.entry.text} ${e.tags}'
              .toLowerCase()
              .contains(query.toLowerCase()) &&
          (selectedDate == null ||
              DateUtils.isSameDay(e.entry.timeCreate, selectedDate)))
      .toList()
    ..sort((a, b) => b.entry.timeCreate.compareTo(a.entry.timeCreate));

  void message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<bool> persist(List<BrowserEntry> next) async {
    setState(() => busy = true);
    try {
      await widget.store.save(next);
      if (mounted) setState(() {});
      return true;
    } catch (_) {
      message(
          'Không thể lưu. Bộ nhớ trình duyệt có thể đã đầy. Hãy sao lưu và giảm số ảnh.');
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit([BrowserEntry? value]) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => JournalEditor(
            value: value,
            onSave: (result) => persist([
                  ...entries.where((e) => e.entry.id != result.entry.id),
                  result
                ]))));
  }

  Future<void> remove(BrowserEntry value) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Xóa nhật ký'),
                content: const Text('Bạn có muốn xóa nhật ký này không?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xóa'))
                ]));
    if (confirmed == true) {
      await persist(
          entries.where((e) => e.entry.id != value.entry.id).toList());
    }
  }

  Future<void> restore() async {
    try {
      final file = await FilePicker.pickFile(
          type: FileType.custom, allowedExtensions: ['json']);
      if (file == null) return;
      if ((await file.length() ?? 20000001) > 20000000) {
        throw const FormatException();
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > 20000000) throw const FormatException();
      final imported = BrowserJournalStore.decode(utf8.decode(bytes));
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Khôi phục bản sao lưu'),
                  content: Text(
                      'Thay thế ${entries.length} nhật ký hiện tại bằng ${imported.length} nhật ký trong tệp? Hãy tải bản sao lưu hiện tại trước khi tiếp tục.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Khôi phục'))
                  ]));
      if (confirmed == true && await persist(imported)) {
        message('Đã khôi phục nhật ký.');
      }
    } catch (_) {
      message(
          'Không thể nhập tệp. Hãy chọn bản sao lưu JSON của Nhật Ký Việt Web.');
    }
  }

  Widget entryCard(BrowserEntry value) => Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: busy ? null : () => edit(value),
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(
                              DateFormat('EEEE, dd/MM/yyyy', 'vi')
                                  .format(value.entry.timeCreate),
                              style: Theme.of(context).textTheme.labelLarge)),
                      Text(
                          value.entry.mood == null
                              ? ''
                              : moods[value.entry.mood! + 2],
                          style: const TextStyle(fontSize: 24)),
                      PopupMenuButton<String>(
                          tooltip: 'Tùy chọn',
                          enabled: !busy,
                          onSelected: (action) =>
                              action == 'edit' ? edit(value) : remove(value),
                          itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('Chỉnh sửa')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Xóa nhật ký'))
                              ])
                    ]),
                    if (value.title.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(value.title,
                              style: Theme.of(context).textTheme.titleLarge)),
                    Text(value.entry.text,
                        maxLines: 5, overflow: TextOverflow.ellipsis),
                    if (value.tags.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                              value.tags
                                  .split(',')
                                  .map((t) => '#${t.trim()}')
                                  .join('  '),
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary))),
                    if (value.images.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Image.memory(
                              base64Decode(value.images.first.split(',').last),
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stack) =>
                                  const Text('Không thể hiển thị ảnh'))),
                  ]))));

  Widget journal() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Mỗi ngày đều đáng nhớ.',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
            'Lưu lại suy nghĩ, cảm xúc và những điều khiến bạn mỉm cười.'),
        const SizedBox(height: 24),
        TextField(
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm nội dung, tiêu đề hoặc nhãn…',
                border: OutlineInputBorder()),
            onChanged: (value) => setState(() => query = value)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ActionChip(
              avatar: const Icon(Icons.calendar_month, size: 18),
              label: Text(selectedDate == null
                  ? 'Chọn ngày'
                  : DateFormat('dd/MM/yyyy').format(selectedDate!)),
              onPressed: () async {
                final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2200));
                if (date != null) setState(() => selectedDate = date);
              }),
          if (selectedDate != null)
            ActionChip(
                label: const Text('Tất cả ngày'),
                onPressed: () => setState(() => selectedDate = null)),
          Chip(label: Text('${filtered.length} nhật ký'))
        ]),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                  child: Text(
                      'Chưa có nhật ký phù hợp. Hãy ghi lại ngày hôm nay!'))),
        ...filtered.map(entryCard),
      ]);

  Widget stats() {
    final days = entries
        .map((e) => DateUtils.dateOnly(e.entry.timeCreate))
        .toSet()
        .length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Thống kê', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      Wrap(spacing: 16, runSpacing: 16, children: [
        Chip(label: Text('${entries.length} nhật ký')),
        Chip(label: Text('$days ngày ghi chép')),
        Chip(
            label: Text(
                '${entries.fold<int>(0, (n, e) => n + e.images.length)} hình ảnh'))
      ]),
      const SizedBox(height: 28),
      Text('Tâm trạng của bạn', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      for (var i = 0; i < moods.length; i++)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              SizedBox(width: 120, child: Text('${moods[i]} ${moodNames[i]}')),
              Expanded(
                  child: LinearProgressIndicator(
                      value: entries.isEmpty
                          ? 0
                          : entries.where((e) => e.entry.mood == i - 2).length /
                              entries.length,
                      minHeight: 12)),
              SizedBox(
                  width: 50,
                  child: Text(
                      '${entries.where((e) => e.entry.mood == i - 2).length}',
                      textAlign: TextAlign.end))
            ])),
    ]);
  }

  Widget settings() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Cài đặt', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        Card(
            child: Column(children: [
          ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Ngôn ngữ'),
              subtitle: const Text('Tiếng Việt')),
          ListTile(
              leading: const Icon(Icons.contrast),
              title: const Text('Giao diện sáng / tối'),
              onTap: widget.toggleTheme),
          ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Tải bản sao lưu JSON'),
              subtitle:
                  const Text('Bao gồm nhật ký, tâm trạng, nhãn và hình ảnh.'),
              onTap: () {
                downloadBackup(widget.store.encode(),
                    'nhat-ky-viet-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json');
              }),
          ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Khôi phục từ tệp JSON'),
              onTap: busy ? null : restore),
        ])),
        const SizedBox(height: 20),
        const Text(
            'Dữ liệu được lưu trong trình duyệt tại địa chỉ này. Hãy tải bản sao lưu định kỳ; '
            'xóa dữ liệu trang web, đổi trình duyệt hoặc đổi cổng localhost sẽ không giữ cùng kho nhật ký.'),
        const SizedBox(height: 28),
        Text('Giới thiệu', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const SelectableText('Nhật Ký Việt Web — bản sửa đổi độc lập dựa trên '
            'Daily You của Demizo và cộng đồng, không phải ứng dụng chính thức. Giấy phép GPL-3.0.\n'
            'Mã nguồn: https://github.com/khanhx419/Dail_You\n'
            'Bản gốc: https://github.com/Demizo/Daily_You'),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nhật Ký Việt'), actions: [
          IconButton(
              tooltip: 'Đổi giao diện',
              onPressed: widget.toggleTheme,
              icon: const Icon(Icons.contrast)),
          const SizedBox(width: 12)
        ]),
        body: Column(children: [
          if (busy) const LinearProgressIndicator(),
          Expanded(
              child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                          children: [
                            if (page == 0) journal(),
                            if (page == 1)
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Thư viện ảnh',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium),
                                    const SizedBox(height: 20),
                                    if (entries.every((e) => e.images.isEmpty))
                                      const Text('Chưa có hình ảnh.'),
                                    ...entries
                                        .where((e) => e.images.isNotEmpty)
                                        .map(entryCard)
                                  ]),
                            if (page == 2) stats(),
                            if (page == 3) settings(),
                          ]))))
        ]),
        floatingActionButton: page == 0
            ? FloatingActionButton.extended(
                onPressed: busy ? null : () => edit(),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Viết nhật ký'))
            : null,
        bottomNavigationBar: NavigationBar(
            selectedIndex: page,
            onDestinationSelected: (i) => setState(() => page = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
              NavigationDestination(
                  icon: Icon(Icons.photo_library_outlined), label: 'Thư viện'),
              NavigationDestination(
                  icon: Icon(Icons.bar_chart), label: 'Thống kê'),
              NavigationDestination(
                  icon: Icon(Icons.settings_outlined), label: 'Cài đặt')
            ]),
      );
}

class JournalEditor extends StatefulWidget {
  const JournalEditor({super.key, this.value, required this.onSave});
  final BrowserEntry? value;
  final Future<bool> Function(BrowserEntry) onSave;
  @override
  State<JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<JournalEditor> {
  late final title = TextEditingController(text: widget.value?.title);
  late final text = TextEditingController(text: widget.value?.entry.text);
  late final tags = TextEditingController(text: widget.value?.tags);
  late DateTime date = widget.value?.entry.timeCreate ?? DateTime.now();
  late int? mood = widget.value?.entry.mood;
  late List<String> images = List.of(widget.value?.images ?? []);
  bool preview = false;
  bool dirty = false;
  bool saving = false;
  bool allowExit = false;

  void exitEditor() {
    setState(() => allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void initState() {
    super.initState();
    for (final controller in [title, text, tags]) {
      controller.addListener(() => dirty = true);
    }
  }

  @override
  void dispose() {
    title.dispose();
    text.dispose();
    tags.dispose();
    super.dispose();
  }

  Future<void> addImage() async {
    try {
      final file = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif']);
      if (file == null || !mounted) return;
      final size = await file.length() ?? 1500001;
      if (!mounted) return;
      if (size > 1500000 || images.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Mỗi nhật ký hỗ trợ tối đa 3 ảnh, mỗi ảnh không quá 1,5 MB.')));
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final ext = file.extension?.toLowerCase() == 'jpg'
          ? 'jpeg'
          : file.extension?.toLowerCase();
      setState(() {
        images.add('data:image/$ext;base64,${base64Encode(bytes)}');
        dirty = true;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Không thể mở ảnh.')));
      }
    }
  }

  Future<void> leave() async {
    if (saving) return;
    if (!dirty) {
      exitEditor();
      return;
    }
    final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Bỏ các thay đổi chưa lưu?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Tiếp tục viết')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Bỏ thay đổi'))
                ]));
    if (discard == true && mounted) exitEditor();
  }

  Future<void> save() async {
    if (saving) return;
    if (text.text.trim().isEmpty &&
        title.text.trim().isEmpty &&
        images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Hãy nhập nội dung hoặc thêm ảnh trước khi lưu.')));
      return;
    }
    setState(() => saving = true);
    final result = BrowserEntry(
        title: title.text.trim(),
        tags: tags.text.trim(),
        images: images,
        entry: Entry(
            id: widget.value?.entry.id ?? DateTime.now().microsecondsSinceEpoch,
            text: text.text,
            mood: mood,
            timeCreate: date,
            timeModified: DateTime.now()));
    final saved = await widget.onSave(result);
    if (!mounted) return;
    setState(() => saving = false);
    if (saved) {
      exitEditor();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Chưa lưu được. Nội dung vẫn ở đây; hãy giảm số ảnh và thử lại.')));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: allowExit,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(
            leading: IconButton(
                tooltip: 'Quay lại',
                onPressed: leave,
                icon: const Icon(Icons.arrow_back)),
            title: Text(
                widget.value == null ? 'Nhật ký mới' : 'Chỉnh sửa nhật ký'),
            actions: [
              TextButton.icon(
                  onPressed: saving ? null : save,
                  icon: const Icon(Icons.check),
                  label: const Text('Lưu')),
              const SizedBox(width: 12)
            ]),
        body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  TextField(
                      controller: title,
                      decoration: const InputDecoration(
                          hintText: 'Tiêu đề…', border: InputBorder.none),
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 10, children: [
                    ActionChip(
                        avatar: const Icon(Icons.calendar_today, size: 18),
                        label: Text(DateFormat('dd/MM/yyyy').format(date)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2200));
                          if (picked != null) {
                            setState(() {
                              date = picked;
                              dirty = true;
                            });
                          }
                        }),
                    for (var i = 0; i < moods.length; i++)
                      ChoiceChip(
                          tooltip: moodNames[i],
                          label: Text(moods[i],
                              style: const TextStyle(fontSize: 22)),
                          selected: mood == i - 2,
                          onSelected: (selected) => setState(() {
                                mood = selected ? i - 2 : null;
                                dirty = true;
                              }))
                  ]),
                  const SizedBox(height: 20),
                  TextField(
                      controller: tags,
                      decoration: const InputDecoration(
                          labelText: 'Nhãn',
                          hintText: 'Gia đình, công việc, biết ơn',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, children: [
                    TextButton.icon(
                        onPressed: () => setState(() => preview = !preview),
                        icon: Icon(
                            preview ? Icons.edit : Icons.visibility_outlined),
                        label:
                            Text(preview ? 'Soạn thảo' : 'Xem trước Markdown')),
                    TextButton.icon(
                        onPressed: addImage,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Thêm ảnh')),
                    PopupMenuButton<String>(
                        tooltip: 'Chèn mẫu nhật ký',
                        onSelected: (value) {
                          text.text += value;
                          setState(() {});
                        },
                        itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value:
                                      '\n### Tóm tắt hôm nay\n- \n\n### Điều tôi biết ơn\n- ',
                                  child: Text('Mẫu tóm tắt')),
                              PopupMenuItem(
                                  value:
                                      '\n### Hôm nay tôi cảm thấy thế nào?\n\n### Tôi đã học được gì?\n\n### Ngày mai tôi mong đợi điều gì?\n',
                                  child: Text('Mẫu suy ngẫm'))
                            ],
                        child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Chèn mẫu ▾')))
                  ]),
                  const SizedBox(height: 8),
                  if (preview)
                    MarkdownBlock(data: text.text)
                  else
                    TextField(
                        controller: text,
                        minLines: 12,
                        maxLines: null,
                        decoration: const InputDecoration(
                            hintText:
                                'Viết gì đó…\n\nBạn có thể định dạng bằng Markdown.',
                            border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  for (var i = 0; i < images.length; i++)
                    Column(children: [
                      Image.memory(base64Decode(images[i].split(',').last),
                          height: 220,
                          errorBuilder: (_, error, stack) =>
                              const Text('Không thể hiển thị ảnh')),
                      TextButton.icon(
                          onPressed: () => setState(() {
                                images.removeAt(i);
                                dirty = true;
                              }),
                          icon: const Icon(Icons.close),
                          label: const Text('Bỏ ảnh'))
                    ]),
                  const SizedBox(height: 48),
                ]))),
      ));
}
