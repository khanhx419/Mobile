import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/date_formatter.dart';
import '../models/delete_log.dart';
import '../providers/document_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_widget.dart';

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);
    final logs = docProvider.recycleBinLogs;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thùng rác (DeleteLogs)'),
        actions: [
          if (logs.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 18),
              label: const Text('Dọn sạch', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Dọn sạch thùng rác?',
                  content: 'Tất cả các bản ghi đã xóa sẽ bị hủy vĩnh viễn và không thể khôi phục.',
                  confirmText: 'Xóa toàn bộ',
                  isDestructive: true,
                );
                if (confirmed == true) {
                  await docProvider.clearRecycleBin();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã dọn sạch thùng rác')),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: logs.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.delete_outline_rounded,
              title: 'Thùng rác trống',
              message: 'Các tài liệu bị xóa sẽ được lưu trữ tạm thời tại đây theo cơ chế Tombstone của kiến trúc Cashew.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (ctx, index) {
                final DeleteLog log = logs[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đã xóa: ${DateFormatter.formatFull(log.dateTimeModified)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Restore button
                      IconButton(
                        icon: const Icon(Icons.restore_from_trash_rounded, color: Colors.green),
                        tooltip: 'Khôi phục tài liệu',
                        onPressed: () async {
                          if (log.id != null) {
                            final success = await docProvider.restoreDocument(log.id!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Đã khôi phục tài liệu' : 'Khôi phục thất bại'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      // Permanent Delete
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.red),
                        tooltip: 'Xóa vĩnh viễn',
                        onPressed: () async {
                          if (log.id != null) {
                            await docProvider.permanentDelete(log.id!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã xóa vĩnh viễn bản ghi')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
