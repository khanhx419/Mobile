import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/file_helper.dart';
import '../models/document.dart';
import '../models/document_permission.dart';
import '../providers/document_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/share_document_dialog.dart';
import 'add_edit_document_page.dart';

class DocumentDetailPage extends StatelessWidget {
  final String documentId;

  const DocumentDetailPage({
    super.key,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);
    final documentList = docProvider.documents;
    final docIndex = documentList.indexWhere((d) => d.documentId == documentId);

    if (docIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết tài liệu')),
        body: const Center(
          child: Text('Tài liệu không tồn tại hoặc bạn không có quyền truy cập.'),
        ),
      );
    }

    final Document doc = documentList[docIndex];
    final theme = Theme.of(context);
    final subjectColor = doc.subjectColor != null ? Color(doc.subjectColor!) : theme.colorScheme.primary;
    final categoryColor = doc.categoryColor != null ? Color(doc.categoryColor!) : Colors.grey;

    final isOwner = doc.isOwner;
    final canEdit = doc.canEdit;
    final isViewer = doc.userPermission == PermissionLevel.view;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tài liệu'),
        actions: [
          // Nút chia sẻ tài liệu
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Chia sẻ tài liệu (RBAC)',
            onPressed: () => ShareDocumentDialog.show(context, doc),
          ),
          IconButton(
            icon: Icon(
              doc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: doc.isFavorite ? Colors.amber : null,
            ),
            tooltip: 'Yêu thích',
            onPressed: () => docProvider.toggleFavorite(doc.documentId, doc.isFavorite),
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Chỉnh sửa',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => AddEditDocumentPage(documentToEdit: doc),
                  ),
                );
              },
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Xóa tài liệu',
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Xóa tài liệu?',
                  content: 'Tài liệu và tệp tin trên Cloud sẽ được chuyển vào Thùng rác.',
                  confirmText: 'Chuyển vào thùng rác',
                  isDestructive: true,
                );
                if (confirmed == true) {
                  await docProvider.deleteDocument(doc.documentId);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa tài liệu khỏi hệ thống')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner phân quyền nếu là Viewer / Editor
          if (isViewer) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.visibility_rounded, color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bạn đang xem tài liệu được chia sẻ ở quyền "Chỉ xem (Viewer)". Bạn không thể chỉnh sửa hoặc xóa tài liệu này.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else if (!isOwner && canEdit) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: Colors.purple, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bạn được cấp quyền "Chỉnh sửa (Editor)". Bạn có thể cập nhật thông tin tài liệu nhưng không có quyền xóa.',
                      style: TextStyle(fontSize: 12, color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Badges: Subject, Category, Status, Cloud
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: subjectColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: subjectColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      doc.subjectCode?.isNotEmpty == true
                          ? '${doc.subjectCode} - ${doc.subjectName ?? ''}'
                          : (doc.subjectName ?? 'Môn học'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: subjectColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  doc.categoryName ?? 'Phân loại',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: doc.isCompleted ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      doc.isCompleted ? Icons.check_circle_rounded : Icons.pending_rounded,
                      size: 14,
                      color: doc.isCompleted ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      doc.isCompleted ? 'Đã học' : 'Đang học',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: doc.isCompleted ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              // Cloud Badge
              if (doc.storagePath != null || doc.fileUrl != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done_rounded, size: 14, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Firebase Storage',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            doc.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Metadata Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  icon: AppIcons.getFileTypeIcon(doc.fileType),
                  label: 'Định dạng tệp',
                  value: doc.fileType,
                ),
                const Divider(height: 20),
                _buildInfoRow(
                  context,
                  icon: Icons.person_outline_rounded,
                  label: 'Chủ sở hữu',
                  value: doc.ownerEmail ?? doc.ownerName ?? 'Chính bạn',
                ),
                const Divider(height: 20),
                _buildInfoRow(
                  context,
                  icon: Icons.data_usage_rounded,
                  label: 'Kích thước',
                  value: doc.fileSizeBytes > 0 ? FileHelper.formatBytes(doc.fileSizeBytes) : 'Không xác định',
                ),
                const Divider(height: 20),
                _buildInfoRow(
                  context,
                  icon: Icons.calendar_today_rounded,
                  label: 'Ngày tải lên',
                  value: DateFormatter.formatFull(doc.dateCreated),
                ),
                const Divider(height: 20),
                _buildInfoRow(
                  context,
                  icon: Icons.update_rounded,
                  label: 'Lần sửa cuối',
                  value: DateFormatter.formatFull(doc.dateTimeModified),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tags section
          if (doc.tagsList.isNotEmpty) ...[
            const Text(
              'Từ khóa / Tags',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: doc.tagsList.map((tag) {
                return Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Description Section
          const Text(
            'Mô tả & Ghi chú',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
              ),
            ),
            child: Text(
              doc.description.isNotEmpty ? doc.description : 'Không có mô tả cho tài liệu này.',
              style: TextStyle(
                fontSize: 14,
                color: doc.description.isNotEmpty ? null : Colors.grey,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // File / URL action
          if (doc.fileUri.isNotEmpty || doc.fileName.isNotEmpty || doc.fileUrl != null) ...[
            const Text(
              'Tệp đính kèm & Firebase Storage',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(AppIcons.getFileTypeIcon(doc.fileType), size: 32, color: subjectColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.fileName.isNotEmpty ? doc.fileName : 'Tài liệu đính kèm',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (doc.storagePath != null && doc.storagePath!.isNotEmpty)
                              Text(
                                'Storage: ${doc.storagePath}',
                                style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontFamily: 'monospace'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        tooltip: 'Sao chép đường dẫn',
                        onPressed: () {
                          final textToCopy = doc.fileUrl ?? doc.fileUri;
                          Clipboard.setData(ClipboardData(text: textToCopy));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã sao chép liên kết tệp vào bộ nhớ tạm')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Toggle Completed Button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: doc.isCompleted ? Colors.grey.shade600 : Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => docProvider.toggleCompleted(doc.documentId, doc.isCompleted),
            icon: Icon(doc.isCompleted ? Icons.replay_rounded : Icons.check_circle_outline_rounded),
            label: Text(
              doc.isCompleted ? 'Đánh dấu là Chưa học' : 'Đánh dấu Đã học xong',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
