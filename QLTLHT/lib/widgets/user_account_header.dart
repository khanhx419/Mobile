import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';

class UserAccountHeader extends StatelessWidget {
  final bool compact;

  const UserAccountHeader({
    super.key,
    this.compact = false,
  });

  static void showAccountSwitcherDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.switch_account_rounded, color: Colors.indigo, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chọn tài khoản kiểm thử', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Phân quyền truy cập Cloud (Checklist 6)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: authProvider.testAccounts.map((account) {
                final isCurrent = authProvider.currentUser?.id == account.id;
                String roleBadge;
                Color badgeColor;

                if (account.email.contains('owner')) {
                  roleBadge = 'Chủ sở hữu (Owner)';
                  badgeColor = Colors.teal;
                } else if (account.email.contains('viewer')) {
                  roleBadge = 'Người xem (Viewer)';
                  badgeColor = Colors.blue;
                } else if (account.email.contains('editor')) {
                  roleBadge = 'Người sửa (Editor)';
                  badgeColor = Colors.purple;
                } else {
                  roleBadge = 'Người lạ (Unauthorized)';
                  badgeColor = Colors.grey;
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.2),
                      width: isCurrent ? 2 : 1,
                    ),
                    color: isCurrent ? Theme.of(context).colorScheme.primary.withOpacity(0.06) : null,
                  ),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: badgeColor.withOpacity(0.15),
                      child: Text(
                        account.displayName[0],
                        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            account.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            roleBadge,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: badgeColor),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(account.email, style: const TextStyle(fontSize: 11)),
                    trailing: isCurrent
                        ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 20)
                        : null,
                    onTap: () {
                      authProvider.switchTestAccount(account);
                      docProvider.setCurrentUserId(account.id);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã chuyển sang: ${account.displayName} ($roleBadge)'),
                          backgroundColor: badgeColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.login_rounded, size: 16),
        label: const Text('Đăng nhập', style: TextStyle(fontSize: 12)),
        onPressed: () => auth.signInWithGoogle(),
      );
    }

    String roleName = 'Owner';
    Color roleColor = Colors.teal;
    if (user.email.contains('viewer')) {
      roleName = 'Viewer';
      roleColor = Colors.blue;
    } else if (user.email.contains('editor')) {
      roleName = 'Editor';
      roleColor = Colors.purple;
    } else if (user.email.contains('stranger')) {
      roleName = 'Guest';
      roleColor = Colors.grey;
    }

    return InkWell(
      onTap: () => showAccountSwitcherDialog(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: roleColor.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: roleColor,
              child: Text(
                user.displayName.isNotEmpty ? user.displayName[0] : 'U',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 60 : 75),
              child: Text(
                user.displayName.split(' ').first,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                roleName,
                style: TextStyle(fontSize: 9, color: roleColor, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Banner hiển thị to, rõ thông tin tài khoản Cloud và phân quyền
class CloudUserBanner extends StatelessWidget {
  const CloudUserBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_circle_outlined, color: Colors.amber, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Chưa đăng nhập tài khoản Cloud',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton.tonal(
              onPressed: () => auth.signInWithGoogle(),
              child: const Text('Đăng nhập Google'),
            ),
          ],
        ),
      );
    }

    String roleName = 'Chủ sở hữu (Owner)';
    Color roleColor = Colors.teal;
    String roleDesc = 'Toàn quyền: Tạo, Chỉnh sửa, Chia sẻ và Xóa tài liệu';

    if (user.email.contains('viewer')) {
      roleName = 'Người xem (Viewer)';
      roleColor = Colors.blue;
      roleDesc = 'Quyền đọc: Chỉ xem tài liệu được chia sẻ, cấm sửa và xóa';
    } else if (user.email.contains('editor')) {
      roleName = 'Người sửa (Editor)';
      roleColor = Colors.purple;
      roleDesc = 'Quyền chỉnh sửa: Được phép sửa tài liệu, nhưng không được xóa';
    } else if (user.email.contains('stranger')) {
      roleName = 'Người lạ (Unauthorized)';
      roleColor = Colors.grey;
      roleDesc = 'Không có quyền: Không thể xem tài liệu riêng tư của người khác';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roleColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: roleColor,
            child: Text(
              user.displayName[0],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleName.split('(').first.trim(),
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  roleDesc,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => UserAccountHeader.showAccountSwitcherDialog(context),
            child: const Text('Đổi tài khoản', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
