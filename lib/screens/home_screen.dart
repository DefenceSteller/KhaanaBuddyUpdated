import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khaanabuddy/screens/history_screen.dart';
import 'package:khaanabuddy/screens/profile_screen.dart';
import 'package:khaanabuddy/screens/recipe_detail.dart';
import 'package:khaanabuddy/themes/theme.dart';
import 'package:khaanabuddy/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController ingredientController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String selectedCuisine = "Italian";
  String? userName;
  bool _loadingName = true;
  final FocusNode _searchFocus = FocusNode();

  final List<String> cuisines = [
    "Italian",
    "Chinese",
    "Indian",
    "Mexican",
    "American",
    "Thai",
    "Pakistani",
    "English",
    "Mughlai",
    "French"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('name')) {
          setState(() {
            userName = data['name'] ?? "User";
            _loadingName = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error loading name: $e");
    }

    setState(() {
      userName = "User";
      _loadingName = false;
    });
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  void _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
    _loadUserName();
  }

  void _findRecipes() {
    FocusScope.of(context).unfocus();

    final ingredients = ingredientController.text.trim();
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one ingredient')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetail(
          ingredients: ingredients,
          cuisine: selectedCuisine,
        ),
      ),
    );
  }

  void _searchRecipe() {
    FocusScope.of(context).unfocus();
    final query = searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe name to search')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetail(
          ingredients: query,
          cuisine: "",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _loadingName
                      ? const SizedBox(
                          width: 140,
                          child: LinearProgressIndicator(
                            color: AppColors.orange,
                            backgroundColor: AppColors.tint,
                            minHeight: 6,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hello, ${userName ?? 'User'} 👋",
                              style: text.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "What's cooking today?",
                              style: text.bodyMedium?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                ),
                // Theme toggle
                _HeaderButton(
                  icon: themeProvider.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  onTap: () => themeProvider.toggleTheme(),
                ),
                const SizedBox(width: 10),
                // Profile
                _HeaderButton(
                  icon: Icons.person_outline_rounded,
                  onTap: _openProfile,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Search bar ──────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                boxShadow: [AppColors.softShadow],
              ),
              child: TextField(
                controller: searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchRecipe(),
                decoration: const InputDecoration(
                  hintText: "Search any recipe...",
                  prefixIcon: Icon(Icons.search_rounded),
                  fillColor: AppColors.surface,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Hero card: find recipes ─────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [AppColors.glow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Find Recipes",
                        style: text.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Add your ingredients and pick a cuisine",
                    style: text.bodySmall?.copyWith(
                      color: const Color(0xE6FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Ingredients input (white on gradient)
                  TextField(
                    controller: ingredientController,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      hintText: "e.g. tomato, chicken",
                      hintStyle: TextStyle(
                        color: AppColors.muted,
                        fontSize: 15,
                      ),
                      fillColor: AppColors.surface,
                      prefixIcon: Icon(Icons.food_bank_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Cuisine label
                  const Text(
                    "Choose cuisine",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cuisine chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cuisines.map((cuisine) {
                      final selected = cuisine == selectedCuisine;
                      return GestureDetector(
                        onTap: () => setState(() => selectedCuisine = cuisine),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : const Color(0x26FFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : const Color(0x59FFFFFF),
                            ),
                          ),
                          child: Text(
                            cuisine,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.orangeDeep
                                  : const Color(0xF0FFFFFF),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // CTA — inverted white button on gradient
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _findRecipes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.orangeDeep,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Find Recipes",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Feature tiles ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _FeatureTile(
                    icon: Icons.bookmark_rounded,
                    title: "Saved Recipes",
                    subtitle: "Your collection",
                    onTap: _openHistory,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _FeatureTile(
                    icon: Icons.search_rounded,
                    title: "Search Recipe",
                    subtitle: "Find by name",
                    onTap: _searchRecipe,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular white header action button.
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            size: 21,
            color: isDark ? AppColors.darkInk : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// White feature card with orange icon chip.
class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
            boxShadow: isDark ? const [] : const [AppColors.softShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.orange, size: 24),
              ),
              const SizedBox(height: 14),
              Text(title, style: text.titleSmall),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
