import 'package:flutter/material.dart';
import 'package:game_changer_ai/services/api_service.dart';
import 'package:logging/logging.dart';

class TeamStatsProvider extends ChangeNotifier {
  final Logger _log = Logger('TeamStatsProvider');
  
  Map<String, dynamic> _teamStats = {};
  Map<String, dynamic> _playerStats = {};
  bool _isLoading = false;
  String? _error;
  String _currentConference = 'All'; // Track current conference filter
  String _currentStatCategory = 'PTS'; // Track current stat category filter
  bool _showingPlayers = false; // Track whether showing teams or players
  
  // Getters
  Map<String, dynamic> get teamStats => _teamStats;
  Map<String, dynamic> get playerStats => _playerStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentConference => _currentConference;
  String get currentStatCategory => _currentStatCategory;
  bool get showingPlayers => _showingPlayers;
  
  // Get list of teams from the standings
  List<dynamic> get teams {
    if (_teamStats.containsKey('standings')) {
      return _teamStats['standings'] ?? [];
    }
    return [];
  }
  
  // Get list of players from the standings
  List<dynamic> get players {
    if (_playerStats.containsKey('standings')) {
      return _playerStats['standings'] ?? [];
    }
    return [];
  }
  
  // Get current standings data based on whether showing teams or players
  List<dynamic> get currentStandings {
    return _showingPlayers ? players : teams;
  }
  
  // Get season information
  String get season {
    return _showingPlayers ? 
      (_playerStats['season'] ?? '2024-25') : 
      (_teamStats['season'] ?? '2024-25');
  }
  
  // Get standings date
  String get standingsDate {
    return _showingPlayers ? 
      (_playerStats['standings_date'] ?? '') : 
      (_teamStats['standings_date'] ?? '');
  }
  
  // Fetch team statistics from the API with optional conference filter
  Future<void> fetchTeamStats({String conference = 'All'}) async {
    _log.info('Fetching team stats with conference filter: $conference');
    _isLoading = true;
    _error = null;
    _currentConference = conference;
    _showingPlayers = false;
    notifyListeners();
    
    try {
      final stats = await ApiService.getTeamStats(conference: conference);
      _log.info('Received team stats: ${stats.keys}');
      _log.info('Number of teams: ${stats['standings']?.length ?? 0}');
      _teamStats = stats;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _log.severe('Error fetching team stats: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch player statistics from the API with optional conference filter
  Future<void> fetchPlayerStats({String conference = 'All', String statCategory = 'PTS'}) async {
    _log.info('Fetching player stats with conference filter: $conference, stat category: $statCategory');
    _isLoading = true;
    _error = null;
    _currentConference = conference;
    _currentStatCategory = statCategory;
    _showingPlayers = true;
    notifyListeners();
    
    try {
      final stats = await ApiService.getPlayerStats(conference: conference, statCategory: statCategory);
      _log.info('Received player stats: ${stats.keys}');
      _log.info('Number of players: ${stats['standings']?.length ?? 0}');
      _playerStats = stats;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _log.severe('Error fetching player stats: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Toggle between team and player stats
  void toggleStatsType(bool showPlayers) {
    if (_showingPlayers != showPlayers) {
      _showingPlayers = showPlayers;
      if (showPlayers) {
        fetchPlayerStats(conference: _currentConference, statCategory: _currentStatCategory);
      } else {
        fetchTeamStats(conference: _currentConference);
      }
    }
  }
}
