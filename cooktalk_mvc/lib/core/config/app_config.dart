import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  static bool get isDebugMode => dotenv.env['DEBUG_MODE'] == 'true';
  
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      throw Exception('Failed to load .env file: $e');
    }
  }
  
  static void validateConfig() {
    if (geminiApiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set in .env file');
    }
  }
}
