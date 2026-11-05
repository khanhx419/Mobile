import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateStripPicker extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const DateStripPicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<DateStripPicker> createState() => _DateStripPickerState();
}

class _DateStripPickerState extends State<DateStripPicker> {
  late final ScrollController _scrollController;
  final int _pastDays = 14;
  final int _futureDays = 3;
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = List.generate(
      _pastDays + _futureDays + 1,
      (index) => today.subtract(Duration(days: _pastDays - index)),
    );

    // Tính toán vị trí cuộn tới ngày hôm nay
    final initialIndex = _pastDays;
    _scrollController = ScrollController(
      initialScrollOffset: (initialIndex * 66.0) - 120.0,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getWeekdayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'vi').format(widget.selectedDate).toUpperCase(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (!_isSameDay(widget.selectedDate, today))
                TextButton.icon(
                  onPressed: () {
                    widget.onDateSelected(DateTime.now());
                  },
                  icon: const Icon(Icons.today, size: 16),
                  label: const Text('Hôm nay'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 84,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: _dates.length,
            itemBuilder: (context, index) {
              final date = _dates[index];
              final isSelected = _isSameDay(date, widget.selectedDate);
              final isToday = _isSameDay(date, today);

              return GestureDetector(
                onTap: () => widget.onDateSelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 58,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isToday
                            ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                            : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isToday
                              ? theme.colorScheme.primary.withOpacity(0.5)
                              : theme.colorScheme.outlineVariant.withOpacity(0.5),
                      width: isToday && !isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getWeekdayName(date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday
                              ? (isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
