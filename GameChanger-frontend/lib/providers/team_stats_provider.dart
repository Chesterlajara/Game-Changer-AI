import 'package:flutter/material.dart';
import 'package:game_changer_ai/services/api_service.dart';
import 'package:logging/logging.dart';

class TeamStatsProvider extends ChangeNotifier {
  final Logger _log = Logger('TeamStatsProvider');
  
  Map<String, dynamic> _teamStats = {};
  bool _isLoading = false;
  String? _error;
  String _currentConference = 'All'; // Track current conference filter
  
  // Getters
  Map<String, dynamic> get teamStats => _teamStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentConference => _currentConference;
  
  // Get list of teams from the standings
  List<dynamic> get teams {
    if (_teamStats.containsKey('standings')) {
      return _teamStats['standings'] ?? [];
    }
    return [];
  }
  
  // Get season information
  String get season {
    return _teamStats['season'] ?? '2024-25';
  }
  
  // Get standings date
  String get standingsDate {
    return _teamStats['standings_date'] ?? '';
  }
  
  // Fetch team statistics from the API with optional conference filter
  Future<void> fetchTeamStats({String conference = 'All'}) async {
    _log.info('Fetching team stats with conference filter: $conference');
    _isLoading = true;
    _error = null;
    _currentConference = conference;
    notifyListeners();
    
    try {
      // Pass the conference parameter directly to the API service
      // The StatsPage has already converted 'Eastern' to 'East' and 'Western' to 'West'
      _log.info('TeamStatsProvider: Passing conference parameter directly: "$conference"');
      
      final stats = await ApiService.getTeamStats(conference: conference);
      _teamStats = stats;
      _log.info('Received ${teams.length} teams for $conference conference');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _log.severe('Error fetching team stats: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
