import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../models/document.dart';
import '../providers/category_provider.dart';
import '../providers/document_provider.dart';
import '../providers/subject_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/share_document_dialog.dart';
import '../widgets/user_account_header.dart';
import 'add_edit_document_page.dart';
import 'document_detail_page.dart';

class DocumentListPage extends StatelessWidget {
  const DocumentListPage({super.key});

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return const _FilterBottomSheetContent();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    final hasActiveFilter = docProvider.selectedSubjectId != 'all' ||
        docProvider.selectedFileType != 'all' ||
        docProvider.isFavoriteOnly ||
        docProvider.isCompletedFilter != null ||
        docProvider.sortBy != AppConstants.sortDateDesc;

    List<Document> displayedDocs;
    if (docProvider.sharingTabIndex == 1) {
      displayedDocs = docProvider.myDocuments;
    } else if (docProvider.sharingTabIndex == 2) {
      displayedDocs = docProvider.sharedWithMeDocuments;
    } else {
      displayedDocs = docProvider.documents;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Tài Liệu'),
        actions: [
          const UserAccountHeader(compact: true),
          const SizedBox(width: 4),
          if (hasActiveFilter)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: 'Xóa bộ lọc',
              onPressed: () => docProvider.resetFilters(),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBarWidget(
              initialValue: docProvider.searchQuery,
              onChanged: (q) => docProvider.setSearchQuery(q),
              onFilterTap: () => _showFilterModal(context),
              hasActiveFilter: hasActiveFilter,
            ),
          ),

          // Sharing Filter Chips (Cuộn ngang an toàn tuyệt đối, không bao giờ bị overflow)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  avatar: const Icon(Icons.folder_copy_outlined, size: 16),
                  label: Text('Tất cả (${docProvider.documents.length})'),
                  selected: docProvider.sharingTabIndex == 0,
                  onSelected: (_) => docProvider.setSharingTab(0),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.person_outline, size: 16),
                  label: Text('Của tôi (${docProvider.myDocuments.length})'),
                  selected: docProvider.sharingTabIndex == 1,
                  onSelected: (_) => docProvider.setSharingTab(1),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.people_outline, size: 16),
                  label: Text('Được chia sẻ (${docProvider.sharedWithMeDocuments.length})'),
                  selected: docProvider.sharingTabIndex == 2,
                  onSelected: (_) => docProvider.setSharingTab(2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Category Chips
          CategoryChipBar(
            categories: categoryProvider.categories,
            selectedCategoryId: docProvider.selectedCategoryId,
            onSelected: (catId) => docProvider.setSelectedCategory(catId),
          ),
          const SizedBox(height: 6),

          // Count & Sort Info bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${displayedDocs.length} tài liệu hiển thị',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showFilterModal(context),
                  child: Row(
                    children: [
                      Icon(Icons.sort_rounded, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        docProvider.sortBy,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 12),

          // Documents List
          Expanded(
            child: docProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedDocs.isEmpty
                    ? EmptyStateWidget(
                        title: 'Không tìm thấy tài liệu nào',
                        message: docProvider.sharingTabIndex == 2
                            ? 'Chưa có ai chia sẻ tài liệu nào cho bạn. Hãy chuyển sang tài khoản Alice (Owner) để chia sẻ tài liệu!'
                            : (docProvider.searchQuery.isNotEmpty || hasActiveFilter
                                ? 'Thử thay đổi từ khóa hoặc đặt lại bộ lọc để tìm kiếm'
                                : 'Bắt đầu thêm tài liệu học tập mới bằng nút bên dưới'),
                        actionText: 'Thêm tài liệu',
                        onAction: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => const AddEditDocumentPage(),
                            ),
                          );
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: () => docProvider.loadDocuments(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: displayedDocs.length,
                          itemBuilder: (ctx, index) {
                            final doc = displayedDocs[index];
                            return DocumentCard(
                              document: doc,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (c) => DocumentDetailPage(documentId: doc.documentId),
                                  ),
                                );
                              },
                              onToggleFavorite: () =>
                                  docProvider.toggleFavorite(doc.documentId, doc.isFavorite),
                              onToggleCompleted: () =>
                                  docProvider.toggleCompleted(doc.documentId, doc.isCompleted),
                              onShare: () => ShareDocumentDialog.show(context, doc),
                              onEdit: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (c) => AddEditDocumentPage(documentToEdit: doc),
                                  ),
                                );
                              },
                              onDelete: () async {
                                final confirmed = await ConfirmDialog.show(
                                  context,
                                  title: 'Xóa tài liệu?',
                                  content: 'Tài liệu sẽ được chuyển vào Thùng rác.',
                                  confirmText: 'Chuyển vào thùng rác',
                                  isDestructive: true,
                                );
                                if (confirmed == true) {
                                  final success = await docProvider.deleteDocument(doc.documentId);
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã chuyển tài liệu vào Thùng rác')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(docProvider.errorMessage ?? 'Không thể xóa tài liệu'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const AddEditDocumentPage(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm tài liệu'),
      ),
    );
  }
}

class _FilterBottomSheetContent extends StatefulWidget {
  const _FilterBottomSheetContent();

  @override
  State<_FilterBottomSheetContent> createState() => _FilterBottomSheetContentState();
}

class _FilterBottomSheetContentState extends State<_FilterBottomSheetContent> {
  late String _subjectId;
  late String _fileType;
  late bool _favOnly;
  late bool? _completed;
  late String _sort;

  @override
  void initState() {
    super.initState();
    final p = Provider.of<DocumentProvider>(context, listen: false);
    _subjectId = p.selectedSubjectId;
    _fileType = p.selectedFileType;
    _favOnly = p.isFavoriteOnly;
    _completed = p.isCompletedFilter;
    _sort = p.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubjectProvider>(context);
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bộ lọc & Sắp xếp',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  docProvider.resetFilters();
                  Navigator.of(context).pop();
                },
                child: const Text('Đặt lại'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter by Subject
          DropdownButtonFormField<String>(
            value: _subjectId,
            decoration: const InputDecoration(
              labelText: 'Môn học',
              prefixIcon: Icon(Icons.school_rounded),
            ),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Tất cả môn học')),
              ...subProvider.subjects.map((s) => DropdownMenuItem(
                    value: s.subjectId,
                    child: Text('${s.code} - ${s.name}'),
                  )),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _subjectId = val);
            },
          ),
          const SizedBox(height: 14),

          // Filter by File Type
          DropdownButtonFormField<String>(
            value: _fileType,
            decoration: const InputDecoration(
              labelText: 'Định dạng tệp',
              prefixIcon: Icon(Icons.insert_drive_file_rounded),
            ),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('Tất cả định dạng')),
              ...AppConstants.supportedFileTypes.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t),
                  )),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _fileType = val);
            },
          ),
          const SizedBox(height: 14),

          // Sort option
          DropdownButtonFormField<String>(
            value: _sort,
            decoration: const InputDecoration(
              labelText: 'Sắp xếp theo',
              prefixIcon: Icon(Icons.sort_rounded),
            ),
            items: [
              AppConstants.sortDateDesc,
              AppConstants.sortDateAsc,
              AppConstants.sortTitleAsc,
              AppConstants.sortTitleDesc,
              AppConstants.sortSizeDesc,
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _sort = val);
            },
          ),
          const SizedBox(height: 14),

          // Favorites filter toggle
          SwitchListTile(
            title: const Text('Chỉ tài liệu yêu thích'),
            value: _favOnly,
            onChanged: (val) => setState(() => _favOnly = val),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 16),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                docProvider.setSelectedSubject(_subjectId);
                docProvider.setSelectedFileType(_fileType);
                if (_favOnly != docProvider.isFavoriteOnly) {
                  docProvider.toggleFavoriteOnly();
                }
                docProvider.setCompletedFilter(_completed);
                docProvider.setSortBy(_sort);
                Navigator.of(context).pop();
              },
              child: const Text('Áp dụng bộ lọc'),
            ),
          ),
        ],
      ),
    );
  }
}
