// lib/config/ai_config.dart
// COPY THIS FILE AND RENAME TO ai_config_local.dart
// THEN ADD YOUR API KEY TO ai_config_local.dart
// ai_config_local.dart IS IN .gitignore AND WILL NOT BE COMMITTED

class AIConfig {
  // Groq API key - get free keys at https://console.groq.com/keys
  static const String groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
  static const String baseUrl = 'https://api.groq.com/openai/v1';
  static const String model = 'qwen/qwen3.8-27b';
}