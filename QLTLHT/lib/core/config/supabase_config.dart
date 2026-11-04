class SupabaseConfig {
  /// URL dự án Supabase (Mặc định hoặc người dùng có thể cấu hình)
  static String supabaseUrl = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qltlht-project.supabase.co',
  );

  /// Anon Public Key của Supabase
  static String supabaseAnonKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.fake_anon_key_for_testing',
  );

  /// Cho phép tùy biến URL và Key qua cài đặt ứng dụng
  static void updateConfig({required String url, required String anonKey}) {
    supabaseUrl = url;
    supabaseAnonKey = anonKey;
  }
}
