import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Values load from [.env] at startup (see [load]).
/// Override with --dart-define=KEY=value when needed (dart-define wins for empty .env fields).
class Env {
  Env._();

  /// Call from main() before using [hasSupabase] or Supabase.initialize.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Missing .env (e.g. CI): rely on dart-define only.
    }
  }

  static String _get(String dotenvKey, String dartDefineKey) {
    final fromFile = dotenv.env[dotenvKey]?.trim();
    if (fromFile != null && fromFile.isNotEmpty) return fromFile;
    return String.fromEnvironment(dartDefineKey, defaultValue: '');
  }

  static String get supabaseUrl => _get('SUPABASE_URL', 'SUPABASE_URL');
  static String get supabaseAnonKey =>
      _get('SUPABASE_ANON_KEY', 'SUPABASE_ANON_KEY');
  static String get geminiApiKey => _get('GEMINI_API_KEY', 'GEMINI_API_KEY');
  static String get googleMapsApiKey =>
      _get('GOOGLE_MAPS_API_KEY', 'GOOGLE_MAPS_API_KEY');
  static String get placesApiKey => _get('PLACES_API_KEY', 'PLACES_API_KEY');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  static bool get hasGemini => geminiApiKey.isNotEmpty;
  static String get effectivePlacesKey =>
      placesApiKey.isNotEmpty ? placesApiKey : googleMapsApiKey;
}
