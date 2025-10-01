import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String apiKey = "AIzaSyA-rGvnGcjdpTh4gYzQWiUze64_MbJ-TMo"; // replace with your key

  static Future<String> getRecipe(String ingredients, String cuisine) async {
    final model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );

    final prompt = '''
Suggest a detailed step-by-step recipe using the following ingredients: $ingredients.
Cuisine type: $cuisine.
Include ingredients, steps, and a short name/title for the dish.
''';

    final response = await model.generateContent([
      Content.text(prompt),
    ]);

    // Return generated text (if available)
    return response.text ?? "No recipe generated.";
  }
}
