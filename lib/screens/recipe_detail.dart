import 'package:flutter/material.dart';
import 'package:khaanabuddy/services/ai_service.dart';
import 'package:khaanabuddy/services/firestore_service.dart';
import 'package:khaanabuddy/voice/voice_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:khaanabuddy/services/youtube_service.dart';

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
  bool _isVideoLoading = false;
  bool _videoLoadFailed = false;

  String ingredients = "";
  String cuisine = "";
  String userId = "guest";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    ingredients = args["ingredients"] ?? "";
    cuisine = args["cuisine"] ?? "";
    userId = args["userId"] ?? "guest";
    _loadRecipe(ingredients, cuisine);
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

      // ✅ Extract better recipe information for YouTube search
      final recipeInfo = _extractRecipeInfo(result);
      
      // Create more specific search query
      String searchQuery;
      if (recipeInfo['dishName'] != null && recipeInfo['cuisine'] != null) {
        searchQuery = "${recipeInfo['dishName']} ${recipeInfo['cuisine']} recipe";
      } else if (recipeInfo['dishName'] != null) {
        searchQuery = "${recipeInfo['dishName']} recipe";
      } else {
        // Fallback to original method
        final titleLine = recipe.split('\n').first.trim();
        searchQuery = "$titleLine recipe tutorial";
      }

      print("🔍 Searching YouTube for: $searchQuery");

      // ✅ Fetch related YouTube video
      final videoId = await YoutubeService.getFirstVideoId(searchQuery);

      if (videoId != null && mounted) {
        // Dispose previous controller if exists
        _youtubeController?.dispose();
        
        // Create new controller
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: false,
            forceHD: false,
          ),
        );

        // Add listener to track video state
        _youtubeController!.addListener(() {
          if (_youtubeController!.value.hasError && mounted) {
            setState(() {
              _videoLoadFailed = true;
              _isVideoLoading = false;
            });
          }
        });

        // Small delay to ensure proper initialization
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          setState(() {
            _videoId = videoId;
            _isVideoLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isVideoLoading = false;
            _videoLoadFailed = true;
          });
        }
      }

      VoiceService().speak("Here's a recipe for you.");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        recipe = "Error loading recipe: $e";

        _isVideoLoading = false;
        _videoLoadFailed = true;
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Map<String, String> _extractRecipeInfo(String recipe) {
    final lines = recipe.split('\n');
    final Map<String, String> info = {};
    
    // Extract dish name from first line
    if (lines.isNotEmpty) {
      String firstLine = lines.first.trim();
      // Remove common prefixes
      firstLine = firstLine.replaceAll(RegExp(r'^Recipe for|^How to make|^[\d\.\-\*]+\s*', caseSensitive: false), '');
      info['dishName'] = firstLine;
    }
    
    // Look for cuisine type in the recipe
    final cuisineKeywords = ['cuisine', 'style', 'type', 'traditional', 'authentic'];
    for (String line in lines) {
      final lowerLine = line.toLowerCase();
      for (String keyword in cuisineKeywords) {
        if (lowerLine.contains(keyword)) {
          // Extract potential cuisine info
          info['cuisine'] = line;
          break;
        }
      }
      if (info.containsKey('cuisine')) break;
    }
    
    return info;
  }

  Future<void> _retryVideo() async {
    if (_videoId == null) return;
    
    setState(() {
      _isVideoLoading = true;
      _videoLoadFailed = false;
    });

    try {
      // Recreate the controller
      _youtubeController?.dispose();
      
      _youtubeController = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _isVideoLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _videoLoadFailed = true;
        });
      }
    }
  }

  Future<void> _saveRecipe() async {
    try {

      // Extract a better title for saving
      final recipeInfo = _extractRecipeInfo(recipe);
      final title = recipeInfo['dishName'] ?? "Generated Recipe";
      
      await FirestoreService().saveRecipe(
        userId: userId,
        title: title,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          "Recipe Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 3,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🧡 Recipe Text
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        recipe,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🎥 YouTube Player Section
                  if (_videoId != null) ...[
                    const Text(
                      "Watch Recipe Tutorial:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),

                    
                    // Video loading state
                    if (_isVideoLoading)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.orange),
                              SizedBox(height: 10),
                              Text('Loading video...'),
                            ],
                          ),
                        ),
                      )
                    else if (_videoLoadFailed)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 40),
                              const SizedBox(height: 10),
                              const Text('Failed to load video'),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: _retryVideo,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry Video'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_youtubeController != null)
                      YoutubePlayerBuilder(
                        player: YoutubePlayer(
                          controller: _youtubeController!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: Colors.orange,
                          onReady: () {
                            print("✅ YouTube player is ready");
                          },
                          onEnded: (error) {
                            print("❌ YouTube player error: $error");
                            if (mounted) {
                              setState(() {
                                _videoLoadFailed = true;
                              });
                            }
                          },
                        ),
                        builder: (context, player) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: player,
                        ),
                      ),
                  ] else ...[
                    // No video available
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No tutorial video available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveRecipe,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.history),
        label: const Text("Save to history"),
      ),
    );
  }

}
