import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';
import '../providers/settings_provider.dart';
import '../services/backup_service.dart';
import 'recycle_bin_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showBackupDialog(BuildContext context) async {
    final backupService = BackupService();
    try {
      final jsonSnapshot = await backupService.exportToJson();

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Bản sao lưu JSON (Cashew Snapshot)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dữ liệu toàn bộ môn học, danh mục, tài liệu và DeleteLogs đã được đóng gói thành công theo chuẩn snapshot của Cashew.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                height: 140,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    jsonSnapshot,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Sao chép JSON'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonSnapshot));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép bản sao lưu JSON vào bộ nhớ tạm'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi sao lưu: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRestoreDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Phục hồi dữ liệu từ JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dán chuỗi JSON bản sao lưu snapshot vào ô dưới đây để hợp nhất vào cơ sở dữ liệu SQLite.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                hintText: '{\n  "app": "Quản Lý Tài Liệu Học Tập", ...\n}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final jsonStr = textController.text.trim();
              if (jsonStr.isEmpty) return;

              final backupService = BackupService();
              try {
                final result = await backupService.importFromJson(jsonStr);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Phục hồi thành công: ${result['documents']} tài liệu, ${result['subjects']} môn học.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi cú pháp JSON: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Phục hồi'),
          ),
        ],
      ),
    );
  }

  void _showSqlSchemaDialog(BuildContext context) {
    const sqlSchema = '''-- SUPABASE DDL & ROW LEVEL SECURITY (RLS) POLICIES
-- File: supabase_schema_rls.sql
-- Áp dụng cho: users, documents, document_permissions

CREATE TABLE IF NOT EXISTS public.users (
    id VARCHAR(128) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.documents (
    id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(50) DEFAULT 'PDF',
    file_url TEXT,
    storage_path TEXT,
    file_size BIGINT DEFAULT 0,
    owner_id VARCHAR(128) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.document_permissions (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    user_id VARCHAR(128) NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_email VARCHAR(255) NOT NULL,
    permission_level VARCHAR(20) NOT NULL CHECK (permission_level IN ('view', 'edit', 'admin')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_permissions ENABLE ROW LEVEL SECURITY;

-- Policy SELECT Documents: Chủ sở hữu HOẶC người được cấp quyền
CREATE POLICY "Xem tài liệu của mình hoặc được chia sẻ"
    ON public.documents FOR SELECT
    USING (
        owner_id = auth.uid()::text
        OR EXISTS (
            SELECT 1 FROM public.document_permissions dp
            WHERE dp.document_id = public.documents.id
            AND dp.user_id = auth.uid()::text
        )
    );

-- Policy UPDATE Documents: Chủ sở hữu HOẶC quyền 'edit' / 'admin'
CREATE POLICY "Sửa tài liệu bởi chủ sở hữu hoặc editor"
    ON public.documents FOR UPDATE
    USING (
        owner_id = auth.uid()::text
        OR EXISTS (
            SELECT 1 FROM public.document_permissions dp
            WHERE dp.document_id = public.documents.id
            AND dp.user_id = auth.uid()::text
            AND dp.permission_level IN ('edit', 'admin')
        )
    );

-- Policy DELETE Documents: CHỈ DUY NHẤT Chủ sở hữu
CREATE POLICY "Chỉ chủ sở hữu được xóa tài liệu"
    ON public.documents FOR DELETE
    USING (owner_id = auth.uid()::text);''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mã SQL Supabase & RLS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sao chép đoạn mã SQL dưới đây và thực thi trong Supabase SQL Editor để khởi tạo bảng và chính sách bảo mật Row Level Security:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Container(
              height: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const SingleChildScrollView(
                child: SelectableText(
                  sqlSchema,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Sao chép SQL'),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: sqlSchema));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép mã SQL vào bộ nhớ tạm'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    final theme = Theme.of(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Cloud & Firebase/Supabase
          _buildSectionHeader('HỆ THỐNG CLOUD (FIREBASE & SUPABASE)'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(Icons.cloud_sync_rounded, color: Colors.orange),
                  ),
                  title: const Text('Xác thực Firebase Auth (Google Sign-In)'),
                  subtitle: Text(
                    user != null
                        ? 'Đang đăng nhập: ${user.displayName} (${user.email})'
                        : 'Chưa đăng nhập Google',
                  ),
                  trailing: user != null
                      ? OutlinedButton(
                          onPressed: () => auth.signOut(),
                          child: const Text('Đăng xuất'),
                        )
                      : FilledButton.tonal(
                          onPressed: () => auth.signInWithGoogle(),
                          child: const Text('Đăng nhập Google'),
                        ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.switch_account_rounded, color: Colors.indigo),
                  title: const Text('Tài khoản kiểm thử phân quyền (Checklist 6)'),
                  subtitle: Text('Hiện tại: ${user?.displayName ?? "Chưa chọn"}'),
                  trailing: DropdownButton<int>(
                    value: auth.currentAccountIndex,
                    underline: const SizedBox(),
                    items: auth.testAccounts.asMap().entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(
                          entry.value.displayName.split(' ').first,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (idx) {
                      if (idx != null) {
                        auth.switchTestAccountByIndex(idx);
                        docProvider.setCurrentUserId(auth.testAccounts[idx].id);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: Colors.green),
                  title: const Text('Chính sách Row Level Security (RLS)'),
                  subtitle: const Text('Xem mã SQL DDL và Policies bảo mật trên Supabase'),
                  trailing: const Icon(Icons.code_rounded),
                  onTap: () => _showSqlSchemaDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.link_rounded, color: Colors.blue),
                  title: const Text('Cấu hình Supabase Project URL'),
                  subtitle: Text(
                    SupabaseConfig.supabaseUrl,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Giao diện
          _buildSectionHeader('GIAO DIỆN & MÀU SẮC'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_rounded),
                  title: const Text('Chế độ giao diện'),
                  subtitle: Text(_getThemeModeName(settings.themeMode)),
                  trailing: DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('Theo hệ thống')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Sáng')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Tối')),
                    ],
                    onChanged: (mode) {
                      if (mode != null) settings.setThemeMode(mode);
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Màu sắc chủ đạo (Accent Color)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: AppColors.presetColors.map((color) {
                          final isSelected = settings.accentColor.value == color.value;
                          return InkWell(
                            onTap: () => settings.setAccentColor(color),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Dữ liệu & Lưu trữ (Cashew Local-First)
          _buildSectionHeader('LƯU TRỮ & SAO LƯU (LOCAL-FIRST)'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                  title: const Text('Sao lưu dữ liệu (Snapshot Export)'),
                  subtitle: const Text('Xuất toàn bộ cơ sở dữ liệu ra định dạng JSON'),
                  onTap: () => _showBackupDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: Colors.teal),
                  title: const Text('Phục hồi dữ liệu (Snapshot Import)'),
                  subtitle: const Text('Nạp lại dữ liệu từ tệp snapshot vào SQLite'),
                  onTap: () => _showRestoreDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded, color: Colors.orange),
                  title: const Text('Thùng rác & Lịch sử xóa'),
                  subtitle: const Text('Quản lý bảng DeleteLogs (Tombstones) và khôi phục'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (c) => const RecycleBinPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Thông tin kiến trúc
          _buildSectionHeader('THÔNG TIN KIẾN TRÚC HYBRID CLOUD & CASHEW'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.cloud_done_rounded, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppConstants.appName} Cloud Edition',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'Flutter • Firebase Auth & Storage • Supabase PostgreSQL (RLS)',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Hệ thống kết hợp mô hình Local-First hiệu năng cao của Cashew với hệ sinh thái Cloud hiện đại: Xác thực Google qua Firebase Authentication, lưu trữ tệp vật lý trên Firebase Storage và quản trị phân quyền đa người dùng bằng Row Level Security (RLS) trên Supabase.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
      case ThemeMode.system:
      default:
        return 'Theo hệ thống';
    }
  }
}
