import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục dữ liệu mẫu'),
        content: const Text(
          'Thao tác này sẽ đặt lại tất cả thói quen và lịch sử hoàn thành về dữ liệu mẫu mặc định ban đầu. Bạn có chắc chắn không?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<HabitProvider>(context, listen: false).resetAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã khôi phục dữ liệu mẫu thành công!')),
                );
              }
            },
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt & Thông tin'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Triết lý Kỷ luật cá nhân
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.tertiaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Sức mạnh của Kỷ luật',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"Chúng ta là những gì chúng ta lặp đi lặp lại. Do đó, sự xuất sắc không phải là một hành động mà là một thói quen." — Will Durant',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nhóm Quản lý dữ liệu
          Text(
            'Dữ liệu & Cấu hình',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.restore_page_rounded, color: Colors.orange),
                  title: const Text('Khôi phục dữ liệu mẫu'),
                  subtitle: const Text('Tải lại các thói quen tiêu chuẩn & dữ liệu ban đầu'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nhóm Thông tin ứng dụng
          Text(
            'Về ứng dụng',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.verified_rounded, color: Colors.blue),
                  title: Text('Ứng dụng Kỷ Luật Cá Nhân (Habit Tracker)'),
                  subtitle: Text('Phiên bản 1.0.0 • Flutter'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.storage_rounded, color: Colors.teal),
                  title: Text('Lưu trữ cục bộ SQLite'),
                  subtitle: Text('Dữ liệu được lưu an toàn trên máy, không bị mất khi thoát'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Colors.purple),
                  title: const Text('Mục tiêu học tập'),
                  subtitle: const Text('UI/UX, State Management (Provider), SQLite Database, fl_chart'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
