// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khaanabuddy/services/recipe_service.dart';
import 'package:khaanabuddy/themes/theme.dart';

/// 🌿 Saved Recipes — "Your cookbook", styled with the Botanical Kitchen
/// design system (cream surfaces, basil-green gradient tiles, Fraunces
/// headings, saffron-free muted meta text).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final String userId =
      Supabase.instance.client.auth.currentUser?.id ?? "guest";
  final RecipeService _recipeService = RecipeService();

  String _query = '';

  // ── Filtering ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> docs) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return docs;
    return docs.where((d) {
      final title = (d['title'] ?? '').toString().toLowerCase();
      final cuisine = (d['cuisine'] ?? '').toString().toLowerCase();
      final ingredients = (d['ingredients'] ?? '').toString().toLowerCase();
      return title.contains(q) ||
          cuisine.contains(q) ||
          ingredients.contains(q);
    }).toList();
  }

  // ── Relative date: "Just now" · "3h ago" · "2d ago" · "12 Nov" ───────
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  // ── Recipe viewer (bottom sheet) ─────────────────────────────────────
  void _showRecipeSheet(
      BuildContext parentContext, Map<String, dynamic> data, String docId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;
    final title = (data['title'] ?? 'Recipe').toString();
    final cuisine = (data['cuisine'] ?? '').toString().trim();
    final dateLabel = _formatDate(data['created_at']?.toString());

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.sizeOf(sheetContext).height * 0.86,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [AppColors.cardShadow],
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),

              // Header: gradient tile + title + meta + close
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.bookmark_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (cuisine.isNotEmpty)
                                _CuisineChip(label: cuisine, isDark: isDark),
                              if (dateLabel.isNotEmpty)
                                Text(
                                  dateLabel,
                                  style: text.bodySmall?.copyWith(
                                    fontSize: 12.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: isDark ? AppColors.darkTint : AppColors.tint,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(sheetContext),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.darkInk
                                : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Recipe body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                  child: SelectableText(
                    (data['full_text'] ?? 'No recipe details available.')
                        .toString(),
                    style: text.bodyMedium?.copyWith(height: 1.65),
                  ),
                ),
              ),

              // Actions
              Container(
                padding: EdgeInsets.fromLTRB(
                  22,
                  14,
                  22,
                  16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.border,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await _recipeService.deleteRecipe(docId);
                          } catch (e) {
                            debugPrint('Error deleting recipe: $e');
                          }
                          if (!mounted) return;
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Recipe deleted 🗑️"),
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 19),
                        label: const Text("Delete"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(
                              color: Color(0x66EF4444), width: 1.4),
                          minimumSize: const Size.fromHeight(52),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text("Done"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Page ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _recipeService.watchRecipes(userId),
      builder: (context, snapshot) {
        final docs = snapshot.data ?? <Map<String, dynamic>>[];
        final filtered = _filter(docs);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Saved Recipes"),
                Text(
                  snapshot.connectionState == ConnectionState.waiting
                      ? "Loading your cookbook…"
                      : docs.length == 1
                          ? "1 recipe in your cookbook"
                          : "${docs.length} recipes in your cookbook",
                  style: text.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          body: _buildBody(snapshot, docs, filtered, text, isDark),
        );
      },
    );
  }

  Widget _buildBody(
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    List<Map<String, dynamic>> docs,
    List<Map<String, dynamic>> filtered,
    TextTheme text,
    bool isDark,
  ) {
    // Loading
    if (snapshot.connectionState == ConnectionState.waiting &&
        snapshot.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.brand),
            const SizedBox(height: 16),
            Text("Loading your cookbook…", style: text.bodySmall),
          ],
        ),
      );
    }

    // Error
    if (snapshot.hasError) {
      debugPrint('History stream error: ${snapshot.error}');
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: AppColors.muted, size: 44),
              const SizedBox(height: 14),
              Text("Couldn't load recipes", style: text.titleMedium),
              const SizedBox(height: 6),
              Text(
                "Check your connection and try again.",
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text("Try again"),
              ),
            ],
          ),
        ),
      );
    }

    // Empty cookbook
    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradient,
                  shape: BoxShape.circle,
                  boxShadow: [AppColors.glow],
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                "No saved recipes yet",
                textAlign: TextAlign.center,
                style: text.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                "Tap Save Recipe on any dish and it will live here in your cookbook.",
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: 230,
                child: ElevatedButton.icon(
                  onPressed: _goHome,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 19),
                  label: const Text("Find a recipe"),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // List
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        // Search field
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            boxShadow: [AppColors.softShadow],
          ),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: "Search your saved recipes...",
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppColors.muted,
                      onPressed: () => setState(() => _query = ''),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Section header + count
        Row(
          children: [
            Text(
              _query.trim().isEmpty ? "Your collection" : "Search results",
              style: text.titleMedium,
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkTint : AppColors.tint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${filtered.length}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.brandSoft : AppColors.brandDeep,
                ),
              ),
            ),
            const Spacer(),
            if (_query.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _query = ''),
                child: const Text("Clear"),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // No search matches
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkTint : AppColors.tint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.brand,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text("No matches for \"$_query\"", style: text.titleMedium),
                const SizedBox(height: 6),
                Text(
                  "Try another title, cuisine or ingredient.",
                  style: text.bodySmall,
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: () => setState(() => _query = ''),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                  ),
                  child: const Text("Clear search"),
                ),
              ],
            ),
          )
        else
          ...filtered.map((data) {
            final docId = (data['id'] ?? '').toString();
            return _RecipeCard(
              data: data,
              dateLabel: _formatDate(data['created_at']?.toString()),
              isDark: isDark,
              onTap: () => _showRecipeSheet(context, data, docId),
            );
          }),
      ],
    );
  }

  void _goHome() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }
}

// ── Reusable pieces ────────────────────────────────────────────────────

class _CuisineChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _CuisineChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkTint : AppColors.tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0x33FFA64D)
              : const Color(0x33FF7A1A),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isDark ? AppColors.brandSoft : AppColors.brandDeep,
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String dateLabel;
  final bool isDark;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.data,
    required this.dateLabel,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = (data['title'] ?? 'Untitled Recipe').toString();
    final cuisine = (data['cuisine'] ?? '').toString().trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              boxShadow:
                  isDark ? const [] : const [AppColors.softShadow],
            ),
            child: Row(
              children: [
                // Gradient recipe tile
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33FF7A1A),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (cuisine.isNotEmpty)
                            _CuisineChip(label: cuisine, isDark: isDark),
                          if (dateLabel.isNotEmpty)
                            Text(
                              dateLabel,
                              style: text.bodySmall?.copyWith(
                                fontSize: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chevron chip
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkTint : AppColors.tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark ? AppColors.brandSoft : AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
