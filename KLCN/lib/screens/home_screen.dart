import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/date_strip_picker.dart';
import '../widgets/habit_card.dart';
import '../widgets/progress_card.dart';
import 'habit_form_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavigationIndex = 0;

  final List<Widget> _screens = const [
    _HabitListTab(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentNavigationIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavigationIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentNavigationIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: 'Thói quen',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Thống kê',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

class _HabitListTab extends StatelessWidget {
  const _HabitListTab();

  void _openAddHabit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HabitFormScreen()),
    );
  }

  void _openEditHabit(BuildContext context, Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HabitFormScreen(habit: habit)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<HabitProvider>(context);

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final habits = provider.habitsForSelectedDate;
    final completedCount = provider.completedHabitsCountForSelectedDate;
    final totalCount = provider.totalHabitsForSelectedDate;
    final rate = provider.completionRateForSelectedDate;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kỷ Luật Cá Nhân',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              DateFormat('EEEE, dd/MM', 'vi').format(provider.selectedDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Thêm thói quen mới',
            onPressed: () => _openAddHabit(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddHabit(context),
        icon: const Icon(Icons.add),
        label: const Text('Thói quen mới'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.init();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            // 1. Dải chọn ngày ngang
            DateStripPicker(
              selectedDate: provider.selectedDate,
              onDateSelected: (date) {
                provider.setSelectedDate(date);
              },
            ),

            // 2. Thẻ hiển thị tiến độ ngày đang chọn
            ProgressCard(
              completed: completedCount,
              total: totalCount,
              percentage: rate,
            ),

            // 3. Thanh bộ lọc
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    label: 'Tất cả ($totalCount)',
                    filter: HabitFilter.all,
                    currentFilter: provider.filter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Chưa xong (${totalCount - completedCount})',
                    filter: HabitFilter.pending,
                    currentFilter: provider.filter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Đã xong ($completedCount)',
                    filter: HabitFilter.completed,
                    currentFilter: provider.filter,
                  ),
                ],
              ),
            ),

            // 4. Danh sách thói quen
            if (habits.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.self_improvement_rounded,
                        size: 72,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có thói quen nào phù hợp',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.habits.isEmpty
                            ? 'Bạn chưa tạo thói quen nào. Hãy nhấn nút bên dưới để thêm!'
                            : 'Không có thói quen nào trong bộ lọc này cho ngày hôm nay.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openAddHabit(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm thói quen ngay'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...habits.map((habit) {
                final isDone = provider.isCompleted(habit.id);
                final streak = provider.getStreak(habit.id);
                return HabitCard(
                  habit: habit,
                  isCompleted: isDone,
                  streak: streak,
                  onToggle: () {
                    if (habit.id != null) {
                      provider.toggleHabitCompletion(habit.id!);
                    }
                  },
                  onEdit: () => _openEditHabit(context, habit),
                  onDelete: () {
                    if (habit.id != null) {
                      _confirmDeleteHabit(context, provider, habit);
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required HabitFilter filter,
    required HabitFilter currentFilter,
  }) {
    final isSelected = filter == currentFilter;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        Provider.of<HabitProvider>(context, listen: false).setFilter(filter);
      },
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  void _confirmDeleteHabit(
    BuildContext context,
    HabitProvider provider,
    Habit habit,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${habit.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteHabit(habit.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa thói quen!')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
