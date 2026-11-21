import 'dart:convert';
import 'package:http/http.dart' as http;

class YoutubeService {
  static const String _apiKey = "AIzaSyDxQD_HBdlBls0Yr8LquBcYlB4H9nruUqQ";

  // Words that strongly indicate a cooking video
  static const List<String> _cookingTerms = [
    'recipe', 'cooking', 'cook', 'kitchen', 'how to make', 'how to cook',
    'tutorial', 'ingredients', 'homemade', 'chef', 'food', 'prepare',
    'bake', 'baking', 'fry', 'frying', 'grill', 'simmer', 'boil', 'roast',
    'dish', 'cuisine', 'meal', 'dinner', 'lunch', 'breakfast', 'dessert',
    'step by step', 'easy recipe', 'in minutes', 'parsi', 'curry', 'spice',
  ];

  // Words that strongly indicate non-cooking content (dramas, music, etc.)
  static const List<String> _offTopicTerms = [
    'drama', 'episode', 'ep ', 'series', 'season', 'movie', 'film',
    'trailer', 'official video', 'music video', 'lyrics', 'song', 'reaction',
    'interview', 'vlog', 'gaming', 'gameplay', 'news', 'sports', 'highlight',
    'unboxing', 'review', 'shorts', 'cartoon', 'animation', 'documentary',
    'talk show', 'comedy', 'full album', 'behind the scenes', 'teaser',
    'subtitles', 'dubbed', 'clip', 'live', 'performance',
  ];

  static Future<String?> getFirstVideoId(String query) async {
    final cleanQuery = _formatSearchQuery(query);

    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet&q=$cleanQuery&type=video&maxResults=10'
      '&relevanceLanguage=en&safeSearch=strict&key=$_apiKey',
    );

    print("🎥 Fetching YouTube video for: $cleanQuery");

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        print("❌ YouTube API error: ${response.statusCode} - ${response.body}");
        return null;
      }

      final data = json.decode(response.body);
      final items = List<dynamic>.from(data['items'] ?? []);

      if (items.isEmpty) {
        print("⚠️ No videos found for query: $cleanQuery");
        return null;
      }

      // Step 1: score candidates (keeps recipe-related, drops off-topic ones)
      final ranked = _scoreVideos(items, query);
      if (ranked.isEmpty) {
        print("⚠️ No recipe-related videos matched — skipping video section");
        return null;
      }

      // Step 2: verify the top candidates against real video metadata
      // (duration + category) so a drama/long-form show never wins.
      final videoId = await _verifyCandidates(ranked.take(5).toList());
      if (videoId != null) {
        print("✅ Found videoId: $videoId");
      } else {
        print("⚠️ No relevant cooking video after verification");
      }
      return videoId;
    } catch (e) {
      print("🚨 Error fetching YouTube video: $e");
      return null;
    }
  }

  static String _formatSearchQuery(String query) {
    // Keep the dish name AND the recipe words — they are what make the
    // results recipe-related. Only clean up stray punctuation/whitespace.
    String formattedQuery = query
        .replaceAll(RegExp(r'[^\w\s&-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Make sure cooking keywords are present exactly once
    final lower = formattedQuery.toLowerCase();
    if (!lower.contains('recipe')) formattedQuery = '$formattedQuery recipe';
    if (!lower.contains('cook')) formattedQuery = '$formattedQuery cooking tutorial';

    return Uri.encodeComponent(formattedQuery);
  }

  /// Titles written in CJK / Japanese scripts are irrelevant for this
  /// English app (this is what let the Chinese drama through before).
  static final RegExp _nonLatinTitle =
      RegExp(r'[\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF\u0600-\u06FF]');

  static List<Map<String, dynamic>> _scoreVideos(
      List<dynamic> items, String originalQuery) {
    final originalWords = originalQuery
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3)
        .toList();

    final List<Map<String, dynamic>> scoredVideos = [];

    for (var item in items) {
      final videoId = item['id']?['videoId'];
      if (videoId == null) continue;

      final snippet = item['snippet'];
      final title = snippet['title'].toString().toLowerCase();
      final description = snippet['description'].toString().toLowerCase();
      final channel = snippet['channelTitle'].toString().toLowerCase();

      // Hard reject: non-Latin title (foreign drama/show)
      if (_nonLatinTitle.hasMatch(title)) continue;

      int score = 0;

      // Score based on the dish name / query words
      for (String word in originalWords) {
        if (title.contains(word)) score += 4;
        if (description.contains(word)) score += 1;
      }

      // Bonus for cooking-related terms
      bool cookingInTitle = false;
      for (String term in _cookingTerms) {
        if (title.contains(term)) {
          score += 3;
          cookingInTitle = true;
        } else if (description.contains(term)) {
          score += 1;
        }
      }

      // Cooking channels get a boost
      if (channel.contains('cook') ||
          channel.contains('kitchen') ||
          channel.contains('food') ||
          channel.contains('recipe') ||
          channel.contains('chef')) {
        score += 3;
      }

      // Heavy penalty for non-cooking content
      for (String term in _offTopicTerms) {
        if (title.contains(term)) score -= 10;
        if (description.contains(term)) score -= 3;
      }

      // A video whose title says nothing about cooking must be clearly
      // a dish-name match to survive — otherwise it is dropped entirely.
      if (!cookingInTitle && score < 14) continue;

      scoredVideos.add({
        'videoId': videoId,
        'score': score,
        'title': snippet['title'],
      });
    }

    scoredVideos.sort((a, b) => b['score'].compareTo(a['score']));

    for (final v in scoredVideos) {
      print("📊 '${v['title']}' → score ${v['score']}");
    }

    return scoredVideos;
  }

  /// Confirms candidates with the videos endpoint (duration + category).
  /// Recipe videos are ~2-40 min and usually category 26 (Howto & Style).
  static Future<String?> _verifyCandidates(
      List<Map<String, dynamic>> candidates) async {
    if (candidates.isEmpty) return null;

    final ids = candidates.map((c) => c['videoId']).join(',');
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/videos'
      '?part=snippet,contentDetails&id=$ids&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        // Metadata call failed — fall back to the best scored candidate
        return candidates.first['videoId'] as String?;
      }

      final data = json.decode(response.body);
      final details = <String, dynamic>{
        for (var v in (data['items'] as List<dynamic>? ?? []))
          v['id'].toString(): v
      };

      for (final candidate in candidates) {
        final detail = details[candidate['videoId']];
        if (detail == null) continue;

        final duration =
            _parseDuration(detail['contentDetails']?['duration']?.toString());
        if (duration == null) continue;
        if (duration.inMinutes < 1 || duration.inMinutes > 40) continue;

        final title = detail['snippet']?['title'].toString().toLowerCase() ?? '';
        final categoryId = detail['snippet']?['categoryId']?.toString() ?? '';

        // Skip anything that still looks like a show/drama/music video
        if (_nonLatinTitle.hasMatch(title)) continue;
        if (_offTopicTerms.any((term) => title.contains(term))) continue;

        final cookingInTitle = _cookingTerms.any((term) => title.contains(term));

        // Prefer Howto & Style (26) or a title that clearly says cooking
        if (categoryId == '26' || cookingInTitle) {
          print("🎯 Verified: '${detail['snippet']['title']}' "
              "(${duration.inMinutes} min, category $categoryId)");
          return candidate['videoId'] as String?;
        }
      }

      // Nothing verified as a cooking video — show "no tutorial" instead
      // of an irrelevant video.
      return null;
    } catch (e) {
      print("⚠️ Verification failed: $e — using best scored candidate");
      return candidates.isNotEmpty ? candidates.first['videoId'] as String? : null;
    }
  }

  static Duration? _parseDuration(String? iso) {
    if (iso == null) return null;
    final match =
        RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(iso);
    if (match == null) return null;
    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '') ?? 0;
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }
}
