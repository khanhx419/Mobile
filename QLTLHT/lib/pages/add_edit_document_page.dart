import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/file_helper.dart';
import '../models/category.dart';
import '../models/document.dart';
import '../providers/category_provider.dart';
import '../providers/document_provider.dart';
import '../providers/subject_provider.dart';

class AddEditDocumentPage extends StatefulWidget {
  final Document? documentToEdit;
  final String? initialSubjectId;

  const AddEditDocumentPage({
    super.key,
    this.documentToEdit,
    this.initialSubjectId,
  });

  @override
  State<AddEditDocumentPage> createState() => _AddEditDocumentPageState();
}

class _AddEditDocumentPageState extends State<AddEditDocumentPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _fileNameController;
  late TextEditingController _fileUriController;
  late TextEditingController _tagsController;
  late TextEditingController _fileSizeController;

  String? _selectedSubjectId;
  String? _selectedCategoryId;
  String _selectedFileType = AppConstants.fileTypePdf;
  bool _isFavorite = false;
  bool _isCompleted = false;

  // File Picker variables for Firebase Storage
  PlatformFile? _pickedFile;
  Uint8List? _pickedFileBytes;
  String? _pickedFilePath;
  int? _pickedFileSize;
  bool _isUploading = false;

  bool get _isEditing => widget.documentToEdit != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.documentToEdit;

    _titleController = TextEditingController(text: doc?.title ?? '');
    _descController = TextEditingController(text: doc?.description ?? '');
    _fileNameController = TextEditingController(text: doc?.fileName ?? '');
    _fileUriController = TextEditingController(text: doc?.fileUri ?? '');
    _tagsController = TextEditingController(text: doc?.tags ?? '');
    _fileSizeController = TextEditingController(
      text: doc != null && doc.fileSizeBytes > 0 ? (doc.fileSizeBytes ~/ (1024 * 1024)).toString() : '2',
    );

    _selectedSubjectId = doc?.subjectFk ?? widget.initialSubjectId;
    _selectedCategoryId = doc?.categoryFk;
    _selectedFileType = doc?.fileType ?? AppConstants.fileTypePdf;
    _isFavorite = doc?.isFavorite ?? false;
    _isCompleted = doc?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _fileNameController.dispose();
    _fileUriController.dispose();
    _tagsController.dispose();
    _fileSizeController.dispose();
    super.dispose();
  }

  Future<void> _pickLocalFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result.isNotEmpty) {
        final file = result.first;
        final bytes = await file.readAsBytes();
        final size = await file.length() ?? file.lengthSync() ?? bytes.length;
        setState(() {
          _pickedFile = file;
          _pickedFileBytes = bytes;
          _pickedFilePath = file.path;
          _pickedFileSize = size;
          _fileNameController.text = file.name;

          // Tự động phát hiện kích thước
          final mb = (size / (1024 * 1024)).ceil();
          _fileSizeController.text = mb > 0 ? mb.toString() : '1';

          // Tự động phát hiện định dạng
          final ext = file.extension?.toUpperCase();
          if (ext != null) {
            if (AppConstants.supportedFileTypes.contains(ext)) {
              _selectedFileType = ext;
            } else if (ext == 'DOC' || ext == 'DOCX') {
              _selectedFileType = 'DOCX';
            } else if (ext == 'PPT' || ext == 'PPTX') {
              _selectedFileType = 'PPTX';
            } else if (ext == 'XLS' || ext == 'XLSX') {
              _selectedFileType = 'XLSX';
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã chọn tệp: ${file.name} (${FileHelper.formatBytes(size)})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn tệp: $e')),
        );
      }
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn môn học')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục tài liệu')),
      );
      return;
    }

    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    final sizeMb = int.tryParse(_fileSizeController.text.trim()) ?? 1;
    final sizeBytes = _pickedFileSize ?? (sizeMb * 1024 * 1024);
    final now = DateTime.now();

    final doc = Document(
      documentId: _isEditing ? widget.documentToEdit!.documentId : const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      subjectFk: _selectedSubjectId!,
      categoryFk: _selectedCategoryId!,
      fileType: _selectedFileType,
      fileName: _fileNameController.text.trim().isNotEmpty
          ? _fileNameController.text.trim()
          : '${_titleController.text.trim().replaceAll(' ', '_')}.pdf',
      fileUri: _fileUriController.text.trim(),
      fileSizeBytes: sizeBytes,
      tags: _tagsController.text.trim(),
      isFavorite: _isFavorite,
      isCompleted: _isCompleted,
      dateCreated: _isEditing ? widget.documentToEdit!.dateCreated : now,
      dateTimeModified: now,
      ownerId: _isEditing ? widget.documentToEdit!.ownerId : docProvider.currentUserId,
      ownerEmail: _isEditing ? widget.documentToEdit!.ownerEmail : null,
      storagePath: _isEditing ? widget.documentToEdit!.storagePath : null,
      fileUrl: _isEditing ? widget.documentToEdit!.fileUrl : null,
    );

    setState(() => _isUploading = true);

    bool success;
    if (_isEditing) {
      success = await docProvider.updateDocument(doc);
    } else {
      success = await docProvider.addDocumentWithCloudFile(
        doc: doc,
        fileBytes: _pickedFileBytes,
        localFilePath: _pickedFilePath,
      );
    }

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Đã cập nhật tài liệu trên Cloud' : 'Đã tải lên Firebase Storage & lưu vào Supabase'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(docProvider.errorMessage ?? 'Thao tác thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    // Default selection if not already chosen
    if (_selectedSubjectId == null && subjectProvider.subjects.isNotEmpty) {
      _selectedSubjectId = subjectProvider.subjects.first.subjectId;
    }
    if (_selectedCategoryId == null && categoryProvider.categories.isNotEmpty) {
      _selectedCategoryId = categoryProvider.categories.first.categoryId;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa tài liệu' : 'Thêm tài liệu mới'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? Colors.amber : null,
            ),
            tooltip: 'Yêu thích',
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          FilledButton.tonal(
            onPressed: _isUploading ? null : _saveDocument,
            child: _isUploading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Lưu'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Cloud Sync Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_upload_rounded, color: Colors.blue, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tệp sẽ được lưu trữ tự động trên Firebase Storage và siêu dữ liệu được lưu trên Supabase với chính sách bảo mật RLS.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title input
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề tài liệu *',
                hintText: 'VD: Slide Bài giảng Chương 2 - Kiến trúc Cloud Flutter',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Tiêu đề không được để trống';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // File Attachment Card with Picker
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TỆP ĐÍNH KÈM (FIREBASE STORAGE)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickLocalFile,
                          icon: const Icon(Icons.upload_file_rounded, size: 16),
                          label: const Text('Chọn tệp...'),
                        ),
                      ],
                    ),
                    if (_pickedFile != null) ...[
                      const SizedBox(height: 8),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                        title: Text(_pickedFile!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Kích thước: ${FileHelper.formatBytes(_pickedFileSize ?? 0)}'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subject selector
            DropdownButtonFormField<String>(
              value: _selectedSubjectId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Môn học *',
                prefixIcon: Icon(Icons.school_rounded),
              ),
              items: subjectProvider.subjects.map((sub) {
                return DropdownMenuItem(
                  value: sub.subjectId,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(sub.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${sub.code} - ${sub.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedSubjectId = val),
            ),
            const SizedBox(height: 16),

            // Category selector
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Phân loại tài liệu *',
                prefixIcon: Icon(Icons.folder_rounded),
              ),
              items: categoryProvider.categories.map<DropdownMenuItem<String>>((Category cat) {
                return DropdownMenuItem<String>(
                  value: cat.categoryId,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(cat.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
            const SizedBox(height: 16),

            // File Type selector
            DropdownButtonFormField<String>(
              value: _selectedFileType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Định dạng tệp *',
                prefixIcon: Icon(Icons.insert_drive_file_rounded),
              ),
              items: AppConstants.supportedFileTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedFileType = val);
              },
            ),
            const SizedBox(height: 16),

            // File Name
            TextFormField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'Tên tệp tin',
                hintText: 'VD: slide_chuong_2.pdf',
                prefixIcon: Icon(Icons.attachment_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Estimated Size
            TextFormField(
              controller: _fileSizeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kích thước (MB)',
                hintText: 'VD: 2',
                prefixIcon: Icon(Icons.data_usage_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // File URI / Link
            TextFormField(
              controller: _fileUriController,
              decoration: const InputDecoration(
                labelText: 'Đường dẫn / Liên kết trực tuyến (tùy chọn)',
                hintText: 'VD: https://firebasestorage.googleapis.com/...',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Nhãn / Từ khóa (phân cách bằng dấu phẩy)',
                hintText: 'VD: Slide, Chương 2, Firebase, Supabase',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mô tả & Ghi chú tóm tắt',
                hintText: 'Ghi chú nội dung trọng tâm, mục tiêu bài học...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Completion switch
            SwitchListTile(
              title: const Text('Đã hoàn thành / Đã học xong'),
              subtitle: const Text('Đánh dấu tài liệu này vào tiến độ học tập cá nhân'),
              value: _isCompleted,
              activeColor: Colors.green,
              onChanged: (val) => setState(() => _isCompleted = val),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Theme.of(context).cardColor,
            ),
            const SizedBox(height: 32),

            // Submit Button
            FilledButton.icon(
              onPressed: _isUploading ? null : _saveDocument,
              icon: _isUploading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isUploading
                    ? 'Đang tải lên Cloud...'
                    : (_isEditing ? 'Cập nhật tài liệu' : 'Lưu & Tải lên Cloud'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
