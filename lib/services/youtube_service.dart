import 'dart:convert';
import 'package:http/http.dart' as http;

class YoutubeService {
  static const String _apiKey = "AIzaSyDxQD_HBdlBls0Yr8LquBcYlB4H9nruUqQ";

  static Future<String?> getFirstVideoId(String query) async {
    final url  = Uri.parse(
            'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&key=$_apiKey&maxResults=1',
    );

    final response = await http.get(url);

    if (response.statusCode == 200){
      final data = json.decode(response.body);
      if (data['items'] != null && data ['items'].length > 0){
        return data ['items'][0]['id']['VideoId'];
      }
    }
    return null;
  }
}