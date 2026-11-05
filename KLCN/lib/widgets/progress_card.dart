import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  final int completed;
  final int total;
  final double percentage;

  const ProgressCard({
    super.key,
    required this.completed,
    required this.total,
    required this.percentage,
  });

  String _getMotivationalQuote(double pct) {
    if (total == 0) return 'Hãy thêm thói quen mới để bắt đầu rèn luyện!';
    if (pct == 1.0) return 'Xuất sắc! Bạn đã hoàn thành 100% mục tiêu hôm nay! 🎉';
    if (pct >= 0.7) return 'Rất tuyệt vời! Chỉ còn một chút nữa là hoàn thành!';
    if (pct >= 0.4) return 'Đang đi đúng hướng, kiên trì giữ vững kỷ luật nhé!';
    if (pct > 0.0) return 'Khởi đầu tốt! Hãy tiếp tục hoàn thành các mục tiêu còn lại.';
    return 'Kỷ luật là cầu nối giữa mục tiêu và thành tựu. Hãy bắt đầu ngay!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentInt = (percentage * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tiến độ hôm nay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completed / $total Thói quen',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getMotivationalQuote(percentage),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Vòng tròn tỷ lệ % hoàn thành
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '$percentInt%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
