// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khaanabuddy/services/recipe_service.dart';
import 'package:khaanabuddy/themes/theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final String userId =
      Supabase.instance.client.auth.currentUser?.id ?? "guest";
  final RecipeService _recipeService = RecipeService();

  /// ✅ STEP 3 — Show recipe details popup and handle deletion
  void _showRecipePopup(
      BuildContext context, Map<String, dynamic> data, String docId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          data["title"] ?? "Recipe",
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.orange,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data["full_text"] ?? "No recipe details available.",
                style: text.bodyMedium?.copyWith(height: 1.55),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await _recipeService.deleteRecipe(docId);
                  } catch (e) {
                    debugPrint('Error deleting recipe: $e');
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Recipe deleted successfully 🗑️"),
                    ),
                  );
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete Recipe"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  /// ✅ STEP 3 — UI for showing history list
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Recipe History",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _recipeService.watchRecipes(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('History stream error: ${snapshot.error}');
            return const Center(child: Text("Error loading recipes"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            // Empty state
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      color: AppColors.tint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_border_rounded,
                      color: AppColors.orange,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("No recipes found yet 🍳", style: text.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    "Recipes you save will appear here",
                    style: text.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final docId = (data['id'] ?? '').toString();

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showRecipePopup(context, data, docId),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                        boxShadow:
                            isDark ? const [] : const [AppColors.softShadow],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.tint,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data["title"] ?? "Untitled Recipe",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data["cuisine"] ?? "Saved recipe",
                                  style: text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
