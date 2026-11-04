import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/utils/file_helper.dart';
import '../models/category.dart';
import '../models/document.dart';
import '../providers/category_provider.dart';
import '../providers/document_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/subject_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/share_document_dialog.dart';
import '../widgets/stat_summary_card.dart';
import '../widgets/user_account_header.dart';
import 'add_edit_document_page.dart';
import 'document_detail_page.dart';
import 'document_list_page.dart';
import 'recycle_bin_page.dart';
import 'settings_page.dart';
import 'subject_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardView(),
    DocumentListPage(),
    SubjectPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Tài liệu',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Môn học',
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

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatisticsProvider>(context);
    final docProvider = Provider.of<DocumentProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final theme = Theme.of(context);

    final stats = statsProvider.stats;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.cloud_done_rounded, color: theme.colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('QLTLHT', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          const UserAccountHeader(compact: true),
          IconButton(
            icon: Badge(
              isLabelVisible: docProvider.recycleBinCount > 0,
              label: Text('${docProvider.recycleBinCount}'),
              child: const Icon(Icons.delete_sweep_outlined, size: 22),
            ),
            tooltip: 'Thùng rác (DeleteLogs)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (c) => const RecycleBinPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: 'Thêm tài liệu',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (c) => const AddEditDocumentPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await statsProvider.loadStatistics();
          await docProvider.loadDocuments();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cloud User & RBAC Status Banner
            const CloudUserBanner(),

            // Banner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kiến Trúc Local-First Cashew',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dữ liệu được lưu trữ trực tiếp trên thiết bị (SQLite), phản hồi tức thì với độ trễ bằng 0 và quản lý vết xóa bằng Tombstones.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (c) => const AddEditDocumentPage()),
                      );
                    },
                    child: const Text('Thêm tài liệu mới', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Grid (4 Metric Cards)
            const Text(
              'Thống kê tổng quan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.15,
              children: [
                StatSummaryCard(
                  title: 'Tổng tài liệu',
                  value: '${stats?.totalDocuments ?? 0}',
                  icon: Icons.description_rounded,
                  color: AppColors.presetColors[0],
                ),
                StatSummaryCard(
                  title: 'Môn học',
                  value: '${stats?.totalSubjects ?? 0}',
                  icon: Icons.school_rounded,
                  color: AppColors.presetColors[1],
                ),
                StatSummaryCard(
                  title: 'Dung lượng lưu trữ',
                  value: FileHelper.formatBytes(stats?.totalSizeBytes ?? 0),
                  icon: Icons.cloud_done_rounded,
                  color: AppColors.presetColors[6],
                ),
                StatSummaryCard(
                  title: 'Tiến độ học tập',
                  value: '${((stats?.completionRate ?? 0) * 100).toInt()}%',
                  subtitle: '${stats?.completedDocuments ?? 0}/${stats?.totalDocuments ?? 0} hoàn thành',
                  icon: Icons.verified_rounded,
                  color: AppColors.presetColors[7],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chart Section: Category Breakdown
            if (stats != null && stats.totalDocuments > 0) ...[
              _buildCategoryChartSection(context, stats, categoryProvider),
              const SizedBox(height: 24),
            ],

            // Recent Documents Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tài liệu cập nhật gần đây',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to documents list tab
                    final homeState = context.findAncestorStateOfType<_HomePageState>();
                    homeState?.setState(() {
                      homeState._currentIndex = 1;
                    });
                  },
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Recent Documents List
            if (docProvider.documents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Chưa có tài liệu nào')),
              )
            else
              ...docProvider.documents.take(4).map((doc) {
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
                  onDelete: () => docProvider.deleteDocument(doc.documentId),
                );
              }),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChartSection(
    BuildContext context,
    LearningStatistics stats,
    CategoryProvider categoryProvider,
  ) {
    final theme = Theme.of(context);
    final countByCategory = stats.countByCategory;

    final List<PieChartSectionData> sections = [];
    final List<Widget> legendWidgets = [];

    for (final Category cat in categoryProvider.categories) {
      final count = countByCategory[cat.categoryId] ?? 0;
      if (count > 0) {
        final color = Color(cat.color);
        final pct = (count / stats.totalDocuments * 100).toInt();

        sections.add(
          PieChartSectionData(
            value: count.toDouble(),
            title: '$pct%',
            color: color,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );

        legendWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cat.name,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$count tài liệu',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bổ tài liệu theo loại',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 24,
                    sectionsSpace: 2,
                  ),
                  duration: Duration.zero,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: legendWidgets,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
