import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../models/subject.dart';
import '../providers/document_provider.dart';
import '../providers/subject_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/subject_card.dart';

class SubjectPage extends StatelessWidget {
  const SubjectPage({super.key});

  void _showAddEditSubjectDialog(BuildContext context, {Subject? subjectToEdit}) {
    showDialog(
      context: context,
      builder: (ctx) => _AddEditSubjectDialog(subjectToEdit: subjectToEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Môn học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Thêm môn học',
            onPressed: () => _showAddEditSubjectDialog(context),
          ),
        ],
      ),
      body: subjectProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : subjectProvider.subjects.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.school_rounded,
                  title: 'Chưa có môn học nào',
                  message: 'Thêm môn học mới để bắt đầu sắp xếp tài liệu theo từng học phần',
                  actionText: 'Thêm môn học',
                  onAction: () => _showAddEditSubjectDialog(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: subjectProvider.subjects.length,
                  itemBuilder: (ctx, index) {
                    final subject = subjectProvider.subjects[index];
                    return SubjectCard(
                      subject: subject,
                      onTap: () {
                        // Filter documents by this subject and switch view or pop
                        docProvider.setSelectedSubject(subject.subjectId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã chọn lọc tài liệu theo: ${subject.name}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      onEdit: () => _showAddEditSubjectDialog(context, subjectToEdit: subject),
                      onDelete: () async {
                        final confirmed = await ConfirmDialog.show(
                          context,
                          title: 'Xóa môn học?',
                          content: 'Nếu xóa môn học "${subject.name}", các tài liệu thuộc môn học này cũng sẽ bị xóa vào Thùng rác.',
                          confirmText: 'Xóa môn học',
                          isDestructive: true,
                        );
                        if (confirmed == true) {
                          await subjectProvider.deleteSubject(subject.subjectId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Đã xóa môn học ${subject.name}')),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSubjectDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm môn học'),
      ),
    );
  }
}

class _AddEditSubjectDialog extends StatefulWidget {
  final Subject? subjectToEdit;

  const _AddEditSubjectDialog({this.subjectToEdit});

  @override
  State<_AddEditSubjectDialog> createState() => _AddEditSubjectDialogState();
}

class _AddEditSubjectDialogState extends State<_AddEditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _lecturerController;
  late Color _selectedColor;
  late String _selectedIcon;

  bool get _isEditing => widget.subjectToEdit != null;

  @override
  void initState() {
    super.initState();
    final sub = widget.subjectToEdit;
    _nameController = TextEditingController(text: sub?.name ?? '');
    _codeController = TextEditingController(text: sub?.code ?? '');
    _lecturerController = TextEditingController(text: sub?.lecturer ?? '');
    _selectedColor = sub != null ? Color(sub.color) : AppColors.presetColors.first;
    _selectedIcon = sub?.icon ?? 'school';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _lecturerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final subProvider = Provider.of<SubjectProvider>(context, listen: false);
    final now = DateTime.now();

    final subject = Subject(
      subjectId: _isEditing ? widget.subjectToEdit!.subjectId : const Uuid().v4(),
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      lecturer: _lecturerController.text.trim(),
      color: _selectedColor.value,
      icon: _selectedIcon,
      order: _isEditing ? widget.subjectToEdit!.order : subProvider.subjects.length + 1,
      dateCreated: _isEditing ? widget.subjectToEdit!.dateCreated : now,
      dateTimeModified: now,
    );

    bool success;
    if (_isEditing) {
      success = await subProvider.updateSubject(subject);
    } else {
      success = await subProvider.addSubject(subject);
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Đã cập nhật môn học' : 'Đã thêm môn học mới'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_isEditing ? 'Sửa môn học' : 'Thêm môn học mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã môn học',
                  hintText: 'VD: INT3105',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên môn học *',
                  hintText: 'VD: Lập trình Di động',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên môn học';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lecturerController,
                decoration: const InputDecoration(
                  labelText: 'Giảng viên',
                  hintText: 'VD: TS. Nguyễn Văn A',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Màu sắc đại diện:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppColors.presetColors.map((color) {
                  final isSelected = _selectedColor.value == color.value;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Lưu' : 'Thêm'),
        ),
      ],
    );
  }
}
