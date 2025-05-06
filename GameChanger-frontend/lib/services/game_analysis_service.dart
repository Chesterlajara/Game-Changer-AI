import 'dart:convert';
import 'package:http/http.dart' as http;

class GameAnalysisService {
  static const String baseUrl = 'http://localhost:5000'; // Flask server

  // Fetch game analysis including team stats and player impacts from CSV data
  static Future<Map<String, dynamic>> getGameAnalysis(String gameId) async {
    try {
      print('Fetching game analysis for gameId: $gameId');
      final url = '$baseUrl/api/game-analysis/$gameId';
      print('API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('Raw response body: ${response.body.substring(0, min(100, response.body.length))}...');
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('Game analysis data received with keys: ${data.keys.toList()}');
        
        // Validate expected structure
        if (data.containsKey('team1_name')) {
          print('Found team1_name: ${data["team1_name"]}');
        } else {
          print('WARNING: team1_name not found in response');
        }
        
        if (data.containsKey('team1_players')) {
          print('Found team1_players with ${(data["team1_players"] as List?)?.length ?? 0} items');
        } else {
          print('WARNING: team1_players not found in response');
        }
        
        return data;
      } else {
        print('Error fetching game analysis: ${response.statusCode}');
        print('Response body: ${response.body}');
        
        // Return empty object if the request fails
        return {};
      }
    } catch (e, stackTrace) {
      print('Exception in getGameAnalysis: $e');
      print('Stack trace: $stackTrace');
      return {};
    }
  }
  
  // Helper function to get min of two numbers
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
