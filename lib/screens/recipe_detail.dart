import 'package:flutter/material.dart';
import 'package:khaanabuddy/services/ai_service.dart';
// import 'package:khaanabuddy/services/firestore_service.dart';
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

class _RecipeDetailState extends State<RecipeDetail> {
  String recipe = "";
  bool isLoading = true;

  YoutubePlayerController? _youtubeController;
  String? _videoId;
  bool _isVideoLoading = false;
  bool _videoLoadFailed = false;

  @override

  void initState() {
    super.initState();
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
    final lines = recipe.split('\n');
    final info = <String, String>{};
    if (lines.isNotEmpty) info['dishName'] = lines.first.replaceAll('#', '').trim();
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

  /// ✅ Properly format and clean recipe text
  Widget _buildCleanRecipeText(String recipeText) {
    // Step 1: Remove all hashtags
    String cleaned = recipeText.replaceAll('#', '');

    // Step 2: Split into lines and remove empties
    List<String> lines = cleaned.split('\n').map((e) => e.trim()).toList();
    lines.removeWhere((line) => line.isEmpty);

    // Step 3: Add visual formatting (headings + bullets)
    List<InlineSpan> textSpans = [];
    for (var line in lines) {
      // Detect headers like "Ingredients", "Instructions", etc.
      if (RegExp(r'ingredients|instructions|steps|directions', caseSensitive: false)
          .hasMatch(line)) {
        textSpans.add(TextSpan(
          text: "\n${line.toUpperCase()}\n",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.orange,
            height: 2.0,
          ),
        ));
      } 
      // Detect bullet points
      else if (RegExp(r'^(\d+\.|\-|\*)').hasMatch(line)) {
        textSpans.add(TextSpan(
          text: "• ${line.replaceAll(RegExp(r'^(\d+\.|\-|\*)'), '').trim()}\n",
          style: const TextStyle(fontSize: 16, height: 1.6),
        ));
      } 
      // Normal paragraph
      else {
        textSpans.add(TextSpan(
          text: "$line\n",
          style: const TextStyle(fontSize: 16, height: 1.6),
        ));
      }
    }

    return RichText(
      text: TextSpan(style: const TextStyle(color: Colors.black87), children: textSpans),
    );
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          "Recipe Detail",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
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
                              color: Colors.orange),
                        ),
                        const SizedBox(height: 10),
                        YoutubePlayerBuilder(
                          player: YoutubePlayer(
                            controller: _youtubeController!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.orange,
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveRecipe,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.save),
        label: const Text("Save Recipe"),
      ),
    );
  }

}
