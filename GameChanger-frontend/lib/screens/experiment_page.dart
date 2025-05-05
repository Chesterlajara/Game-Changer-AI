import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/prediction_model.dart';
import '../widgets/team_selection.dart';
import '../widgets/player_adjustment.dart';
import '../widgets/performance_factor.dart';
import '../widgets/prediction_card.dart';
import '../providers/theme_provider.dart';
import '../data/nba_teams.dart';

class ExperimentPage extends StatefulWidget {
  const ExperimentPage({super.key});

  @override
  State<ExperimentPage> createState() => _ExperimentPageState();
}

class _ExperimentPageState extends State<ExperimentPage> {
  String? selectedTeam1;
  String? selectedTeam2;
  String? selectedTeamForAdjustment;

  List<String> samplePlayers = [
    'LeBron James',
    'Stephen Curry',
    'Kevin Durant',
    'Jayson Tatum',
    'Jimmy Butler',
  ];

  Map<String, bool> playerAdjustments = {};

  double homeCourtAdvantage = 5;
  double restDaysImpact = 5;
  double recentFormWeight = 5;

  // Use all NBA team names from our data file
  List<String> sampleTeams = NbaTeams.getAllTeamNames();

  void resetSelection() {
    setState(() {
      selectedTeam1 = null;
      selectedTeam2 = null;
      selectedTeamForAdjustment = null;
      playerAdjustments.clear();
      homeCourtAdvantage = 5;
      restDaysImpact = 5;
      recentFormWeight = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: Text(
          'Experiment',
          style: GoogleFonts.poppins(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetSelection,
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TeamSelectionCard(
                sampleTeams: sampleTeams,
                selectedTeam1: selectedTeam1,
                selectedTeam2: selectedTeam2,
                onTeam1Changed: (value) => setState(() => selectedTeam1 = value),
                onTeam2Changed: (value) => setState(() => selectedTeam2 = value),
              ),
              const SizedBox(height: 16),
              PlayerAdjustmentsCard(
                selectedTeam1: selectedTeam1,
                selectedTeam2: selectedTeam2,
                selectedTeamForAdjustment: selectedTeamForAdjustment,
                samplePlayers: samplePlayers,
                playerAdjustments: playerAdjustments,
                onTeamForAdjustmentChanged: (value) => setState(() => selectedTeamForAdjustment = value),
                onPlayerAdjustmentChanged: (player, value) => setState(() => playerAdjustments[player] = value),
              ),
              const SizedBox(height: 16),
              PerformanceFactorsCard(
                homeCourtAdvantage: homeCourtAdvantage,
                restDaysImpact: restDaysImpact,
                recentFormWeight: recentFormWeight,
                onHomeCourtChanged: (value) => setState(() => homeCourtAdvantage = value),
                onRestDaysChanged: (value) => setState(() => restDaysImpact = value),
                onRecentFormChanged: (value) => setState(() => recentFormWeight = value),
              ),
              const SizedBox(height: 16),
              if (selectedTeam1 != null && selectedTeam2 != null) ...[
                PredictionCard(
                  prediction: Prediction(
                      team1Name: selectedTeam1!,
                      team2Name: selectedTeam2!,
                      team1LogoPath: '${selectedTeam1!.toLowerCase().replaceAll(' ', '_')}_logo.png',
                      team2LogoPath: '${selectedTeam2!.toLowerCase().replaceAll(' ', '_')}_logo.png',
                      team1WinProbability: 0.5,
                      team2WinProbability: 0.5,
                      keyFactors: ['Strong defense', 'Home advantage', 'Star player returning']
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}