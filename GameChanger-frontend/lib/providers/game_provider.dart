import 'package:flutter/material.dart';
import 'package:game_changer_ai/models/game_model.dart';
import 'package:game_changer_ai/services/api_service.dart';
import 'package:logging/logging.dart';

class GameProvider extends ChangeNotifier {
  final Logger _log = Logger('GameProvider');
  
  List<Game> _games = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Game> get games => _games;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Filter games by status
  List<Game> getGamesByStatus(GameStatus status) {
    return _games.where((game) => game.status == status).toList();
  }
  
  // Filter games by date
  List<Game> getGamesByDate(DateTime date) {
    return _games.where((game) => 
      game.gameDate.year == date.year && 
      game.gameDate.month == date.month && 
      game.gameDate.day == date.day
    ).toList();
  }
  
  // Filter games by date and status
  List<Game> getGamesByDateAndStatus(DateTime date, GameStatus status) {
    return _games.where((game) => 
      game.gameDate.year == date.year && 
      game.gameDate.month == date.month && 
      game.gameDate.day == date.day &&
      game.status == status
    ).toList();
  }
  
  // Fetch games from the API
  Future<void> fetchGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final games = await ApiService.getGames();
      _games = games;
      
      // Debug log to see what games are loaded
      _log.info('Loaded ${games.length} games:');
      for (var game in games) {
        _log.info('Game: ${game.team1Name} vs ${game.team2Name}, Status: ${game.status}, Date: ${game.gameDate}');
      }
      
      // Debug log for today's games
      final today = DateTime.now();
      final todayGames = getGamesByDateAndStatus(today, GameStatus.today);
      _log.info('Today (non-live) games: ${todayGames.length}');
      for (var game in todayGames) {
        _log.info('Today game: ${game.team1Name} vs ${game.team2Name}, Time: ${game.gameTime?.hour}:${game.gameTime?.minute}');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      _log.severe('Error fetching games: $e');
      notifyListeners();
    }
  }
}
