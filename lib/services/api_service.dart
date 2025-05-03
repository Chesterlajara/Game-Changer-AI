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
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // For Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // For web or iOS simulator
  
  // Get all games (today, upcoming, live)
  static Future<List<Game>> getGames() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/games'));
      
      if (response.statusCode == 200) {
        final List<dynamic> gamesJson = json.decode(response.body);
        return gamesJson.map((gameJson) => _parseGame(gameJson)).toList();
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
      final response = await http.get(Uri.parse('$baseUrl/games/$gameId/analysis'));
      
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
  
  // Get team statistics
  static Future<Map<String, dynamic>> getTeamStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/teams/stats'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
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
    return Game(
      team1Name: json['team1']['name'],
      team1LogoPath: json['team1']['logo_path'],
      team1WinProbability: json['team1']['win_probability'].toDouble(),
      team2Name: json['team2']['name'],
      team2LogoPath: json['team2']['logo_path'],
      team2WinProbability: json['team2']['win_probability'].toDouble(),
      status: _parseGameStatus(json['status']),
      gameDate: DateTime.parse(json['game_date']),
      location: json['location'],
      gameTime: json['game_time'] != null 
          ? TimeOfDay(
              hour: int.parse(json['game_time'].split(':')[0]),
              minute: int.parse(json['game_time'].split(':')[1])
            ) 
          : null,
    );
  }
  
  // Helper method to parse game status
  static GameStatus _parseGameStatus(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return GameStatus.live;
      case 'upcoming':
        return GameStatus.upcoming;
      case 'today':
      default:
        return GameStatus.today;
    }
  }
}
