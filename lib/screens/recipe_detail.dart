import 'package:flutter/material.dart';
import 'package:khaanabuddy/services/ai_service.dart';
import 'package:khaanabuddy/voice/voice_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:khaanabuddy/services/youtube_service.dart';
import 'package:khaanabuddy/themes/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetail extends StatefulWidget {
  final String ingredients;
  final String cuisine;

  const RecipeDetail({
    super.key,
    required this.ingredients,
    required this.cuisine,
  });

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail>
    with SingleTickerProviderStateMixin {
  String recipe = "";
  bool isLoading = true;

  YoutubePlayerController? _youtubeController;
  String? _videoId;
  bool _isVideoLoading = false;

  late AnimationController _aiAnimationController;
  late Animation<double> _bounceAnimation;

  final Color accentColor = AppColors.orange;

  @override
  void initState() {
    super.initState();

    _aiAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation =
        Tween<double>(begin: 0, end: 10).animate(CurvedAnimation(
      parent: _aiAnimationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecipe(widget.ingredients, widget.cuisine);
    });
  }

  Future<void> _loadRecipe(String ingredients, String cuisine) async {
    try {
      final result = await AIService.getRecipe(ingredients, cuisine);
      if (!mounted) return;

      setState(() {
        recipe = result;
        _isVideoLoading = true;
      });

      final recipeInfo = _extractRecipeInfo(result);
      String searchQuery =
          "${recipeInfo['dishName'] ?? ingredients} ${cuisine} recipe";

      final videoId = await YoutubeService.getFirstVideoId(searchQuery);

      if (!mounted) return;

      if (videoId != null) {
        _youtubeController?.dispose();
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false),
        );
        setState(() {
          _videoId = videoId;
          _isVideoLoading = false;
        });
      } else {
        setState(() {
          _isVideoLoading = false;
        });
      }

      // Only speak when the user has voice readouts enabled in Profile.
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('voiceEnabled') ?? true) {
          VoiceService().speak("Here’s a recipe for you.");
        }
      } catch (_) {
        VoiceService().speak("Here’s a recipe for you.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        recipe = "Error loading recipe: $e";
        _isVideoLoading = false;
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Map<String, String> _extractRecipeInfo(String recipe) {
    final titleMatch =
        RegExp(r'<title>(.*?)<\/title>', dotAll: true).firstMatch(recipe);
    final info = <String, String>{};
    if (titleMatch != null) {
      info['dishName'] = titleMatch.group(1)?.trim() ?? '';
    } else {
      final markdownTitleMatch =
          RegExp(r'\*{1,2}(.*?)\*{1,2}').firstMatch(recipe);
      if (markdownTitleMatch != null) {
        info['dishName'] = markdownTitleMatch.group(1)?.trim() ?? '';
      } else {
        final lines = recipe.split('\n');
        if (lines.isNotEmpty) info['dishName'] = lines.first.trim();
      }
    }
    return info;
  }

  Future<void> _saveRecipe() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final recipeInfo = _extractRecipeInfo(recipe);
      final title = recipeInfo['dishName'] ?? "Generated Recipe";

      final recipeData = {
        "title": title,
        "ingredients": widget.ingredients,
        "cuisine": widget.cuisine,
        "fullText": recipe,
        "timestamp": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("history")
          .add(recipeData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipe saved successfully ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error saving recipe: $e")));
    }
  }

  Widget _buildCleanRecipeText(String recipeText) {
    final titleRegex = RegExp(r'<title>(.*?)<\/title>', dotAll: true);
    final markdownTitleRegex = RegExp(r'\*{1,2}(.*?)\*{1,2}');
    String title = '';

    final titleMatch = titleRegex.firstMatch(recipeText);
    if (titleMatch != null) {
      title = titleMatch.group(1)?.trim() ?? '';
      recipeText = recipeText.replaceAll(titleRegex, '');
    } else {
      final markdownMatch = markdownTitleRegex.firstMatch(recipeText);
      if (markdownMatch != null) {
        title = markdownMatch.group(1)?.trim() ?? '';
        recipeText = recipeText.replaceAll(markdownTitleRegex, '');
      }
    }

    String cleaned = recipeText.replaceAll('#', '');
    List<String> lines = cleaned.split('\n').map((e) => e.trim()).toList();
    lines.removeWhere((line) => line.isEmpty);

    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    List<InlineSpan> textSpans = [];

    if (title.isNotEmpty) {
      textSpans.add(TextSpan(
        text: "$title\n\n",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: accentColor,
          height: 1.7,
        ),
      ));
    }

    for (var line in lines) {
      if (RegExp(r'ingredients|instructions|serving tip|steps|directions',
              caseSensitive: false)
          .hasMatch(line)) {
        textSpans.add(TextSpan(
          text: "\n${line.toUpperCase()}\n",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: accentColor,
            height: 2.0,
            letterSpacing: 0.5,
          ),
        ));
      } else if (RegExp(r'^(\d+\.|\-|\*)').hasMatch(line)) {
        textSpans.add(TextSpan(
          text: "• ${line.replaceAll(RegExp(r'^(\d+\.|\-|\*)'), '').trim()}\n",
          style: TextStyle(fontSize: 16, height: 1.6, color: textColor),
        ));
      } else {
        textSpans.add(TextSpan(
          text: "$line\n",
          style: TextStyle(fontSize: 16, height: 1.6, color: textColor),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: textSpans),
    );
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _aiAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = Theme.of(context).textTheme;
    final cardColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final cardBorder =
        isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Recipe Detail",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: isLoading
          ? Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gradient icon bubble
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          gradient: AppColors.gradient,
                          shape: BoxShape.circle,
                          boxShadow: [AppColors.glow],
                        ),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Cooking up your recipe...",
                        style: text.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Our AI chef is working on it",
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const LinearProgressIndicator(
                            minHeight: 6,
                            color: AppColors.orange,
                            backgroundColor: AppColors.tint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30,
                  right: 24,
                  child: AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_bounceAnimation.value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [AppColors.softShadow],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.smart_toy_rounded,
                                color: AppColors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "AI is thinking...",
                                style: TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: cardBorder),
                      boxShadow: isDark
                          ? const []
                          : const [AppColors.cardShadow],
                    ),
                    child: _buildCleanRecipeText(recipe),
                  ),
                  const SizedBox(height: 24),

                  // Tutorial section
                  if (_videoId != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.tint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_circle_fill_rounded,
                                color: AppColors.orange,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Watch Recipe Tutorial",
                              style: text.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: YoutubePlayerBuilder(
                            player: YoutubePlayer(
                              controller: _youtubeController!,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: accentColor,
                            ),
                            builder: (context, player) => player,
                          ),
                        ),
                      ],
                    )
                  else if (_isVideoLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(
                          color: AppColors.orange,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.videocam_off_outlined,
                            color: AppColors.muted,
                            size: 34,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No tutorial video available',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

      floatingActionButton: isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _saveRecipe,
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.bookmark_add_rounded),
              label: const Text(
                "Save Recipe",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}
