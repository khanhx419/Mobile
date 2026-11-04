import 'package:flutter/material.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/file_helper.dart';
import '../models/document.dart';
import '../models/document_permission.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onShare;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onToggleCompleted,
    required this.onEdit,
    required this.onDelete,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectColor = document.subjectColor != null
        ? Color(document.subjectColor!)
        : theme.colorScheme.primary;
    final categoryColor = document.categoryColor != null
        ? Color(document.categoryColor!)
        : Colors.grey;

    final isViewer = document.userPermission == PermissionLevel.view;
    final isEditor = document.userPermission == PermissionLevel.edit;
    final isOwner = document.isOwner;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges & Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Subject Tag
                            Container(
                              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: subjectColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: subjectColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      document.subjectCode?.isNotEmpty == true
                                          ? '${document.subjectCode} - ${document.subjectName ?? ''}'
                                          : (document.subjectName ?? 'Môn học'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: subjectColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Category Tag
                            Container(
                              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                document.categoryName ?? 'Phân loại',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: categoryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Cloud / Firebase Storage Badge
                            if (document.storagePath != null || document.fileUrl != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cloud_done_rounded, size: 12, color: Colors.blue),
                                    SizedBox(width: 3),
                                    Text('Cloud', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),

                            // RBAC Badge (Shared With Me / Permission Status)
                            if (document.isSharedWithMe)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isEditor ? Colors.purple.withOpacity(0.12) : Colors.indigo.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isEditor ? Icons.edit_note_rounded : Icons.visibility_rounded,
                                      size: 12,
                                      color: isEditor ? Colors.purple : Colors.indigo,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isEditor ? 'Được chia sẻ (Sửa)' : 'Được chia sẻ (Xem)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isEditor ? Colors.purple : Colors.indigo,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Favorite Button
                  IconButton(
                    icon: Icon(
                      document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: document.isFavorite ? Colors.amber : Colors.grey.shade400,
                      size: 22,
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: onToggleFavorite,
                  ),

                  // More Menu (Share / Edit / Delete)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey.shade500),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == 'share' && onShare != null) onShare!();
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      if (isOwner && onShare != null)
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_outlined, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Chia sẻ tài liệu'),
                            ],
                          ),
                        ),
                      if (document.canEdit)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                      if (isOwner)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xóa tài liệu', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                document.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: document.isCompleted ? TextDecoration.lineThrough : null,
                  color: document.isCompleted ? Colors.grey : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (document.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  document.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Footer: File Type, Size, Date, Completed checkbox
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.getFileTypeIcon(document.fileType),
                            size: 15,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            document.fileType,
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                          ),
                          if (document.fileSizeBytes > 0) ...[
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: Colors.grey.shade400)),
                            const SizedBox(width: 6),
                            Text(
                              FileHelper.formatBytes(document.fileSizeBytes),
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Text('•', style: TextStyle(color: Colors.grey.shade400)),
                          const SizedBox(width: 6),
                          Text(
                            DateFormatter.formatRelative(document.dateTimeModified),
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Mark as completed checkbox
                  InkWell(
                    onTap: onToggleCompleted,
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        Icon(
                          document.isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: document.isCompleted ? Colors.green : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          document.isCompleted ? 'Đã học' : 'Chưa học',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: document.isCompleted ? Colors.green : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
