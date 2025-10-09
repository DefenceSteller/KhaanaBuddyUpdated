import 'dart:convert';
import 'package:http/http.dart' as http;

class YoutubeService {
  static const String _apiKey = "AIzaSyDxQD_HBdlBls0Yr8LquBcYlB4H9nruUqQ";

  static Future<String?> getFirstVideoId(String query) async {

    final cleanQuery = _formatSearchQuery(query);
    
    final url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet&q=$cleanQuery&type=video&maxResults=5&key=$_apiKey',
    );

    print("🎥 Fetching YouTube video for: $cleanQuery");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] != null && data['items'].isNotEmpty) {
          final videoId = _findBestMatch(data['items'], query, cleanQuery);
          print("✅ Found videoId: $videoId");
          return videoId;
        } else {
          print("⚠️ No videos found for query: $cleanQuery");
          return null;
        }
      } else {
        print("❌ YouTube API error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("🚨 Error fetching YouTube video: $e");
      return null;
    }
  }

  static String _formatSearchQuery(String query) {
    // Remove generic prefixes and make query more specific
    String formattedQuery = query
        .replaceAll(RegExp(r'how to make|recipe|tutorial|easy|simple|step by step', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
    
    // Add specific cooking keywords for better results
    formattedQuery = '$formattedQuery authentic recipe cooking tutorial';
    
    // URL encode the query
    return Uri.encodeComponent(formattedQuery);
  }

  static String? _findBestMatch(List<dynamic> items, String originalQuery, String formattedQuery) {
    final originalWords = originalQuery.toLowerCase().split(' ').where((word) => word.length > 3).toList();
    final formattedWords = formattedQuery.toLowerCase().split(' ').where((word) => word.length > 3).toList();
    
    final List<Map<String, dynamic>> scoredVideos = [];
    
    for (var item in items) {
      final title = item['snippet']['title'].toString().toLowerCase();
      final description = item['snippet']['description'].toString().toLowerCase();
      
      int score = 0;
      
      // Score based on original query words
      for (String word in originalWords) {
        if (title.contains(word)) score += 3;
        if (description.contains(word)) score += 1;
      }
      
      // Score based on formatted query words
      for (String word in formattedWords) {
        if (title.contains(word)) score += 2;
        if (description.contains(word)) score += 1;
      }
      
      // Bonus points for cooking-related terms
      if (title.contains('recipe') || title.contains('cook') || title.contains('make')) score += 2;
      
      // Penalize unrelated content
      if (title.contains('unboxing') || title.contains('review') || title.contains('vlog')) score -= 5;
      
      scoredVideos.add({
        'videoId': item['id']['videoId'],
        'score': score,
        'title': item['snippet']['title']
      });
    }
    
    // Sort by score and return the best match
    scoredVideos.sort((a, b) => b['score'].compareTo(a['score']));
    
    if (scoredVideos.isNotEmpty) {
      final bestMatch = scoredVideos.first;
      print("🏆 Best match: '${bestMatch['title']}' with score ${bestMatch['score']}");
      return bestMatch['videoId'];
    }
    
    return null;
  }
}