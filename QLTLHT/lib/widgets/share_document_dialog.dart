import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/document.dart';
import '../models/document_permission.dart';
import '../providers/document_provider.dart';
import '../services/auth_service.dart';

class ShareDocumentDialog extends StatefulWidget {
  final Document document;

  const ShareDocumentDialog({
    super.key,
    required this.document,
  });

  static Future<void> show(BuildContext context, Document document) {
    return showDialog(
      context: context,
      builder: (ctx) => ShareDocumentDialog(document: document),
    );
  }

  @override
  State<ShareDocumentDialog> createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final TextEditingController _emailController = TextEditingController();
  PermissionLevel _selectedLevel = PermissionLevel.view;
  List<DocumentPermission> _permissions = [];
  bool _isLoading = true;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<DocumentProvider>(context, listen: false);
    try {
      final list = await provider.getDocumentPermissions(widget.document.documentId);
      if (mounted) {
        setState(() {
          _permissions = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi nạp quyền: $e')),
        );
      }
    }
  }

  Future<void> _shareWithEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email người nhận')),
      );
      return;
    }

    setState(() => _isActionInProgress = true);
    final provider = Provider.of<DocumentProvider>(context, listen: false);
    final success = await provider.shareDocument(
      documentId: widget.document.documentId,
      targetEmail: cleanEmail,
      permission: _selectedLevel,
    );

    if (mounted) {
      setState(() => _isActionInProgress = false);
      if (success) {
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chia sẻ tài liệu thành công cho $cleanEmail'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPermissions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Không thể chia sẻ tài liệu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _revokePermission(String targetUserId, String targetEmail) async {
    setState(() => _isActionInProgress = true);
    final provider = Provider.of<DocumentProvider>(context, listen: false);
    final success = await provider.revokePermission(
      documentId: widget.document.documentId,
      targetUserId: targetUserId,
    );

    if (mounted) {
      setState(() => _isActionInProgress = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thu hồi quyền của $targetEmail')),
        );
        _loadPermissions();
      }
    }
  }

  Future<void> _changePermission(String targetUserId, PermissionLevel newLevel) async {
    setState(() => _isActionInProgress = true);
    final provider = Provider.of<DocumentProvider>(context, listen: false);
    final success = await provider.updatePermissionLevel(
      documentId: widget.document.documentId,
      targetUserId: targetUserId,
      newLevel: newLevel,
    );

    if (mounted) {
      setState(() => _isActionInProgress = false);
      if (success) {
        _loadPermissions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<DocumentProvider>(context);
    final isOwner = widget.document.ownerId == null || widget.document.ownerId == provider.currentUserId;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.share_rounded, color: Colors.blue, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chia sẻ tài liệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Phân quyền truy cập an toàn (RBAC & RLS)', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin tài liệu
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded, size: 20, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.document.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Chủ sở hữu: ${widget.document.ownerEmail ?? widget.document.ownerName ?? "Bạn"}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!isOwner) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chỉ Chủ sở hữu tài liệu mới có quyền cấp hoặc thay đổi quyền chia sẻ cho người khác.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Form cấp quyền mới
                const Text(
                  'Cấp quyền cho người dùng mới',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Nhập email người nhận...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<PermissionLevel>(
                      value: _selectedLevel,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: PermissionLevel.view,
                          child: Text('Chỉ xem', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: PermissionLevel.edit,
                          child: Text('Được sửa', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                      onChanged: (lvl) {
                        if (lvl != null) setState(() => _selectedLevel = lvl);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Gợi ý chọn nhanh các tài khoản kiểm thử
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AuthService.testAccounts
                      .where((u) => u.id != provider.currentUserId)
                      .map((u) {
                    return ActionChip(
                      avatar: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(u.displayName[0], style: const TextStyle(fontSize: 10)),
                      ),
                      label: Text(
                        u.displayName.split(' ').first,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        _emailController.text = u.email;
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _isActionInProgress
                        ? null
                        : () => _shareWithEmail(_emailController.text),
                    icon: _isActionInProgress
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('Cấp quyền'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const Divider(height: 24),
              ],

              // Danh sách những người đang có quyền truy cập
              const Text(
                'Danh sách người có quyền truy cập',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_permissions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: Text(
                    'Tài liệu này chưa được chia sẻ cho ai.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _permissions.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (ctx, index) {
                    final perm = _permissions[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: perm.permissionLevel == PermissionLevel.edit
                            ? Colors.purple.shade100
                            : Colors.blue.shade100,
                        child: Icon(
                          perm.permissionLevel == PermissionLevel.edit
                              ? Icons.edit_note_rounded
                              : Icons.visibility_rounded,
                          size: 16,
                          color: perm.permissionLevel == PermissionLevel.edit
                              ? Colors.purple
                              : Colors.blue,
                        ),
                      ),
                      title: Text(
                        perm.userName ?? perm.userEmail,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        perm.userEmail,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: isOwner
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButton<PermissionLevel>(
                                  value: perm.permissionLevel,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: PermissionLevel.view,
                                      child: Text('Xem', style: TextStyle(fontSize: 12)),
                                    ),
                                    DropdownMenuItem(
                                      value: PermissionLevel.edit,
                                      child: Text('Sửa', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                  onChanged: (lvl) {
                                    if (lvl != null && lvl != perm.permissionLevel) {
                                      _changePermission(perm.userId, lvl);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                                  tooltip: 'Thu hồi quyền',
                                  onPressed: () => _revokePermission(perm.userId, perm.userEmail),
                                ),
                              ],
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                perm.permissionLevel.displayName,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
