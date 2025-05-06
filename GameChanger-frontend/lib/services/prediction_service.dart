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

  // Method to predict with player availability consideration


  // Method to predict winner considering both player availability and performance factors
  static Future<Map<String, dynamic>> predictWithPerformanceFactors({
    required String team1,
    required String team2,
    Map<String, bool> playerAvailability = const {},
    Map<String, dynamic> performanceFactors = const {},
  }) async {
    // Log the input data for debugging
    print('Sending predict-with-performance-factors request:');
    print('team1: $team1, team2: $team2');
    print('inactive_players: $playerAvailability');
    print('performance_factors: $performanceFactors');

    // Convert player impacts for sending to backend
    final convertedPlayerImpacts = {};
    
    // This is the key change - we need to identify which players are INACTIVE
    // The frontend uses isActive = true for active players
    // The backend expects is_inactive = true for inactive players
    // So we need to invert the boolean when sending to backend
    Map<String, bool> inactivePlayers = {};
    playerAvailability.forEach((player, isActive) {
      // Send the player as inactive (true) if they are not active (false) in the frontend
      inactivePlayers[player] = !isActive;
    });
    
    print('FIXED inactive_players format: $inactivePlayers');

    try {
      final response = await http.post(Uri.parse('$baseUrl/predict-with-performance-factors'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'team1': team1,
            'team2': team2,
            'inactive_players': inactivePlayers,
            'performance_factors': performanceFactors,
            'player_impacts': convertedPlayerImpacts,
          }));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Got prediction result with performance factors: $data');
        final winner = data['winner'];
        final team1WinProb = data['team1_win_prob'];
        final team2WinProb = data['team2_win_prob'];
        
        // Safely convert player impacts to Map<String, dynamic>
        Map<String, dynamic> playerImpacts = {};
        if (data['player_impacts'] != null) {
          final impacts = data['player_impacts'];
          impacts.forEach((key, value) {
            // Ensure keys are strings and values are properly typed
            playerImpacts[key.toString()] = value is num ? value.toDouble() : value.toString();
          });
        }
        
        // Safely convert performance factors to Map<String, dynamic>
        Map<String, dynamic> factorsData = {};
        if (data['performance_factors'] != null) {
          final factors = data['performance_factors'];
          factors.forEach((key, value) {
            factorsData[key.toString()] = value;
          });
        }
        
        print('Performance factors data: $factorsData'); // Debug log

        return {
          'winner': winner,
          'team1_win_prob': team1WinProb,
          'team2_win_prob': team2WinProb,
          'player_impacts': playerImpacts,
          'performance_factors': factorsData,
        };
      } else {
        throw Exception('Failed to load prediction with performance factors');
      }
    } catch (e) {
      print('Error in predictWithPerformanceFactors: $e');
      return {
        'winner': team1,
        'team1_win_prob': 0.5,
        'team2_win_prob': 0.5,
        'player_impacts': {},
        'performance_factors': {}
      };
    }
  }
}
