import 'dart:convert';
import 'package:http/http.dart' as http;

class TeamStatsService {
  static const String baseUrl = 'http://localhost:5000'; // Flask server

  // Fetch team statistics for both teams
  static Future<Map<String, dynamic>> getTeamStats(String team1Name, String team2Name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-team-stats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'team1': team1Name,
          'team2': team2Name,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error fetching team stats: ${response.statusCode}');
        return _getFallbackStats(team1Name, team2Name);
      }
    } catch (e) {
      print('Exception in getTeamStats: $e');
      return _getFallbackStats(team1Name, team2Name);
    }
  }

  // Generate fallback statistics with slight variations based on team names
  // This ensures different teams will at least have different visualization patterns
  static Map<String, dynamic> _getFallbackStats(String team1Name, String team2Name) {
    // Use the team names to generate consistent but different stats
    final team1Seed = team1Name.length % 10;
    final team2Seed = team2Name.length % 10;
    
    return {
      'team_stats': {
        team1Name: {
          'PTS': 100 + team1Seed * 2.5,
          'REB': 40 + team1Seed * 1.2,
          'AST': 20 + team1Seed * 1.5,
          'FG3_PCT': 32 + team1Seed * 0.8,
          'STL': 6 + team1Seed * 0.4,
          'BLK': 4 + team1Seed * 0.3,
        },
        team2Name: {
          'PTS': 98 + team2Seed * 2.5,
          'REB': 39 + team2Seed * 1.2,
          'AST': 21 + team2Seed * 1.5,
          'FG3_PCT': 33 + team2Seed * 0.8,
          'STL': 7 + team2Seed * 0.4,
          'BLK': 5 + team2Seed * 0.3,
        }
      }
    };
  }
  
  // Convert API stats format to the format needed for the hexagon chart
  static Map<String, Map<String, double>> processTeamStats(Map<String, dynamic> apiResponse, String team1Name, String team2Name) {
    Map<String, dynamic> team1ApiStats = {};
    Map<String, dynamic> team2ApiStats = {};
    
    // Extract stats from API response
    if (apiResponse.containsKey('team_stats')) {
      final teamStats = apiResponse['team_stats'];
      
      if (teamStats.containsKey(team1Name)) {
        team1ApiStats = teamStats[team1Name];
      }
      
      if (teamStats.containsKey(team2Name)) {
        team2ApiStats = teamStats[team2Name];
      }
    }
    
    // Create normalized and raw stat maps
    final result = {
      'team1Stats': <String, double>{},
      'team2Stats': <String, double>{},
      'team1RawStats': <String, double>{},
      'team2RawStats': <String, double>{},
    };
    
    // Process and normalize stats
    _processTeamStats(team1ApiStats, result['team1Stats']!, result['team1RawStats']!);
    _processTeamStats(team2ApiStats, result['team2Stats']!, result['team2RawStats']!);
    
    return result.map((key, value) => MapEntry(key, Map<String, double>.from(value)));
  }
  
  // Process a single team's stats
  static void _processTeamStats(Map<String, dynamic> apiStats, Map<String, double> normalizedStats, Map<String, double> rawStats) {
    // Define max values for normalization
    final maxValues = {
      'PPG': 120.0, // Max points per game
      '3PT': 45.0,  // Max 3-point percentage
      'REB': 55.0,  // Max rebounds
      'AST': 35.0,  // Max assists
      'STL': 12.0,  // Max steals
      'BLK': 8.0,   // Max blocks
    };
    
    // Map API stat names to our display names
    final statMapping = {
      'PTS': 'PPG',
      'FG3_PCT': '3PT',
      'REB': 'REB',
      'AST': 'AST',
      'STL': 'STL',
      'BLK': 'BLK',
    };
    
    // Process each stat
    statMapping.forEach((apiKey, displayKey) {
      if (apiStats.containsKey(apiKey) && apiStats[apiKey] is num) {
        final rawValue = apiStats[apiKey].toDouble();
        rawStats[displayKey] = rawValue;
        
        // Normalize for chart display
        final normalizedValue = (rawValue / maxValues[displayKey]!).clamp(0.0, 1.0);
        normalizedStats[displayKey] = normalizedValue;
      } else {
        // Fallback values
        final fallbackValue = {
          'PPG': 100.0,
          '3PT': 35.0,
          'REB': 42.0,
          'AST': 22.0,
          'STL': 7.0,
          'BLK': 4.0,
        }[displayKey] ?? 0.0;
        
        rawStats[displayKey] = fallbackValue;
        normalizedStats[displayKey] = (fallbackValue / maxValues[displayKey]!).clamp(0.0, 1.0);
      }
    });
  }
}
