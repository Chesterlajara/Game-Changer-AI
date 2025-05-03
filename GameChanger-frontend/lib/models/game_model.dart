import 'package:flutter/material.dart';

enum GameStatus { today, upcoming, live }

class Game {
  final String team1Name;
  final String team1LogoPath; // Path relative to assets/logos/
  final double team1WinProbability; // 0.0 to 1.0
  final String team2Name;
  final String team2LogoPath; // Path relative to assets/logos/
  final double team2WinProbability; // 0.0 to 1.0
  final GameStatus status;
  final TimeOfDay? gameTime; // Nullable, only for upcoming games
  final DateTime gameDate; // Added game date
  final String location; // Added game location

  Game({
    required this.team1Name,
    required this.team1LogoPath,
    required this.team1WinProbability,
    required this.team2Name,
    required this.team2LogoPath,
    required this.team2WinProbability,
    required this.status,
    required this.gameDate,
    required this.location,
    this.gameTime,
  }) : assert(team1WinProbability >= 0 && team1WinProbability <= 1),
       assert(team2WinProbability >= 0 && team2WinProbability <= 1),
       // Basic check: probabilities should ideally sum close to 1, allow some float inaccuracy
       assert((team1WinProbability + team2WinProbability) > 0.99 && (team1WinProbability + team2WinProbability) < 1.01, 'Probabilities must sum to ~1'),
       // Game time must be provided if status is upcoming
       assert(status != GameStatus.upcoming || gameTime != null, 'Upcoming games must have a gameTime');
}
