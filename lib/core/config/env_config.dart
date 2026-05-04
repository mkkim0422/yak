/// Environment configuration. Real values are wired in Phase 2.
class EnvConfig {
  EnvConfig._();

  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String claudeApiKey = '';

  static const bool isProduction = false;

  static bool get hasClaudeKey => claudeApiKey.isNotEmpty;
  static bool get hasSupabaseKeys =>
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
}
