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
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _log.severe('Error fetching games: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
