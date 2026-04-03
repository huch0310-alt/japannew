import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
}

SupabaseClient get supabaseClient => Supabase.instance.client;
