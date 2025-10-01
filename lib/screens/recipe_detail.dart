import 'package:flutter/material.dart';
import 'package:khaanabuddy/services/ai_service.dart';
import 'package:khaanabuddy/services/firestore_service.dart';
import 'package:khaanabuddy/voice/voice_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:khaanabuddy/services/youtube_service.dart'; // defines class YoutubeService

class RecipeDetail extends StatefulWidget {
  const RecipeDetail({super.key});

  @override
  State<RecipeDetail> createState() => _RecipeDetailState();
}

class _RecipeDetailState extends State<RecipeDetail> {
  String recipe = "";
  bool isLoading = true;

  YoutubePlayerController? _youtubeController;
  String? _videoId;

  late String ingredients;
  late String cuisine;
  late String userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;

    ingredients = args["ingredients"];
    cuisine = args["cuisine"];
    userId = args["userId"];

    _initializeContent();
  }

  Future<void> _initializeContent() async {
    await _loadRecipe(ingredients, cuisine);

    // 🔧 Use YoutubeService (no capital T)
    final videoId = await YoutubeService.getFirstVideoId("How to make $cuisine recipe");
    if (!mounted) return;

    if (videoId != null) {
      setState(() {
        _videoId = videoId;
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false),
        );
      });
    }
  }

  Future<void> _loadRecipe(String ingredients, String cuisine) async {
    try {
      final result = await AIService.getRecipe(ingredients, cuisine);
      if (!mounted) return;
      setState(() {
        recipe = result;
        isLoading = false;
      });
      VoiceService().speak("Here's a recipe for you.");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        recipe = "Error loading recipe: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _saveRecipe() async {
    try {
      await FirestoreService().saveRecipe(
        userId: userId,
        title: "Generated Recipe",
        ingredients: ingredients,
        cuisine: cuisine,
        fullText: recipe,
        isFavorite: false,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipe saved to history")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save recipe: $e")),
      );
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recipe details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  if (_videoId != null && _youtubeController != null)
                    YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: true,
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveRecipe,
        icon: const Icon(Icons.history),
        label: const Text("Save to history"),
      ),
    );
  }
}
