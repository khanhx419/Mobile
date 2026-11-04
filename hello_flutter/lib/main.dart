import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyPortfolioApp());
}

// =============================================================================
// 1. DATA MODEL & DỮ LIỆU PORTFOLIO
// =============================================================================

class PortfolioData {
  static const String appName = 'My Portfolio';
  static const String name = 'Lê Tuấn Khanh';
  static const String title = 'Android Mobile Developer';
  static const String bio =
      'Là sinh viên Đại học Thủy Lợi, có niềm đam mê và yêu thích lập trình ứng dụng di động & các giải pháp công nghệ hiện đại.';
  static const String university = 'Trường Đại học Thủy Lợi (TLU)';
  static const String major = 'Công nghệ Thông tin';
  static const String location = 'Hà Nội, Việt Nam';
  static const String connectHeader = 'Kết nối với tôi';

  // URLs & Thông tin liên hệ
  static const String githubUrl = 'https://github.com/khanhx419';
  static const String linkedinUrl =
      'https://www.linkedin.com/in/l%C3%AA-tu%E1%BA%A5n-khanh-063a39391/';
  static const String facebookUrl =
      'https://www.facebook.com/khanh.letuan.7528';
  static const String email = 'khanhx419@gmail.com';
  static const String emailSubject = 'Liên hệ hợp tác từ Portfolio App';
  static const String phoneNumber = '036455xxxx';

  // Tên nút liên hệ (giữ nguyên theo app Android)
  static const String btnGithub = 'GitHub Profile';
  static const String btnLinkedin = 'LinkedIn Profile';
  static const String btnFacebook = 'Facebook Cá Nhân';
  static const String btnEmail = 'Gửi Email Liên Hệ';
  static const String btnPhone = 'Gọi Điện Thoại';
}

// Tương thích ngược cho các test
typedef BusinessCardConfig = PortfolioData;
typedef MyApp = MyPortfolioApp;

/// Bảng màu chuẩn từ file colors.xml của ứng dụng Android
class PortfolioColors {
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFFBBDEFB);
  static const Color accent = Color(0xFF00BCD4);
  static const Color bgScreen = Color(0xFFF5F7FB);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color divider = Color(0xFFE2E8F0);

  // Brand button colors
  static const Color github = Color(0xFF24292F);
  static const Color linkedin = Color(0xFF0A66C2);
  static const Color facebook = Color(0xFF1877F2);
  static const Color email = Color(0xFFEA4335);
  static const Color phone = Color(0xFF10B981);
}

// =============================================================================
// 2. ROOT WIDGET
// =============================================================================

class MyPortfolioApp extends StatelessWidget {
  const MyPortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${PortfolioData.name} - ${PortfolioData.appName}',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: PortfolioColors.primary,
          primary: PortfolioColors.primary,
          surface: PortfolioColors.cardSurface,
        ),
        scaffoldBackgroundColor: PortfolioColors.bgScreen,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// =============================================================================
// 3. MAIN NAVIGATION SCREEN (RESPONSIVE CHUẨN WEB & MOBILE)
// =============================================================================

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<String> _tabTitles = [
    'Trang chủ',
    'Kỹ năng',
    'Kinh nghiệm',
    'Dự án',
    'Liên hệ',
  ];

  final List<IconData> _tabIcons = [
    Icons.person_rounded,
    Icons.code_rounded,
    Icons.work_history_rounded,
    Icons.layers_rounded,
    Icons.contact_mail_rounded,
  ];

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 820;

        return Scaffold(
          backgroundColor: PortfolioColors.bgScreen,
          appBar: isDesktop ? _buildDesktopHeader() : _buildMobileHeader(),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildPageContent(_currentIndex),
              ),
            ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _navigateToTab,
                  backgroundColor: Colors.white,
                  indicatorColor: PortfolioColors.primary.withValues(alpha: 0.15),
                  destinations: List.generate(_tabTitles.length, (index) {
                    return NavigationDestination(
                      icon: Icon(_tabIcons[index]),
                      selectedIcon: Icon(
                        _tabIcons[index],
                        color: PortfolioColors.primary,
                      ),
                      label: _tabTitles[index],
                    );
                  }),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildMobileHeader() {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.stars_rounded, color: PortfolioColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            _tabTitles[_currentIndex],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: PortfolioColors.textPrimary,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: false,
    );
  }

  PreferredSizeWidget _buildDesktopHeader() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: PortfolioColors.divider, width: 1),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Logo / Tên thương hiệu
                  GestureDetector(
                    onTap: () => _navigateToTab(0),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: PortfolioColors.primary,
                          child: Text(
                            'K',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          PortfolioData.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: PortfolioColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Các nút điều hướng tab
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_tabTitles.length, (index) {
                            final bool isSelected = _currentIndex == index;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TextButton.icon(
                                onPressed: () => _navigateToTab(index),
                                icon: Icon(
                                  _tabIcons[index],
                                  size: 17,
                                  color: isSelected
                                      ? PortfolioColors.primary
                                      : PortfolioColors.textSecondary,
                                ),
                                label: Text(
                                  _tabTitles[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? PortfolioColors.primary
                                        : PortfolioColors.textSecondary,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? PortfolioColors.primary
                                          .withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return HomeScreen(onNavigateToTab: _navigateToTab);
      case 1:
        return const SkillsScreen();
      case 2:
        return const ExperienceScreen();
      case 3:
        return const ProjectsScreen();
      case 4:
        return const ContactScreen();
      default:
        return HomeScreen(onNavigateToTab: _navigateToTab);
    }
  }
}

// =============================================================================
// 4. CHECKLIST MỤC 1: TRANG CHỦ (Ảnh đại diện, tên & lời giới thiệu ngắn gọn)
// =============================================================================

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onNavigateToTab;

  const HomeScreen({super.key, required this.onNavigateToTab});

  void _showGreeting(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Xin chào! Cảm ơn bạn đã ghé thăm Portfolio của tôi!',
          style: TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Khối thẻ thông tin chính
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: PortfolioColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Ảnh đại diện bo tròn viền xanh 130dp chuẩn theo app Android
                GestureDetector(
                  onTap: () => _showGreeting(context),
                  child: Tooltip(
                    message: 'Nhấn để chào!',
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: PortfolioColors.primary,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: PortfolioColors.primary
                                .withValues(alpha: 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/avatar_user.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: PortfolioColors.primary,
                              child: const Center(
                                child: Text(
                                  'K',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Họ và tên
                const Text(
                  PortfolioData.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: PortfolioColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Chức danh nghề nghiệp
                const Text(
                  PortfolioData.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: PortfolioColors.primary,
                  ),
                ),
                const SizedBox(height: 14),

                // Lời giới thiệu ngắn gọn (Bio)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: const Text(
                    PortfolioData.bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: PortfolioColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Các nút kêu gọi hành động nhanh
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => onNavigateToTab(3), // Sang Dự án
                      icon: const Icon(Icons.layers_outlined, size: 18),
                      label: const Text('Xem Dự Án'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PortfolioColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => onNavigateToTab(4), // Sang Liên hệ
                      icon: const Icon(Icons.mail_outline_rounded, size: 18),
                      label: const Text('Liên Hệ Ngay'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PortfolioColors.primary,
                        side: const BorderSide(color: PortfolioColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Lưới thông tin nổi bật nhanh
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 600;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 4 : 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: isWide ? 1.6 : 1.35,
                children: const [
                  _HighlightCard(
                    icon: Icons.school_rounded,
                    title: 'Học vấn',
                    subtitle: 'Đại học Thủy Lợi',
                    color: Color(0xFF1976D2),
                  ),
                  _HighlightCard(
                    icon: Icons.phone_android_rounded,
                    title: 'Chuyên môn',
                    subtitle: 'Android & Flutter',
                    color: Color(0xFF00BCD4),
                  ),
                  _HighlightCard(
                    icon: Icons.location_on_rounded,
                    title: 'Khu vực',
                    subtitle: 'Hà Nội, VN',
                    color: Color(0xFF10B981),
                  ),
                  _HighlightCard(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Trạng thái',
                    subtitle: 'Sẵn sàng làm việc',
                    color: Color(0xFF8B5CF6),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _HighlightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PortfolioColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: PortfolioColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: PortfolioColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. CHECKLIST MỤC 2 (PHẦN A): KỸ NĂNG (SKILLS)
// =============================================================================

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kỹ Năng Chuyên Môn',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: PortfolioColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Các công nghệ, ngôn ngữ và công cụ phát triển ứng dụng di động & phần mềm.',
            style: TextStyle(
              fontSize: 14,
              color: PortfolioColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Danh sách kỹ năng phân loại
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 650;

              return Column(
                children: [
                  if (isWide)
                    const Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SkillGroupCard(
                                title: 'Lập Trình Mobile & Web',
                                icon: Icons.phone_iphone_rounded,
                                iconColor: PortfolioColors.primary,
                                skills: [
                                  _SkillItem(name: 'Flutter & Dart (Web, Mobile)', progress: 0.90),
                                  _SkillItem(name: 'Kotlin & Android SDK (Jetpack, XML)', progress: 0.88),
                                  _SkillItem(name: 'React, TypeScript & Node.js', progress: 0.82),
                                  _SkillItem(name: 'Kiến trúc MVVM & Clean Architecture', progress: 0.85),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _SkillGroupCard(
                                title: 'AI, Computer Vision & RPA',
                                icon: Icons.psychology_rounded,
                                iconColor: Color(0xFF00BCD4),
                                skills: [
                                  _SkillItem(name: 'Python (PyTorch, YOLOv8 mAP 91%)', progress: 0.85),
                                  _SkillItem(name: 'OpenCV & Tesseract OCR Image Matching', progress: 0.82),
                                  _SkillItem(name: 'Tự động hóa RPA & Multi-instance ADB', progress: 0.84),
                                  _SkillItem(name: 'Thuật toán đồ thị DAG (PERT/CPM WBS)', progress: 0.80),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _SkillGroupCard(
                                title: 'Ngôn Ngữ & Cơ Sở Dữ Liệu',
                                icon: Icons.terminal_rounded,
                                iconColor: Color(0xFF10B981),
                                skills: [
                                  _SkillItem(name: 'Dart & JavaScript / TypeScript', progress: 0.88),
                                  _SkillItem(name: 'Kotlin & Java', progress: 0.86),
                                  _SkillItem(name: 'Python & PHP', progress: 0.84),
                                  _SkillItem(name: 'SQL, MySQL, Room Database, SQLite', progress: 0.82),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _SkillGroupCard(
                                title: 'Công Cụ & Công Nghệ Thời Gian Thực',
                                icon: Icons.build_circle_rounded,
                                iconColor: Color(0xFF8B5CF6),
                                skills: [
                                  _SkillItem(name: 'Git & GitHub Version Control', progress: 0.90),
                                  _SkillItem(name: 'Socket.io & Web Audio API (Realtime)', progress: 0.82),
                                  _SkillItem(name: 'Android Studio, VS Code, Postman', progress: 0.92),
                                  _SkillItem(name: 'WebAssembly & Canvas Emulation', progress: 0.80),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else ...[
                    const _SkillGroupCard(
                      title: 'Lập Trình Mobile & Web',
                      icon: Icons.phone_iphone_rounded,
                      iconColor: PortfolioColors.primary,
                      skills: [
                        _SkillItem(name: 'Flutter & Dart (Web, Mobile)', progress: 0.90),
                        _SkillItem(name: 'Kotlin & Android SDK (Jetpack, XML)', progress: 0.88),
                        _SkillItem(name: 'React, TypeScript & Node.js', progress: 0.82),
                        _SkillItem(name: 'Kiến trúc MVVM & Clean Architecture', progress: 0.85),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _SkillGroupCard(
                      title: 'AI, Computer Vision & RPA',
                      icon: Icons.psychology_rounded,
                      iconColor: Color(0xFF00BCD4),
                      skills: [
                        _SkillItem(name: 'Python (PyTorch, YOLOv8 mAP 91%)', progress: 0.85),
                        _SkillItem(name: 'OpenCV & Tesseract OCR Image Matching', progress: 0.82),
                        _SkillItem(name: 'Tự động hóa RPA & Multi-instance ADB', progress: 0.84),
                        _SkillItem(name: 'Thuật toán đồ thị DAG (PERT/CPM WBS)', progress: 0.80),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _SkillGroupCard(
                      title: 'Ngôn Ngữ & Cơ Sở Dữ Liệu',
                      icon: Icons.terminal_rounded,
                      iconColor: Color(0xFF10B981),
                      skills: [
                        _SkillItem(name: 'Dart & JavaScript / TypeScript', progress: 0.88),
                        _SkillItem(name: 'Kotlin & Java', progress: 0.86),
                        _SkillItem(name: 'Python & PHP', progress: 0.84),
                        _SkillItem(name: 'SQL, MySQL, Room Database, SQLite', progress: 0.82),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _SkillGroupCard(
                      title: 'Công Cụ & Công Nghệ Thời Gian Thực',
                      icon: Icons.build_circle_rounded,
                      iconColor: Color(0xFF8B5CF6),
                      skills: [
                        _SkillItem(name: 'Git & GitHub Version Control', progress: 0.90),
                        _SkillItem(name: 'Socket.io & Web Audio API (Realtime)', progress: 0.82),
                        _SkillItem(name: 'Android Studio, VS Code, Postman', progress: 0.92),
                        _SkillItem(name: 'WebAssembly & Canvas Emulation', progress: 0.80),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SkillGroupCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_SkillItem> skills;

  const _SkillGroupCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PortfolioColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PortfolioColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            children: skills.map((s) => _buildProgressRow(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(_SkillItem item) {
    final int percent = (item.progress * 100).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PortfolioColors.textPrimary,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: PortfolioColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 6,
              backgroundColor: PortfolioColors.bgScreen,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillItem {
  final String name;
  final double progress;

  const _SkillItem({required this.name, required this.progress});
}

// =============================================================================
// 6. CHECKLIST MỤC 2 (PHẦN B): KINH NGHIỆM (EXPERIENCE)
// =============================================================================

class ExperienceScreen extends StatelessWidget {
  const ExperienceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kinh Nghiệm & Học Vấn',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: PortfolioColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Quá trình học tập, rèn luyện kỹ năng và kinh nghiệm thực chiến dự án.',
            style: TextStyle(
              fontSize: 14,
              color: PortfolioColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Timeline các mốc thời gian
          const _TimelineCard(
            period: '2022 - Hiện tại',
            role: 'Sinh viên Công nghệ Thông tin',
            organization: 'Trường Đại học Thủy Lợi (TLU)',
            description:
                'Nghiên cứu cấu trúc dữ liệu và giải thuật, lập trình hướng đối tượng (OOP), cơ sở dữ liệu và phát triển ứng dụng di động. Tham gia các nhóm học tập và phát triển ứng dụng mã nguồn mở.',
            badges: ['GPA Giỏi', 'OOP & Cấu Trúc Dữ Liệu', 'Lập trình Mobile'],
            icon: Icons.school_rounded,
            accentColor: PortfolioColors.primary,
          ),
          const SizedBox(height: 16),
          const _TimelineCard(
            period: '2024 - 2025',
            role: 'Thực hành Phát triển Ứng dụng Android',
            organization: 'Dự án Học tập & Cá nhân',
            description:
                'Xây dựng các ứng dụng Android hoàn chỉnh từ giao diện (XML & Jetpack Compose), xử lý nền với Coroutines, lưu trữ offline bằng Room Database và tích hợp RESTful APIs theo kiến trúc MVVM.',
            badges: ['Kotlin', 'Jetpack Compose', 'Room DB', 'MVVM'],
            icon: Icons.android_rounded,
            accentColor: Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          const _TimelineCard(
            period: '2025 - Nay',
            role: 'Cross-platform Mobile & Web Developer',
            organization: 'Dự án Đa Nền Tảng',
            description:
                'Ứng dụng Flutter vào việc phát triển ứng dụng chạy mượt mà trên cả Web, Android và iOS. Tối ưu giao diện Responsive và hiệu năng đồ họa.',
            badges: ['Flutter', 'Dart', 'Web Responsive', 'Material 3'],
            icon: Icons.flutter_dash_rounded,
            accentColor: Color(0xFF00BCD4),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final String period;
  final String role;
  final String organization;
  final String description;
  final List<String> badges;
  final IconData icon;
  final Color accentColor;

  const _TimelineCard({
    required this.period,
    required this.role,
    required this.organization,
    required this.description,
    required this.badges,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PortfolioColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon mốc thời gian
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),

          // Nội dung chi tiết
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        role,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: PortfolioColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PortfolioColors.bgScreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  organization,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PortfolioColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: PortfolioColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: badges.map((badge) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PortfolioColors.bgScreen,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: PortfolioColors.divider),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 11,
                          color: PortfolioColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 7. CHECKLIST MỤC 2 (PHẦN C): DỰ ÁN ĐÃ LÀM (PROJECTS)
// =============================================================================

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Game & Giả lập',
    'Trí tuệ nhân tạo (AI)',
    'Tự động hóa (RPA)',
    'Mobile & Web',
  ];

  final List<_ProjectModel> _allProjects = const [
    _ProjectModel(
      title: 'GBA_emulator (GBA_K)',
      category: 'Game & Giả lập',
      description:
          'Trình giả lập Game Boy Advance hiện đại chạy mượt mà trên Web và Android (.apk). Tự động nhận diện SRAM/Flash ROM .gba, tua nhanh Fast-Forward 1.0x-5.0x, điều khiển Joystick tự do (Floating) & D-Pad, 6 slot Save/Load states preview ảnh, bộ lọc màn hình LCD SP / CRT scanlines và cheat code.',
      tags: ['JavaScript', 'WebAssembly', 'HTML5 Canvas', 'Android APK', 'Emulator'],
      githubUrl: 'https://github.com/khanhx419/GBA_emulator',
      icon: Icons.sports_esports_rounded,
      iconColor: Color(0xFF8B5CF6),
      highlight: 'Chạy ROM GBA mượt mà trên Web & đóng gói Android APK',
    ),
    _ProjectModel(
      title: 'smart_pms_ai',
      category: 'Trí tuệ nhân tạo (AI)',
      description:
          'Hệ thống quản lý dự án thông minh: tiếp nhận Use Case, dùng AI bóc tách Work Breakdown Structure (WBS), thuật toán ánh xạ ID 2 pha (Two-Phase ID Resolution), quy đổi sang Lịch làm việc thực tế (Working Calendar 8h/ngày), phân bổ nhân sự và tính toán đường găng PERT/CPM trên đồ thị DAG.',
      tags: ['PHP', 'AI Integration', 'PERT / CPM DAG', 'MySQL', 'Algorithm'],
      githubUrl: 'https://github.com/khanhx419/smart_pms_ai',
      icon: Icons.psychology_rounded,
      iconColor: PortfolioColors.primary,
      highlight: 'Bóc tách WBS bằng AI & Tính đường găng PERT/CPM',
    ),
    _ProjectModel(
      title: 'YOLOv8 Vehicle Detection',
      category: 'Trí tuệ nhân tạo (AI)',
      description:
          'Hệ thống phát hiện & đếm phương tiện giao thông (Xe máy, Ô tô, Xe tải) thời gian thực huấn luyện trên bộ dữ liệu giao thông Việt Nam. Tối ưu bộ nhớ trên GPU NVIDIA RTX, bộ lọc kiểm tra an toàn video, đạt độ chính xác mAP50 lên tới 91.1% sau 50 epochs.',
      tags: ['Python', 'YOLOv8', 'PyTorch', 'OpenCV', 'CUDA GPU'],
      githubUrl: 'https://github.com/khanhx419/YOLO_Learning',
      icon: Icons.visibility_rounded,
      iconColor: Color(0xFF00BCD4),
      highlight: 'Độ chính xác mAP50 đạt 91.1% trên tập dữ liệu Việt Nam',
    ),
    _ProjectModel(
      title: 'Barking_Game (Barking Battle)',
      category: 'Game & Giả lập',
      description:
          'Game đối kháng trực tiếp 2 người chơi qua giọng sủa vào micro thời gian thực! Cơ chế tính điểm kép (Âm lượng × Độ ngân dài), kéo co ranh giới Tug-of-War, phóng to/thu nhỏ 5 giống chó (Husky, Shiba, Bulldog, Corgi, Poodle), phòng chơi real-time qua Socket.io.',
      tags: ['React', 'Node.js', 'Socket.io', 'Web Audio API', 'Tailwind'],
      githubUrl: 'https://github.com/khanhx419/Barking_Game',
      icon: Icons.pets_rounded,
      iconColor: Color(0xFFEA4335),
      highlight: 'Voice battle multiplayer thời gian thực với Web Audio API',
    ),
    _ProjectModel(
      title: 'AOV_tools (Liên Quân RPA)',
      category: 'Tự động hóa (RPA)',
      description:
          'Công cụ tự động hóa RPA điều phối đa giả lập LDPlayer cho Liên Quân Mobile. Kiến trúc Master/Slave, nhận diện hình ảnh OpenCV Template Matching điều hướng UI, OCR Tesseract trích xuất Room ID, đồng bộ hóa đa luồng an toàn.',
      tags: ['Python', 'OpenCV', 'Tesseract OCR', 'RPA', 'LDPlayer ADB'],
      githubUrl: 'https://github.com/khanhx419/AOV_tools',
      icon: Icons.smart_toy_rounded,
      iconColor: Color(0xFF10B981),
      highlight: 'Tự động hóa đa giả lập Master/Slave với OpenCV & OCR',
    ),
    _ProjectModel(
      title: 'break_pixel (Pixel Game)',
      category: 'Mobile & Web',
      description:
          'Dự án game đồ họa Pixel 2D phát triển trên nền tảng Flutter & Dart. Tối ưu vòng lặp game loop, render sprite tương tác mượt mà trên đa thiết bị màn hình cảm ứng.',
      tags: ['Flutter', 'Dart', 'Game Engine', 'Pixel Art', 'Canvas'],
      githubUrl: 'https://github.com/khanhx419/break_pixel',
      icon: Icons.grid_4x4_rounded,
      iconColor: Color(0xFFF59E0B),
      highlight: 'Game đồ họa Pixel tương tác xây dựng bằng Flutter',
    ),
    _ProjectModel(
      title: 'Portfolio Mobile & Web App',
      category: 'Mobile & Web',
      description:
          'Ứng dụng hồ sơ năng lực cá nhân đa nền tảng. Xây dựng phiên bản Native Android với Kotlin, Jetpack Compose, Material 3 và phiên bản Web với Flutter Dart, hỗ trợ hiển thị linh hoạt trên mọi kích thước màn hình.',
      tags: ['Flutter Web', 'Kotlin', 'Jetpack Compose', 'Responsive UI'],
      githubUrl: 'https://github.com/khanhx419/Portfolio-Website',
      icon: Icons.portrait_rounded,
      iconColor: PortfolioColors.primary,
      highlight: 'Đồng bộ chuẩn thiết kế Android Native & Flutter Web',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final List<_ProjectModel> filteredProjects = _selectedCategory == 'Tất cả'
        ? _allProjects
        : _allProjects
            .where((p) => p.category == _selectedCategory)
            .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dự Án Đã Thực Hiện',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: PortfolioColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Các dự án thực tế trên GitHub (@khanhx419) từ Game, AI, RPA đến Mobile & Web.',
                      style: TextStyle(
                        fontSize: 14,
                        color: PortfolioColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: PortfolioColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_allProjects.length} Dự án',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: PortfolioColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bộ lọc danh mục (Filter Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final bool isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    selectedColor: PortfolioColors.primary.withValues(alpha: 0.15),
                    checkmarkColor: PortfolioColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? PortfolioColors.primary
                          : PortfolioColors.textSecondary,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? PortfolioColors.primary
                          : PortfolioColors.divider,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Lưới dự án
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 720;

              if (isWide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 330,
                  ),
                  itemCount: filteredProjects.length,
                  itemBuilder: (context, index) {
                    return _ProjectCard(project: filteredProjects[index]);
                  },
                );
              } else {
                return Column(
                  children: filteredProjects.map((p) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ProjectCard(project: p),
                    );
                  }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ProjectModel {
  final String title;
  final String category;
  final String description;
  final List<String> tags;
  final String githubUrl;
  final IconData icon;
  final Color iconColor;
  final String highlight;

  const _ProjectModel({
    required this.title,
    required this.category,
    required this.description,
    required this.tags,
    required this.githubUrl,
    required this.icon,
    required this.iconColor,
    required this.highlight,
  });
}

class _ProjectCard extends StatelessWidget {
  final _ProjectModel project;

  const _ProjectCard({required this.project});

  Future<void> _openProject(BuildContext context) async {
    final Uri uri = Uri.parse(project.githubUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đường dẫn dự án: ${project.githubUrl}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PortfolioColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card: Icon + Title + Category
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: project.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(project.icon, color: project.iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: PortfolioColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project.category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: project.iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Điểm nổi bật (Highlight tag)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: project.iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: project.iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    project.highlight,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: project.iconColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Mô tả chi tiết từ README
          Expanded(
            child: Text(
              project.description,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: PortfolioColors.textSecondary,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),

          // Tags công nghệ
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: project.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: PortfolioColors.bgScreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PortfolioColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Nút xem chi tiết / GitHub
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openProject(context),
              icon: const FaIcon(FontAwesomeIcons.github, size: 14),
              label: const Text(
                'Xem trên GitHub',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: PortfolioColors.textPrimary,
                side: const BorderSide(color: PortfolioColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 8. CHECKLIST MỤC 3: TRANG LIÊN HỆ (Email, Facebook, GitHub, LinkedIn, Phone)
// =============================================================================

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showNotification(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        backgroundColor: const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (!launched && context.mounted) {
        _showNotification(context, 'Không thể mở liên kết: $urlString');
      }
    } catch (_) {
      if (context.mounted) {
        _showNotification(context, 'Không tìm thấy trình duyệt để mở liên kết!');
      }
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: PortfolioData.email,
      queryParameters: <String, String>{
        'subject': PortfolioData.emailSubject,
      },
    );

    try {
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.platformDefault,
      );
      if (!launched) {
        await Clipboard.setData(
          const ClipboardData(text: PortfolioData.email),
        );
        if (context.mounted) {
          _showNotification(context, 'Đã sao chép email: ${PortfolioData.email}');
        }
      }
    } catch (_) {
      await Clipboard.setData(
        const ClipboardData(text: PortfolioData.email),
      );
      if (context.mounted) {
        _showNotification(
          context,
          'Đã sao chép email: ${PortfolioData.email}',
        );
      }
    }
  }

  Future<void> _dialPhone(BuildContext context) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: PortfolioData.phoneNumber,
    );

    try {
      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.platformDefault,
      );
      if (!launched) {
        await Clipboard.setData(
          const ClipboardData(text: PortfolioData.phoneNumber),
        );
        if (context.mounted) {
          _showNotification(
            context,
            'Đã sao chép số điện thoại: ${PortfolioData.phoneNumber}',
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(
        const ClipboardData(text: PortfolioData.phoneNumber),
      );
      if (context.mounted) {
        _showNotification(
          context,
          'Đã sao chép số điện thoại: ${PortfolioData.phoneNumber}',
        );
      }
    }
  }

  void _handleSendMessage(BuildContext context) {
    final String senderName = _nameController.text.trim();
    final String senderMsg = _messageController.text.trim();

    if (senderName.isEmpty || senderMsg.isEmpty) {
      _showNotification(context, 'Vui lòng điền họ tên và nội dung lời nhắn!');
      return;
    }

    // Mở mail client kèm nội dung tin nhắn hoặc thông báo
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: PortfolioData.email,
      queryParameters: <String, String>{
        'subject': 'Tin nhắn từ $senderName qua Portfolio Web',
        'body': senderMsg,
      },
    );

    launchUrl(emailUri, mode: LaunchMode.platformDefault);
    _showNotification(context, 'Cảm ơn $senderName đã gửi lời nhắn!');
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            PortfolioData.connectHeader,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: PortfolioColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy kết nối với tôi qua mạng xã hội, email hoặc số điện thoại bên dưới.',
            style: TextStyle(
              fontSize: 14,
              color: PortfolioColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // 5 Nút liên hệ thương hiệu chuẩn thiết kế Android portfolio
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 720;

              final Widget buttonsSection = Column(
                children: [
                  // 1. Nút GitHub
                  PortfolioButton(
                    text: PortfolioData.btnGithub,
                    icon: FontAwesomeIcons.github,
                    backgroundColor: PortfolioColors.github,
                    onPressed: () => _launchURL(context, PortfolioData.githubUrl),
                  ),
                  const SizedBox(height: 12),

                  // 2. Nút LinkedIn
                  PortfolioButton(
                    text: PortfolioData.btnLinkedin,
                    icon: FontAwesomeIcons.linkedin,
                    backgroundColor: PortfolioColors.linkedin,
                    onPressed: () => _launchURL(context, PortfolioData.linkedinUrl),
                  ),
                  const SizedBox(height: 12),

                  // 3. Nút Facebook
                  PortfolioButton(
                    text: PortfolioData.btnFacebook,
                    icon: FontAwesomeIcons.facebook,
                    backgroundColor: PortfolioColors.facebook,
                    onPressed: () => _launchURL(context, PortfolioData.facebookUrl),
                  ),
                  const SizedBox(height: 12),

                  // 4. Nút Email
                  PortfolioButton(
                    text: PortfolioData.btnEmail,
                    icon: FontAwesomeIcons.envelope,
                    backgroundColor: PortfolioColors.email,
                    onPressed: () => _sendEmail(context),
                  ),
                  const SizedBox(height: 12),

                  // 5. Nút Phone
                  PortfolioButton(
                    text: PortfolioData.btnPhone,
                    icon: FontAwesomeIcons.phone,
                    backgroundColor: PortfolioColors.phone,
                    onPressed: () => _dialPhone(context),
                  ),
                ],
              );

              final Widget formSection = Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: PortfolioColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gửi Lời Nhắn Nhanh',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: PortfolioColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên của bạn',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email của bạn',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Nội dung tin nhắn...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleSendMessage(context),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Gửi Tin Nhắn',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PortfolioColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: buttonsSection),
                    const SizedBox(width: 24),
                    Expanded(child: formSection),
                  ],
                );
              } else {
                return Column(
                  children: [
                    buttonsSection,
                    const SizedBox(height: 24),
                    formSection,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// =============================================================================
// 9. REUSABLE PORTFOLIO BUTTON (ĐỒNG BỘ VỚI ANDROID BUTTON)
// =============================================================================

class PortfolioButton extends StatefulWidget {
  final String text;
  final FaIconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const PortfolioButton({
    super.key,
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  State<PortfolioButton> createState() => _PortfolioButtonState();
}

class _PortfolioButtonState extends State<PortfolioButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onPressed,
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: FaIcon(
                        widget.icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
