import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habit; // Nếu null là Thêm mới, khác null là Chỉnh sửa

  const HabitFormScreen({super.key, this.habit});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  late String _frequencyType;
  late List<int> _selectedDays;
  late TimeOfDay _reminderTime;
  late int _selectedColorValue;
  late int _selectedIconCode;

  final List<int> _availableColors = [
    0xFF2196F3, // Blue
    0xFF0288D1, // Light Blue
    0xFF4CAF50, // Green
    0xFF388E3C, // Dark Green
    0xFFFF9800, // Orange
    0xFFE64A19, // Deep Orange
    0xFF9C27B0, // Purple
    0xFFE91E63, // Pink
    0xFF009688, // Teal
    0xFF607D8B, // Blue Grey
  ];

  final List<IconData> _availableIcons = [
    Icons.check_circle_outline,
    Icons.fitness_center,
    Icons.menu_book,
    Icons.local_drink,
    Icons.alarm,
    Icons.school,
    Icons.directions_run,
    Icons.bedtime,
    Icons.self_improvement,
    Icons.laptop_mac,
    Icons.eco,
    Icons.favorite,
    Icons.music_note,
    Icons.edit_note,
    Icons.savings,
    Icons.wb_sunny,
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _titleController = TextEditingController(text: h?.title ?? '');
    _descController = TextEditingController(text: h?.description ?? '');
    _frequencyType = h?.frequencyType ?? 'daily';
    _selectedDays = h != null ? List<int>.from(h.selectedDays) : [1, 2, 3, 4, 5, 6, 7];

    if (h != null && h.reminderTime.contains(':')) {
      final parts = h.reminderTime.split(':');
      _reminderTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    } else {
      _reminderTime = const TimeOfDay(hour: 8, minute: 0);
    }

    _selectedColorValue = h?.colorValue ?? _availableColors[0];
    _selectedIconCode = h?.iconCodePoint ?? _availableIcons[0].codePoint;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: 'CHỌN GIỜ NHẮC NHỞ',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  void _saveHabit() {
    if (!_formKey.currentState!.validate()) return;

    if (_frequencyType == 'specific_days' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một ngày trong tuần!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final provider = Provider.of<HabitProvider>(context, listen: false);

    final habitData = Habit(
      id: widget.habit?.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      frequencyType: _frequencyType,
      selectedDays: _frequencyType == 'daily' ? [1, 2, 3, 4, 5, 6, 7] : _selectedDays,
      reminderTime: _formatTimeOfDay(_reminderTime),
      colorValue: _selectedColorValue,
      iconCodePoint: _selectedIconCode,
      createdAt: widget.habit?.createdAt,
      isArchived: widget.habit?.isArchived ?? false,
    );

    if (widget.habit == null) {
      provider.addHabit(habitData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm thói quen mới thành công!')),
      );
    } else {
      provider.updateHabit(habitData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thói quen thành công!')),
      );
    }

    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa thói quen "${widget.habit?.title}" không? Toàn bộ lịch sử hoàn thành sẽ bị xóa.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.habit?.id != null) {
                Provider.of<HabitProvider>(context, listen: false)
                    .deleteHabit(widget.habit!.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa thói quen!')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habit != null;
    final theme = Theme.of(context);

    final dayLabels = [
      {'val': 1, 'label': 'T2'},
      {'val': 2, 'label': 'T3'},
      {'val': 3, 'label': 'T4'},
      {'val': 4, 'label': 'T5'},
      {'val': 5, 'label': 'T6'},
      {'val': 6, 'label': 'T7'},
      {'val': 7, 'label': 'CN'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa thói quen' : 'Tạo thói quen mới'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Xóa thói quen',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Preview Thẻ thói quen nhanh
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Color(_selectedColorValue),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(_selectedColorValue).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  IconData(_selectedIconCode, fontFamily: 'MaterialIcons'),
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nhập Tên thói quen
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tên thói quen *',
                hintText: 'Ví dụ: Đọc sách 20 phút, Uống nước...',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập tên thói quen';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Nhập Mô tả / Mục tiêu
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Mô tả / Động lực rèn luyện',
                hintText: 'Lý do bạn muốn duy trì thói quen này...',
                prefixIcon: const Icon(Icons.notes_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),

            // Chọn Tần suất
            Text(
              'Tần suất thực hiện',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Hàng ngày')),
                    selected: _frequencyType == 'daily',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _frequencyType = 'daily';
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Tùy chỉnh ngày')),
                    selected: _frequencyType == 'specific_days',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _frequencyType = 'specific_days';
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            if (_frequencyType == 'specific_days') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: dayLabels.map((d) {
                  final isSelected = _selectedDays.contains(d['val']);
                  return FilterChip(
                    label: Text(d['label'] as String),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(d['val'] as int);
                          _selectedDays.sort();
                        } else {
                          _selectedDays.remove(d['val'] as int);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // Thời gian nhắc nhở
            Text(
              'Thời gian nhắc nhở',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(14),
                  color: theme.colorScheme.surface,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          _formatTimeOfDay(_reminderTime),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Thay đổi',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Chọn Biểu tượng (Icon)
            Text(
              'Biểu tượng',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableIcons.map((iconData) {
                final isSelected = _selectedIconCode == iconData.codePoint;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIconCode = iconData.codePoint;
                    });
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(_selectedColorValue).withOpacity(0.2)
                          : theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Color(_selectedColorValue)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected
                          ? Color(_selectedColorValue)
                          : theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Chọn Màu sắc
            Text(
              'Màu sắc chủ đạo',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableColors.map((colorVal) {
                final isSelected = _selectedColorValue == colorVal;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorValue = colorVal;
                    });
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(colorVal).withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 22)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),

            // Nút Lưu
            ElevatedButton(
              onPressed: _saveHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(_selectedColorValue),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              child: Text(
                isEditing ? 'LƯU THAY ĐỔI' : 'TẠO THÓI QUEN',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
