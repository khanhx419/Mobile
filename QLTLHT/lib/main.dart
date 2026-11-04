import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/config/firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'pages/home_page.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/document_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/subject_provider.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SQLite FFI for Web and Desktop platforms
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 2. Initialize Storage preferences
  await StorageService.init();

  // 3. Initialize Firebase Cloud Services (an toàn, không crash khi thiếu key mạng)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase App initialized successfully.');
  } catch (e) {
    debugPrint('Firebase initializeApp notification: $e. Sử dụng Secure Simulated Fallback.');
  }

  // 4. Initialize Supabase Cloud Services
  try {
    await SupabaseService().initialize();
  } catch (e) {
    debugPrint('Supabase initialize notification: $e');
  }

  runApp(const QltlhtApp());
}

class QltlhtApp extends StatelessWidget {
  const QltlhtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
      ],
      child: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settings, auth, _) {
          // Tự động đồng bộ currentUserId cho DocumentProvider khi chuyển đổi tài khoản
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final docProvider = Provider.of<DocumentProvider>(context, listen: false);
            if (auth.currentUser != null && docProvider.currentUserId != auth.currentUser!.id) {
              docProvider.setCurrentUserId(auth.currentUser!.id);
            }
          });

          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: AppTheme.lightTheme(settings.accentColor),
            darkTheme: AppTheme.darkTheme(settings.accentColor),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
