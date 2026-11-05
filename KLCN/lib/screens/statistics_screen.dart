import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTabIndex = 0; // 0: Ngày, 1: Tuần, 2: Tháng
  bool _isLoading = false;

  List<DailyStat> _weeklyStats = [];
  Map<String, dynamic> _monthlyStats = {};
  List<HabitPerformance> _performances = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<HabitProvider>(context, listen: false);

    final weekly = await provider.getWeeklyStats();
    final monthly = await provider.getMonthlyStats();
    final perf = await provider.getHabitPerformances();

    if (mounted) {
      setState(() {
        _weeklyStats = weekly;
        _monthlyStats = monthly;
        _performances = perf;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<HabitProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê kỷ luật'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới thống kê',
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tab lựa chọn Ngày / Tuần / Tháng
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTabButton(0, 'Hôm nay'),
                        _buildTabButton(1, 'Theo Tuần'),
                        _buildTabButton(2, 'Theo Tháng'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nội dung tương ứng với Tab
                  if (_selectedTabIndex == 0)
                    _buildDailySection(context, provider)
                  else if (_selectedTabIndex == 1)
                    _buildWeeklySection(context, provider)
                  else
                    _buildMonthlySection(context, provider),

                  const SizedBox(height: 24),

                  // Bảng xếp hạng hiệu suất từng thói quen
                  _buildHabitPerformanceSection(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Thống kê Ngày
  Widget _buildDailySection(BuildContext context, HabitProvider provider) {
    final theme = Theme.of(context);
    final rate = provider.completionRateForSelectedDate;
    final completed = provider.completedHabitsCountForSelectedDate;
    final total = provider.totalHabitsForSelectedDate;
    final remaining = (total - completed).clamp(0, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiến độ ngày ${DateFormat('dd/MM/yyyy').format(provider.selectedDate)}',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Tỷ lệ hoàn thành',
                value: '${(rate * 100).toInt()}%',
                icon: Icons.pie_chart_rounded,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Đã hoàn thành',
                value: '$completed / $total',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Còn lại',
                value: '$remaining thói quen',
                icon: Icons.pending_actions_rounded,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Tổng số mục tiêu',
                value: '$total',
                icon: Icons.flag_rounded,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Thống kê Tuần (Có biểu đồ cột fl_chart)
  Widget _buildWeeklySection(BuildContext context, HabitProvider provider) {
    final theme = Theme.of(context);

    // Tính tỷ lệ trung bình trong tuần
    double totalRate = 0;
    int totalCompleted = 0;
    for (var s in _weeklyStats) {
      totalRate += s.rate;
      totalCompleted += s.completedCount;
    }
    final avgRate = _weeklyStats.isNotEmpty ? (totalRate / _weeklyStats.length) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Biểu đồ 7 ngày gần nhất',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'TB: ${(avgRate * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Biểu đồ FlChart Bar
        Container(
          height: 220,
          padding: const EdgeInsets.only(top: 20, right: 16, left: 0, bottom: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: _weeklyStats.isEmpty
              ? const Center(child: Text('Chưa có dữ liệu tuần'))
              : BarChart(
                  BarChartData(
                    maxY: 100,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey.shade800,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final stat = _weeklyStats[group.x.toInt()];
                          return BarTooltipItem(
                            '${stat.dayName} (${stat.date.day}/${stat.date.month})\n${rod.toY.toInt()}% (${stat.completedCount}/${stat.totalCount})',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < _weeklyStats.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  _weeklyStats[idx].dayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == 50 || value == 100) {
                              return Text(
                                '${value.toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    barGroups: List.generate(_weeklyStats.length, (i) {
                      final stat = _weeklyStats[i];
                      final pct = stat.rate * 100;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: pct,
                            color: pct >= 80
                                ? Colors.green
                                : pct >= 50
                                    ? Colors.blue
                                    : Colors.orange,
                            width: 18,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 100,
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Tổng lượt hoàn thành',
                value: '$totalCompleted',
                icon: Icons.done_all_rounded,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Tỷ lệ trung bình',
                value: '${(avgRate * 100).toInt()}%',
                icon: Icons.trending_up_rounded,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Thống kê Tháng
  Widget _buildMonthlySection(BuildContext context, HabitProvider provider) {
    final theme = Theme.of(context);
    final month = _monthlyStats['month'] ?? DateTime.now().month;
    final year = _monthlyStats['year'] ?? DateTime.now().year;
    final monthlyRate = (_monthlyStats['monthlyRate'] as double? ?? 0.0);
    final totalCompleted = _monthlyStats['totalCompleted'] ?? 0;
    final totalExpected = _monthlyStats['totalExpected'] ?? 0;
    final daysCalculated = _monthlyStats['totalDaysCalculated'] ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng kết Tháng $month/$year',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Tỷ lệ hoàn thành',
                value: '${(monthlyRate * 100).toInt()}%',
                icon: Icons.calendar_month_rounded,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Lượt hoàn thành',
                value: '$totalCompleted / $totalExpected',
                icon: Icons.task_alt_rounded,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mức độ kỷ luật trong tháng',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: monthlyRate,
                  minHeight: 12,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    monthlyRate >= 0.8
                        ? Colors.green
                        : monthlyRate >= 0.5
                            ? Colors.blue
                            : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tính trên $daysCalculated ngày đã qua trong tháng này. Tiếp tục duy trì đều đặn để xây dựng kỷ luật thép!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Danh sách chi tiết hiệu suất từng thói quen
  Widget _buildHabitPerformanceSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hiệu suất từng thói quen (30 ngày)',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_performances.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('Chưa có dữ liệu thói quen')),
          )
        else
          ..._performances.map((p) {
            final pct = (p.completionRate * 100).toInt();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.habit.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(p.habit.icon, color: p.habit.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.habit.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: p.completionRate,
                                  minHeight: 6,
                                  backgroundColor: theme.colorScheme.surfaceVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(p.habit.color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: p.habit.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${p.completedDays}/${p.targetDays} ngày hoàn thành',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p.streak > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '🔥 ${p.streak}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
