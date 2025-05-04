import 'package:flutter/material.dart';

class Prediction {
  final String team1Name;
  final String team1LogoPath;
  final double team1WinProbability;
  final String team2Name;
  final String team2LogoPath;
  final double team2WinProbability;
  final List<String> keyFactors;

  Prediction({
    required this.team1Name,
    required this.team1LogoPath,
    required this.team1WinProbability,
    required this.team2Name,
    required this.team2LogoPath,
    required this.team2WinProbability,
    this.keyFactors = const [],d
  })  : assert(team1WinProbability >= 0 && team1WinProbability <= 1),
        assert(team2WinProbability >= 0 && team2WinProbability <= 1),
        assert(
        (team1WinProbability + team2WinProbability) > 0.99 &&
            (team1WinProbability + team2WinProbability) < 1.01,
        'Probabilities must sum to ~1',
        );
}
