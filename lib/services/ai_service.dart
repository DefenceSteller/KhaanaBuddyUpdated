import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config_local.dart';

class AIService {
  static Future<String> getRecipe(String ingredients, String cuisine) async {
    // ✅ Step 1: Safety filter for inappropriate or irrelevant inputs
    final bannedWords = [
      "kill", "sex", "nude", "bomb", "weapon", "fight", "war", "politics",
      "violence", "blood", "drug", "alcohol", "gun", "murder", "death",
      "crime", "terror", "virus", "disease", "hack", "joke", "song",
      "movie", "story", "game", "music", "love", "hate", "religion",
      "chair", "table", "wood", "metal", "plastic", "toy", "car", "rock",
      "phone", "laptop", "computer", "keyboard", "book", "pen", "shirt",
      "dress", "shoe", "bag", "fan", "light", "bed", "door", "window"
    ];

    // ✅ Step 2: Common food-related words (helps detect valid cooking intent)
    final foodKeywords = [
      "chicken", "rice", "egg", "bread", "sugar", "flour", "milk", "salt",
      "butter", "beef", "fish", "potato", "onion", "garlic", "pepper",
      "oil", "tomato", "carrot", "cheese", "pasta", "beans", "corn",
      "fruit", "vegetable", "spice", "curry", "soup", "cake", "cookie",
      "dessert", "juice", "water", "tea", "coffee"
    ];

    final combinedInput = "${ingredients.toLowerCase()} ${cuisine.toLowerCase()}";

    // ✅ Block empty, too short, or banned words
    if (combinedInput.trim().isEmpty ||
        combinedInput.length < 3 ||
        bannedWords.any((word) => combinedInput.contains(word))) {
      return "⚠️ Please enter valid cooking ingredients or cuisine names only.";
    }

    // ✅ If it doesn't contain any food-like words, block it
    final containsFoodWord =
        foodKeywords.any((word) => combinedInput.contains(word));
    if (!containsFoodWord) {
      return "⚠️ That doesn't sound like a food or ingredient. Please enter real cooking ingredients.";
    }

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
      final response = await http.post(
        Uri.parse('${AIConfig.baseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AIConfig.groqApiKey}',
        },
        body: jsonEncode({
          'model': AIConfig.model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['choices'][0]['message']['content'] as String).trim();
      } else if (response.statusCode == 401) {
        return '⚠️ AI configuration error — check your Groq API key.';
      } else if (response.statusCode == 429) {
        return '⚠️ Too many requests — please wait a moment and try again.';
      } else {
        return 'Error generating recipe: HTTP ${response.statusCode}';
      }
    } catch (e) {
      return "Error generating recipe: $e";
    }
  }
}