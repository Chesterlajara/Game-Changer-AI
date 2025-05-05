import 'dart:convert';
import 'package:http/http.dart' as http;

class PredictionService {
  // Base URL for the API
  static const String baseUrl = 'http://localhost:5000'; // Assuming Flask runs on port 5000

  // Method to predict the winner of a match
  static Future<Map<String, dynamic>> predictWinner(String team1, String team2) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'team1': team1,
          'team2': team2,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return default values if the request fails
        return {
          'winner': 'Unknown',
          'team1_win_prob': 0.5,
          'team2_win_prob': 0.5,
        };
      }
    } catch (e) {
      print('Error predicting winner: $e');
      // Return default values if an exception occurs
      return {
        'winner': 'Unknown',
        'team1_win_prob': 0.5,
        'team2_win_prob': 0.5,
      };
    }
  }
  
  // Method to predict with player availability consideration
  static Future<Map<String, dynamic>> predictWithPlayerAvailability(
    String team1, 
    String team2, 
    Map<String, bool> playerAdjustments
  ) async {
    try {
      // Convert player adjustments to inactive players list
      Map<String, bool> inactivePlayers = {};
      playerAdjustments.forEach((player, isActive) {
        inactivePlayers[player] = !isActive; // Invert: false means inactive
      });
      
      print('Calling predict-with-player-availability with: $team1, $team2, inactive: $inactivePlayers');
      
      final response = await http.post(
        Uri.parse('$baseUrl/predict-with-player-availability'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'team1': team1,
          'team2': team2,
          'inactive_players': inactivePlayers,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Prediction response with player availability: $data');
        return data;
      } else {
        print('Error with predict-with-player-availability: ${response.statusCode} - ${response.body}');
        // Return default values if the request fails
        return {
          'winner': 'Unknown',
          'team1_win_prob': 0.5,
          'team2_win_prob': 0.5,
          'player_impacts': {},
        };
      }
    } catch (e) {
      print('Error predicting with player availability: $e');
      // Return default values if an exception occurs
      return {
        'winner': 'Unknown',
        'team1_win_prob': 0.5,
        'team2_win_prob': 0.5,
        'player_impacts': {},
      };
    }
  }
}
