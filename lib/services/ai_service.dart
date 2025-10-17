import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String apiKey = "AIzaSyDVyZ7YZ6QIswgvTXZNDR2ISbcilBGRRhY";

  static Future<String> getRecipe(String ingredients, String cuisine) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-pro',
      apiKey: apiKey,
    );

    // ✅ Detect if user searched a recipe directly (not ingredients)
    final bool isSearchQuery =
        cuisine.trim().isEmpty || cuisine.toLowerCase() == "default";

    final prompt = isSearchQuery
        ? '''
You are an experienced home chef. 
Generate a detailed, realistic recipe for **"$ingredients"**.

Include:
1. A short and clear recipe title.
2. List of realistic ingredients (use basic household items only).
3. Step-by-step cooking instructions.
4. Optional: a short serving tip or variation.

Keep the tone helpful, concise, and beginner-friendly.
Avoid any exotic or rare ingredients.
Return your response in **this exact structured format**:

<title>Recipe Name Here</title>

Ingredients:
- List of ingredients

Instructions:
1. Step one
2. Step two
3. ...

Serving Tip:
(Optional: one or two short lines)
'''
        : '''
You are an experienced home chef. 
Create a detailed, realistic recipe that belongs to the "$cuisine" cuisine using **only** the following ingredients:
$ingredients

You may use **only very basic, common household spices or condiments** if needed:
(salt, black pepper, red chili powder, turmeric, cooking oil, butter, onion, garlic, ginger, or water).

Do NOT add any other ingredient that is not listed above.
The recipe should be simple, home-cook friendly, and require no special or exotic items.

Return your response in **this exact structured format**:

<title>Recipe Name Here</title>

Ingredients:
- List of ingredients (only from the given list + basic spices)

Instructions:
1. Step one
2. Step two
3. ...

Serving Tip:
(Optional: one or two short lines)

Keep tone helpful and concise.
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
