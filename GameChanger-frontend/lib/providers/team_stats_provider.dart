import 'package:flutter/material.dart';
import 'package:game_changer_ai/services/api_service.dart';
import 'package:logging/logging.dart';

class TeamStatsProvider extends ChangeNotifier {
  final Logger _log = Logger('TeamStatsProvider');
  
  Map<String, dynamic> _teamStats = {};
  bool _isLoading = false;
  String? _error;
  
  // Getters
  Map<String, dynamic> get teamStats => _teamStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Fetch team statistics from the API
  Future<void> fetchTeamStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final stats = await ApiService.getTeamStats();
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
}
