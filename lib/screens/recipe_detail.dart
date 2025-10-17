import 'package:flutter/material.dart';
import 'package:khaanabuddy/services/ai_service.dart';
import 'package:khaanabuddy/voice/voice_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:khaanabuddy/services/youtube_service.dart';
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
  bool _videoLoadFailed = false;

  late AnimationController _aiAnimationController;
  late Animation<double> _bounceAnimation;

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
        _videoLoadFailed = false;
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
          _videoLoadFailed = true;
          _isVideoLoading = false;
        });
      }

      VoiceService().speak("Here’s a recipe for you.");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        recipe = "Error loading recipe: $e";
        _isVideoLoading = false;
        _videoLoadFailed = true;
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

    List<InlineSpan> textSpans = [];

    if (title.isNotEmpty) {
      textSpans.add(TextSpan(
        text: "$title\n\n",
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF7A1A),
          height: 1.8,
        ),
      ));
    }

    for (var line in lines) {
      if (RegExp(r'ingredients|instructions|serving tip|steps|directions',
              caseSensitive: false)
          .hasMatch(line)) {
        textSpans.add(TextSpan(
          text: "\n${line.toUpperCase()}\n",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFFFF7A1A),
            height: 2.0,
          ),
        ));
      } else if (RegExp(r'^(\d+\.|\-|\*)').hasMatch(line)) {
        textSpans.add(TextSpan(
          text: "• ${line.replaceAll(RegExp(r'^(\d+\.|\-|\*)'), '').trim()}\n",
          style: const TextStyle(fontSize: 16, height: 1.6),
        ));
      } else if (line.contains(widget.cuisine)) {
        textSpans.add(TextSpan(
          children: [
            TextSpan(
              text: line.replaceAll(widget.cuisine, ''),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            TextSpan(
              text: widget.cuisine,
              style: const TextStyle(
                  color: Color(0xFFFF7A1A), fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: "\n"),
          ],
        ));
      } else if (line.contains(widget.ingredients)) {
        textSpans.add(TextSpan(
          children: [
            TextSpan(
              text: line.replaceAll(widget.ingredients, ''),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            TextSpan(
              text: widget.ingredients,
              style: const TextStyle(
                  color: Color(0xFFFF7A1A), fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: "\n"),
          ],
        ));
      } else {
        textSpans.add(TextSpan(
          text: "$line\n",
          style: const TextStyle(fontSize: 16, height: 1.6),
        ));
      }
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87),
        children: textSpans,
      ),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF7A1A),
        title: const Text(
          "Recipe Detail",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: isLoading
          ? Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.restaurant_menu,
                          color: Color(0xFFFF7A1A), size: 60),
                      SizedBox(height: 16),
                      Text(
                        "Cooking up your recipe...",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30,
                  right: 30,
                  child: AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_bounceAnimation.value),
                        child: Row(
                          children: const [
                            Icon(Icons.smart_toy,
                                color: Color(0xFFFF7A1A), size: 40),
                            SizedBox(width: 8),
                            Text(
                              "AI is thinking...",
                              style: TextStyle(
                                  color: Color(0xFFFF7A1A), fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildCleanRecipeText(recipe),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_videoId != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Watch Recipe Tutorial:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF7A1A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        YoutubePlayerBuilder(
                          player: YoutubePlayer(
                            controller: _youtubeController!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Color(0xFFFF7A1A),
                          ),
                          builder: (context, player) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: player,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      child: const Text(
                        'No tutorial video available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),

      /// ✅ Hide Save button while loading
      floatingActionButton: isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _saveRecipe,
              backgroundColor: const Color(0xFFFF7A1A),
              icon: const Icon(Icons.save),
              label: const Text("Save Recipe"),
            ),
    );
  }
}
