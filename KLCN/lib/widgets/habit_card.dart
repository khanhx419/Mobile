import 'package:flutter/material.dart';
import '../models/habit.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.streak,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatFrequency(Habit h) {
    if (h.frequencyType == 'daily' || h.selectedDays.length == 7) {
      return 'Hàng ngày';
    }
    final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final selectedNames = h.selectedDays.map((d) => d == 7 ? 'CN' : 'T${d + 1}').join(', ');
    return selectedNames;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitColor = habit.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? habitColor.withOpacity(0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? habitColor.withOpacity(0.4)
              : theme.colorScheme.outlineVariant.withOpacity(0.4),
          width: isCompleted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Icon thói quen
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: habitColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    habit.icon,
                    color: habitColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),

                // Thông tin thói quen
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              habit.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: isCompleted
                                    ? theme.colorScheme.onSurface.withOpacity(0.6)
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (streak > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$streak',
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          habit.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            habit.reminderTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.repeat_rounded,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatFrequency(habit),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Nút Đánh dấu hoàn thành
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? habitColor : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? habitColor
                            : theme.colorScheme.outlineVariant,
                        width: 2,
                      ),
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: habitColor.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: isCompleted ? 1.0 : 0.0,
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),

                // Menu sửa / xóa
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 10),
                          Text('Xóa thói quen', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
