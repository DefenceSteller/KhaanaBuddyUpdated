// lib/services/recipe_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// ✅ Recipe data access for Supabase (table: public.recipes).
class RecipeService {
  /// Save a recipe for the current user.
  Future<void> saveRecipe({
    required String userId,
    required String title,
    required String ingredients,
    required String cuisine,
    required String fullText,
    bool isFavorite = false,
  }) async {
    await supabase.from('recipes').insert({
      'user_id': userId,
      'title': title,
      'ingredients': ingredients,
      'cuisine': cuisine,
      'full_text': fullText,
      'is_favorite': isFavorite,
    });
  }

  /// Live stream of a user's recipes (newest first).
  /// Each item includes its `id` alongside the recipe fields.
  Stream<List<Map<String, dynamic>>> watchRecipes(
    String userId, {
    bool isFavorite = false,
  }) {
    return supabase
        .from('recipes')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .eq('is_favorite', isFavorite)
        .order('created_at', ascending: false);
  }

  /// One-time fetch of a user's recipes (newest first).
  Future<List<Map<String, dynamic>>> fetchRecipes(
    String userId, {
    bool isFavorite = false,
  }) async {
    final rows = await supabase
        .from('recipes')
        .select()
        .eq('user_id', userId)
        .eq('is_favorite', isFavorite)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Delete a recipe by its id.
  Future<void> deleteRecipe(String recipeId) async {
    await supabase.from('recipes').delete().eq('id', recipeId);
  }

  /// Exact count of a user's recipes (for profile stats).
  Future<int> countRecipes(String userId, {bool isFavorite = false}) async {
    final response = await supabase
        .from('recipes')
        .select()
        .eq('user_id', userId)
        .eq('is_favorite', isFavorite)
        .count(CountOption.exact);
    return response.count;
  }
}
