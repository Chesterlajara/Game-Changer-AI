import 'package:flutter/material.dart';
import 'package:game_changer_ai/services/api_service.dart';
import 'package:logging/logging.dart';

class TeamStatsProvider extends ChangeNotifier {
  final Logger _log = Logger('TeamStatsProvider');
  
  Map<String, dynamic> _teamStats = {};
  Map<String, dynamic> _playerStats = {};
  Map<String, dynamic> _offensiveStats = {};
  Map<String, dynamic> _defensiveStats = {};
  List<Map<String, dynamic>> _offensiveLeaders = [];
  List<Map<String, dynamic>> _defensiveLeaders = [];
  bool _isLoading = false;
  String? _error;
  String _currentConference = 'All'; // Track current conference filter
  String _currentStatCategory = 'PTS'; // Track current stat category filter
  bool _showingPlayers = false; // Track whether showing teams or players
  String _selectedSortBy = 'Win %'; // Default sort option
  String? _selectedTeam; // Selected team for offense/defense tabs
  
  // Getters
  Map<String, dynamic> get teamStats => _teamStats;
  Map<String, dynamic> get playerStats => _playerStats;
  Map<String, dynamic> get offensiveStats => _offensiveStats;
  Map<String, dynamic> get defensiveStats => _defensiveStats;
  List<Map<String, dynamic>> get offensiveLeaders => _offensiveLeaders;
  List<Map<String, dynamic>> get defensiveLeaders => _defensiveLeaders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentConference => _currentConference;
  String get currentStatCategory => _currentStatCategory;
  bool get showingPlayers => _showingPlayers;
  String? get selectedTeam => _selectedTeam;
  
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
  
  // Fetch team statistics from the API with optional conference filter and sort option
  Future<void> fetchTeamStats({String conference = 'All', String sortBy = '', bool forceRefresh = false}) async {
    // If no sort option provided, use the current one
    if (sortBy.isEmpty) {
      sortBy = _selectedSortBy;
    } else {
      _selectedSortBy = sortBy;
    }
    
    _log.info('Fetching team stats with conference filter: $conference, sort by: $sortBy, forceRefresh: $forceRefresh');
    _isLoading = true;
    _error = null;
    _currentConference = conference;
    _showingPlayers = false;
    notifyListeners();
    
    try {
      // Add a timestamp parameter to prevent caching when forceRefresh is true
      final stats = await ApiService.getTeamStats(
        conference: conference, 
        sortBy: sortBy,
        timestamp: forceRefresh ? DateTime.now().millisecondsSinceEpoch.toString() : null
      );
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
  
  // Fetch player statistics from the API with optional conference filter and sort option
  Future<void> fetchPlayerStats({String conference = 'All', String sortBy = '', bool forceRefresh = false}) async {
    // If no sort option provided, use the current one
    if (sortBy.isEmpty) {
      sortBy = _selectedSortBy;
    } else {
      _selectedSortBy = sortBy;
    }
    
    _log.info('Fetching player stats with conference filter: $conference, sort by: $sortBy, forceRefresh: $forceRefresh');
    _isLoading = true;
    _error = null;
    _currentConference = conference;
    _currentStatCategory = sortBy;
    _showingPlayers = true;
    notifyListeners();
    
    try {
      // Add a timestamp parameter to prevent caching when forceRefresh is true
      final stats = await ApiService.getPlayerStats(
        conference: conference, 
        sortBy: sortBy,
        timestamp: forceRefresh ? DateTime.now().millisecondsSinceEpoch.toString() : null
      );
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
        fetchPlayerStats(conference: _currentConference, sortBy: _currentStatCategory);
      } else {
        fetchTeamStats(conference: _currentConference);
      }
    }
  }
  
  // Set selected team for offense/defense tabs
  void setSelectedTeam(String? teamName) {
    _log.info('Setting selected team to: $teamName');
    _selectedTeam = teamName;
    notifyListeners();
  }
  
  // Fetch team offensive statistics
  Future<void> fetchTeamOffensiveStats({String conference = 'All', bool forceRefresh = false}) async {
    _log.info('Fetching team offensive stats with conference filter: $conference, forceRefresh: $forceRefresh');
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final stats = await ApiService.getTeamOffensiveStats(
        conference: conference,
        timestamp: forceRefresh ? DateTime.now().millisecondsSinceEpoch.toString() : null
      );
      _log.info('Received team offensive stats: ${stats.keys}');
      _log.info('Number of teams: ${stats['offensive_stats']?.length ?? 0}');
      _offensiveStats = stats;
      
      // Generate league leaders for different offensive categories
      _generateOffensiveLeaders();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _log.severe('Error fetching team offensive stats: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch team defensive statistics
  Future<void> fetchTeamDefensiveStats({String conference = 'All', bool forceRefresh = false}) async {
    _log.info('Fetching team defensive stats with conference filter: $conference, forceRefresh: $forceRefresh');
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final stats = await ApiService.getTeamDefensiveStats(
        conference: conference,
        timestamp: forceRefresh ? DateTime.now().millisecondsSinceEpoch.toString() : null
      );
      _log.info('Received team defensive stats: ${stats.keys}');
      _log.info('Number of teams: ${stats['defensive_stats']?.length ?? 0}');
      _defensiveStats = stats;
      
      // Generate league leaders for different defensive categories
      _generateDefensiveLeaders();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _log.severe('Error fetching team defensive stats: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get list of offensive stats for teams
  List<dynamic> get offensiveTeams {
    if (_offensiveStats.containsKey('offensive_stats')) {
      return _offensiveStats['offensive_stats'] ?? [];
    }
    return [];
  }
  
  // Get list of defensive stats for teams
  List<dynamic> get defensiveTeams {
    if (_defensiveStats.containsKey('defensive_stats')) {
      return _defensiveStats['defensive_stats'] ?? [];
    }
    return [];
  }
  
  // Get selected team's offensive stats
  Map<String, dynamic>? getSelectedTeamOffensiveStats() {
    if (_selectedTeam == null) return null;
    
    try {
      final team = offensiveTeams.firstWhere(
        (team) => team['team_name'] == _selectedTeam
      );
      return team['offensive_stats'];
    } catch (e) {
      _log.warning('Team not found: $_selectedTeam');
      return null;
    }
  }
  
  // Get selected team's defensive stats
  Map<String, dynamic>? getSelectedTeamDefensiveStats() {
    if (_selectedTeam == null) return null;
    
    try {
      final team = defensiveTeams.firstWhere(
        (team) => team['team_name'] == _selectedTeam
      );
      return team['defensive_stats'];
    } catch (e) {
      _log.warning('Team not found: $_selectedTeam');
      return null;
    }
  }
  
  // Generate league leaders for offensive categories
  void _generateOffensiveLeaders() {
    _offensiveLeaders = [];
    
    if (offensiveTeams.isEmpty) return;
    
    // Points per game leaders
    final ppgLeaders = List<Map<String, dynamic>>.from(offensiveTeams);
    ppgLeaders.sort((a, b) => (b['offensive_stats']['points_per_game'] as num)
        .compareTo(a['offensive_stats']['points_per_game'] as num));
    
    // Three point percentage leaders
    final tpLeaders = List<Map<String, dynamic>>.from(offensiveTeams);
    tpLeaders.sort((a, b) => (b['offensive_stats']['three_point_pct'] as num)
        .compareTo(a['offensive_stats']['three_point_pct'] as num));
    
    // Field goal percentage leaders
    final fgLeaders = List<Map<String, dynamic>>.from(offensiveTeams);
    fgLeaders.sort((a, b) => (b['offensive_stats']['field_goal_pct'] as num)
        .compareTo(a['offensive_stats']['field_goal_pct'] as num));
    
    // Assists per game leaders
    final astLeaders = List<Map<String, dynamic>>.from(offensiveTeams);
    astLeaders.sort((a, b) => (b['offensive_stats']['assists_per_game'] as num)
        .compareTo(a['offensive_stats']['assists_per_game'] as num));
    
    // Offensive rating leaders
    final ortgLeaders = List<Map<String, dynamic>>.from(offensiveTeams);
    ortgLeaders.sort((a, b) => (b['offensive_stats']['offensive_rating'] as num)
        .compareTo(a['offensive_stats']['offensive_rating'] as num));
    
    // Add stat_value field for each leader for display purposes
    for (var i = 0; i < ppgLeaders.length; i++) {
      ppgLeaders[i] = Map<String, dynamic>.from(ppgLeaders[i]);
      ppgLeaders[i]['stat_value'] = ppgLeaders[i]['offensive_stats']['points_per_game'];
    }
    
    for (var i = 0; i < tpLeaders.length; i++) {
      tpLeaders[i] = Map<String, dynamic>.from(tpLeaders[i]);
      tpLeaders[i]['stat_value'] = tpLeaders[i]['offensive_stats']['three_point_pct'];
    }
    
    for (var i = 0; i < fgLeaders.length; i++) {
      fgLeaders[i] = Map<String, dynamic>.from(fgLeaders[i]);
      fgLeaders[i]['stat_value'] = fgLeaders[i]['offensive_stats']['field_goal_pct'];
    }
    
    for (var i = 0; i < astLeaders.length; i++) {
      astLeaders[i] = Map<String, dynamic>.from(astLeaders[i]);
      astLeaders[i]['stat_value'] = astLeaders[i]['offensive_stats']['assists_per_game'];
    }
    
    for (var i = 0; i < ortgLeaders.length; i++) {
      ortgLeaders[i] = Map<String, dynamic>.from(ortgLeaders[i]);
      ortgLeaders[i]['stat_value'] = ortgLeaders[i]['offensive_stats']['offensive_rating'];
    }
    
    // Add all leader categories to the offensive leaders list
    _offensiveLeaders = [
      {'category': 'Points Per Game', 'leaders': ppgLeaders, 'stat_label': 'PPG'},
      {'category': '3-Point Percentage', 'leaders': tpLeaders, 'stat_label': '%'},
      {'category': 'Field Goal Percentage', 'leaders': fgLeaders, 'stat_label': '%'},
      {'category': 'Assists Per Game', 'leaders': astLeaders, 'stat_label': 'APG'},
      {'category': 'Offensive Rating', 'leaders': ortgLeaders, 'stat_label': 'ORTG'}
    ];
  }
  
  // Generate league leaders for defensive categories
  void _generateDefensiveLeaders() {
    _defensiveLeaders = [];
    
    if (defensiveTeams.isEmpty) return;
    
    // Opponent points per game leaders (lower is better)
    final oppgLeaders = List<Map<String, dynamic>>.from(defensiveTeams);
    oppgLeaders.sort((a, b) => (a['defensive_stats']['opponent_points_per_game'] as num)
        .compareTo(b['defensive_stats']['opponent_points_per_game'] as num));
    
    // Blocks per game leaders
    final blkLeaders = List<Map<String, dynamic>>.from(defensiveTeams);
    blkLeaders.sort((a, b) => (b['defensive_stats']['blocks_per_game'] as num)
        .compareTo(a['defensive_stats']['blocks_per_game'] as num));
    
    // Steals per game leaders
    final stlLeaders = List<Map<String, dynamic>>.from(defensiveTeams);
    stlLeaders.sort((a, b) => (b['defensive_stats']['steals_per_game'] as num)
        .compareTo(a['defensive_stats']['steals_per_game'] as num));
    
    // Opponent field goal percentage leaders (lower is better)
    final ofgLeaders = List<Map<String, dynamic>>.from(defensiveTeams);
    ofgLeaders.sort((a, b) => (a['defensive_stats']['opponent_field_goal_pct'] as num)
        .compareTo(b['defensive_stats']['opponent_field_goal_pct'] as num));
    
    // Defensive rating leaders (lower is better)
    final drtgLeaders = List<Map<String, dynamic>>.from(defensiveTeams);
    drtgLeaders.sort((a, b) => (a['defensive_stats']['defensive_rating'] as num)
        .compareTo(b['defensive_stats']['defensive_rating'] as num));
    
    // Add stat_value field for each leader for display purposes
    for (var i = 0; i < oppgLeaders.length; i++) {
      oppgLeaders[i] = Map<String, dynamic>.from(oppgLeaders[i]);
      oppgLeaders[i]['stat_value'] = oppgLeaders[i]['defensive_stats']['opponent_points_per_game'];
    }
    
    for (var i = 0; i < blkLeaders.length; i++) {
      blkLeaders[i] = Map<String, dynamic>.from(blkLeaders[i]);
      blkLeaders[i]['stat_value'] = blkLeaders[i]['defensive_stats']['blocks_per_game'];
    }
    
    for (var i = 0; i < stlLeaders.length; i++) {
      stlLeaders[i] = Map<String, dynamic>.from(stlLeaders[i]);
      stlLeaders[i]['stat_value'] = stlLeaders[i]['defensive_stats']['steals_per_game'];
    }
    
    for (var i = 0; i < ofgLeaders.length; i++) {
      ofgLeaders[i] = Map<String, dynamic>.from(ofgLeaders[i]);
      ofgLeaders[i]['stat_value'] = ofgLeaders[i]['defensive_stats']['opponent_field_goal_pct'];
    }
    
    for (var i = 0; i < drtgLeaders.length; i++) {
      drtgLeaders[i] = Map<String, dynamic>.from(drtgLeaders[i]);
      drtgLeaders[i]['stat_value'] = drtgLeaders[i]['defensive_stats']['defensive_rating'];
    }
    
    // Add all leader categories to the defensive leaders list
    _defensiveLeaders = [
      {'category': 'Opponent Points Per Game', 'leaders': oppgLeaders, 'stat_label': 'OPPG'},
      {'category': 'Blocks Per Game', 'leaders': blkLeaders, 'stat_label': 'BPG'},
      {'category': 'Steals Per Game', 'leaders': stlLeaders, 'stat_label': 'SPG'},
      {'category': 'Opponent FG Percentage', 'leaders': ofgLeaders, 'stat_label': '%'},
      {'category': 'Defensive Rating', 'leaders': drtgLeaders, 'stat_label': 'DRTG'}
    ];
  }
}
