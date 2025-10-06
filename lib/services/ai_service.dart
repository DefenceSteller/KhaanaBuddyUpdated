import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // ✅ Replace with your verified Gemini API key
  static const String apiKey = "AIzaSyAkv-Ugat2ZhkBygBJM-PzN7mKRSG12XFQ";

  static Future<String> getRecipe(String ingredients, String cuisine) async {
    // Use a model that exists in your key's model list
    final model = GenerativeModel(
      model: 'gemini-2.5-pro-preview-03-25', // ✅ from your verified JSON
      apiKey: apiKey,
    );

    final prompt = '''
Generate a detailed recipe using these ingredients: $ingredients.
Cuisine type: $cuisine.
Include:
1. A short recipe title.
2. List of ingredients with measurements.
3. Step-by-step cooking instructions.
4. A serving suggestion or tip.
''';

    try {
      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      return response.text?.trim() ?? "No recipe generated.";
    } catch (e) {
      return "Error generating recipe: $e";
    }
  }
}
