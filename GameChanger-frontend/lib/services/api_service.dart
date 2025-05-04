import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:game_changer_ai/models/game_model.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class ApiService {
  static final Logger _log = Logger('ApiService');
  
  // Base URL for your Flask backend
  // For local development, use your machine's IP address instead of localhost
  // when testing on a physical device
  // static const String baseUrl = 'http://192.168.68.103:5000/api'; // Your computer's IP address
  static const String baseUrl = 'http://localhost:5000/api'; // For web or iOS simulator
  
  // Get all games (today, upcoming, live)
  static Future<List<Game>> getGames() async {
    try {
      _log.info('Fetching games from $baseUrl/games');
      final response = await http.get(Uri.parse('$baseUrl/games'));
      
      if (response.statusCode == 200) {
        _log.info('Response received: ${response.body}');
        
        // We'll use the real API data instead of placeholder games
        
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          _log.info('Parsed response data: $responseData');
          
          // Check if the response has categories (today, upcoming, live)
          if (responseData.containsKey('today') || 
              responseData.containsKey('upcoming') || 
              responseData.containsKey('live')) {
            // Combine all categories into a single list
            List<Game> allGames = [];
            
            if (responseData.containsKey('today')) {
              final List<dynamic> todayGames = responseData['today'];
              _log.info('Today games: $todayGames');
              allGames.addAll(todayGames.map((gameJson) => _parseGame(gameJson)).toList());
            }
            
            if (responseData.containsKey('upcoming')) {
              final List<dynamic> upcomingGames = responseData['upcoming'];
              _log.info('Upcoming games: $upcomingGames');
              allGames.addAll(upcomingGames.map((gameJson) => _parseGame(gameJson)).toList());
            }
            
            if (responseData.containsKey('live')) {
              final List<dynamic> liveGames = responseData['live'];
              _log.info('Live games: $liveGames');
              allGames.addAll(liveGames.map((gameJson) => _parseGame(gameJson)).toList());
            }
            
            if (allGames.isEmpty) {
              _log.warning('No games found in API response');
              return [];
            }
            
            return allGames;
          } else if (responseData.containsKey('games')) {
            // If the response has a 'games' key
            final List<dynamic> gamesJson = responseData['games'];
            _log.info('Games from games key: $gamesJson');
            return gamesJson.map((gameJson) => _parseGame(gameJson)).toList();
          } else {
            // Try to parse as a direct list
            try {
              _log.info('Trying to parse as direct list');
              final List<dynamic> gamesJson = json.decode(response.body);
              return gamesJson.map((gameJson) => _parseGame(gameJson)).toList();
            } catch (e) {
              _log.severe('Error parsing games JSON: $e');
              throw Exception('Error parsing games JSON: $e');
            }
          }
        } catch (e) {
          _log.severe('Error processing response: $e');
          throw Exception('Error processing response: $e');
        }
      } else {
        _log.warning('Failed to load games: ${response.statusCode}');
        throw Exception('Failed to load games');
      }
    } catch (e) {
      _log.severe('Error fetching games: $e');
      throw Exception('Error fetching games: $e');
    }
  }
  
  // Get game analysis for a specific game
  static Future<Map<String, dynamic>> getGameAnalysis(String gameId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/game-analysis/$gameId'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _log.warning('Failed to load game analysis: ${response.statusCode}');
        throw Exception('Failed to load game analysis');
      }
    } catch (e) {
      _log.severe('Error fetching game analysis: $e');
      throw Exception('Error fetching game analysis: $e');
    }
  }
  
  // Get team statistics with optional conference filter
  static Future<Map<String, dynamic>> getTeamStats({String conference = ''}) async {
    try {
      // Build URL with conference parameter if provided
      String url = '$baseUrl/team-standings';
      
      // Create query parameters map
      Map<String, String> queryParams = {};
      if (conference.isNotEmpty) {
        queryParams['conference'] = conference;
      }
      
      // Build URI with query parameters
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      
      _log.info('Fetching team stats from: $uri');
      _log.info('Conference parameter value: "$conference"');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log.info('Received team stats with ${data['standings']?.length ?? 0} teams');
        return data;
      } else {
        _log.warning('Failed to load team stats: ${response.statusCode}');
        throw Exception('Failed to load team stats');
      }
    } catch (e) {
      _log.severe('Error fetching team stats: $e');
      throw Exception('Error fetching team stats: $e');
    }
  }
  
  // Helper method to parse Game object from JSON
  static Game _parseGame(Map<String, dynamic> json) {
    // Log the JSON to debug
    _log.info('Parsing game JSON: $json');
    
    try {
      // Check if the JSON has the expected structure
      if (json == null) {
        throw Exception('JSON is null');
      }
      
      // Extract home and away team data with null safety
      final homeTeam = json['home_team'] as Map<String, dynamic>? ?? {};
      final awayTeam = json['away_team'] as Map<String, dynamic>? ?? {};
      
      // Extract prediction data if available
      final prediction = json['prediction'] as Map<String, dynamic>? ?? {};
      
      // Parse start time
      DateTime gameDate;
      try {
        gameDate = json['start_time'] != null 
            ? DateTime.parse(json['start_time'].toString()) 
            : DateTime.now();
      } catch (e) {
        // Fallback to current date if parsing fails
        gameDate = DateTime.now();
        _log.warning('Failed to parse game date: $e');
      }
      
      // SIMPLE CATEGORIZATION LOGIC:
      // 1. Today Tab: start_time == current time (same day)
      // 2. Upcoming Tab: start_time > current time (future date)
      // 3. Live Tab: status == LIVE
      
      GameStatus gameStatus;
      final String statusStr = json['status']?.toString().toLowerCase() ?? '';
      
      // Get current date (just year, month, day)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final gameDay = DateTime(gameDate.year, gameDate.month, gameDate.day);
      
      // Apply the exact categorization logic requested
      if (statusStr == 'live') {
        // Rule 3: Live Tab: status == LIVE
        gameStatus = GameStatus.live;
      } else if (gameDay.isAtSameMomentAs(today)) {
        // Rule 1: Today Tab: start_time == current time (same day)
        gameStatus = GameStatus.today;
      } else if (gameDay.isAfter(today)) {
        // Rule 2: Upcoming Tab: start_time > current time (future date)
        gameStatus = GameStatus.upcoming;
      } else {
        // Default fallback for past games
        gameStatus = GameStatus.today;
      }
      
      _log.info('Game ${homeTeam['name']} vs ${awayTeam['name']} status: $gameStatus (original: $statusStr, date: $gameDate)');
      
      // Create game object with null safety
      return Game(
        team1Name: homeTeam['name']?.toString() ?? 'Team 1',
        team1LogoPath: homeTeam['logo_url']?.toString() ?? '',
        team1WinProbability: prediction['home_win_probability'] != null 
            ? (prediction['home_win_probability'] as num).toDouble() 
            : 0.5,
        team2Name: awayTeam['name']?.toString() ?? 'Team 2',
        team2LogoPath: awayTeam['logo_url']?.toString() ?? '',
        team2WinProbability: prediction['away_win_probability'] != null 
            ? (prediction['away_win_probability'] as num).toDouble() 
            : 0.5,
        status: gameStatus,
        gameDate: gameDate,
        location: json['location']?.toString() ?? 'TBD',
        gameTime: gameDate != null ? TimeOfDay(hour: gameDate.hour, minute: gameDate.minute) : null,
      );
    } catch (e) {
      _log.severe('Error parsing game: $e');
      // Return a placeholder game to avoid crashing
      return Game(
        team1Name: 'Error',
        team1LogoPath: '',
        team1WinProbability: 0.5,
        team2Name: 'Error',
        team2LogoPath: '',
        team2WinProbability: 0.5,
        status: GameStatus.today,
        gameDate: DateTime.now(),
        location: 'Error',
      );
    }
  }
  
  // Helper method to parse game status
  static GameStatus _parseGameStatus(String status) {
    _log.info('Parsing game status: $status');
    
    final String lowercaseStatus = status.toLowerCase();
    
    if (lowercaseStatus == 'live') {
      return GameStatus.live;
    } else if (lowercaseStatus == 'upcoming') {
      return GameStatus.upcoming;
    } else if (lowercaseStatus == 'scheduled') {
      // Check if the game is scheduled for today or a future date
      // For now, we'll treat all SCHEDULED games as today's games
      return GameStatus.today;
    } else if (lowercaseStatus == 'today') {
      return GameStatus.today;
    } else {
      _log.warning('Unknown game status: $status, defaulting to today');
      return GameStatus.today;
    }
  }
}
