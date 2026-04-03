class AppConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // 日本单位
  static const List<String> units = ['個', 'kg', 'g', '袋', '箱', '束', '本'];

  // 默认消费税率 8%
  static const double defaultTaxRate = 0.08;
}
