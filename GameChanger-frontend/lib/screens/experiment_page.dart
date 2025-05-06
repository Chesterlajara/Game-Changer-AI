import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/nba_teams.dart';
import '../data/player_data.dart';
import '../services/prediction_service.dart';
import '../widgets/team_selection.dart';
import '../widgets/player_adjustment.dart';
import '../widgets/performance_factors_card.dart';
import '../widgets/prediction_card.dart';
import '../widgets/prediction_insights_card.dart';
import '../providers/theme_provider.dart';
import '../models/prediction_model.dart';
import '../utils/logo_helper.dart';

class ExperimentPage extends StatefulWidget {
  const ExperimentPage({super.key});

  @override
  State<ExperimentPage> createState() => _ExperimentPageState();
}

class _ExperimentPageState extends State<ExperimentPage> {
  String? selectedTeam1;
  String? selectedTeam2;
  String? selectedTeamForAdjustment;

  // Map to track player adjustments (active/inactive)
  Map<String, bool> playerAdjustments = {};
  
  // Map to store player impact factors
  Map<String, double> playerImpactFactors = {};

  // Performance factors
  Map<String, int> performanceFactors = {
    'home_court_advantage': 5,
    'rest_days_impact': 5,
    'recent_form_weight': 5,
  };
  
  // Win probability
  double team1WinProbability =.5; // Default 50%
  double team2WinProbability = .5; // Default 50%
  bool isLoadingPrediction = false;
  
  // Explanation data
  Map<String, dynamic> team1Stats = {};
  Map<String, dynamic> team2Stats = {};
  Map<String, dynamic> explanationData = {};
  Map<String, dynamic> performanceFactorData = {};

  // Use all NBA team names from our data file
  List<String> sampleTeams = NbaTeams.getAllTeamNames();

  @override
  void initState() {
    super.initState();
    // Initialize player data from CSV
    _initializePlayerData();
  }

  Future<void> _initializePlayerData() async {
    try {
      // Pre-load player data in the background
      await PlayerData.loadPlayerData();
    } catch (e) {
      print('Error pre-loading player data: $e');
    }
  }

  void resetSelection() {
    setState(() {
      selectedTeam1 = null;
      selectedTeam2 = null;
      selectedTeamForAdjustment = null;
      playerAdjustments.clear();
      playerImpactFactors.clear();
      performanceFactors = {
        'home_court_advantage': 5,
        'rest_days_impact': 5,
        'recent_form_weight': 5,
      };
      team1WinProbability = 0.5;
      team2WinProbability = 0.5;
      explanationData.clear();
      performanceFactorData.clear();
    });
  }
  
  // Method to fetch prediction when teams are selected or factors change
  Future<void> updatePrediction() async {
    if (selectedTeam1 == null || selectedTeam2 == null) {
      return; // Can't predict without both teams
    }
    
    setState(() {
      isLoadingPrediction = true;
    });
    
    try {
      // Use the new predictWithPerformanceFactors endpoint with named parameters
      final result = await PredictionService.predictWithPerformanceFactors(
        team1: selectedTeam1!,
        team2: selectedTeam2!,
        playerAvailability: playerAdjustments,
        performanceFactors: performanceFactors,
      );
      
      print('Got prediction result with performance factors: $result');
      
      setState(() {
        // Update win probabilities
        if (result.containsKey('team1_win_prob')) {
          team1WinProbability = result['team1_win_prob'] as double;
        }
        if (result.containsKey('team2_win_prob')) {
          team2WinProbability = result['team2_win_prob'] as double;
        }
        
        // Update player impact factors if available
        if (result.containsKey('player_impacts')) {
          Map<String, dynamic> impacts = result['player_impacts'] as Map<String, dynamic>;
          // Store impact factors for later display
          playerImpactFactors.clear();
          impacts.forEach((playerName, impact) {
            playerImpactFactors[playerName] = impact as double;
            print('Player $playerName has impact factor: $impact');
          });
        }
        
        // Store performance factors data if available
        if (result.containsKey('performance_factors')) {
          performanceFactorData = result['performance_factors'] as Map<String, dynamic>;
          print('Performance factors data: $performanceFactorData');
        }
        
        // Store explanation data if available
        if (result.containsKey('explanation')) {
          explanationData = result['explanation'] as Map<String, dynamic>;
          print('Explanation data: $explanationData');
        }
        
        isLoadingPrediction = false;
      });
    } catch (e) {
      print('Error getting prediction with performance factors: $e');
      setState(() {
        isLoadingPrediction = false;
      });
    }
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
              // VS Layout with team boxes on both sides
              Card(
                color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Teams',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Team 1 Box
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Handle team box click if needed
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Team 1 dropdown
                                    DropdownButtonFormField<String>(
                                      value: selectedTeam1,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey.shade400),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: const Color(0xFF365772)),
                                        ),
                                      ),
                                      dropdownColor: themeProvider.isDarkMode ? Colors.grey[850] : const Color(0xFFF4F4F4),
                                      hint: Text(
                                        'Select Team',
                                        style: GoogleFonts.poppins(fontSize: 12, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                                      ),
                                      items: sampleTeams.map((team) {
                                        return DropdownMenuItem(
                                          value: team,
                                          child: Text(
                                            team,
                                            style: GoogleFonts.poppins(fontSize: 12, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() => selectedTeam1 = value);
                                        if (selectedTeam2 != null && value != null) {
                                          updatePrediction();
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    // Team 1 Logo
                                    if (selectedTeam1 != null)
                                      Container(
                                        height: 120,
                                        width: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: LogoHelper.buildTeamLogo(selectedTeam1!, 120),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // VS and Win Probability section
                          Container(
                            width: 120,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'VS',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (selectedTeam1 != null && selectedTeam2 != null) ...[                                  
                                  Text(
                                    'Win Probability',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  isLoadingPrediction
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF365772),
                                      ),
                                    )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${(team1WinProbability * 100).toInt()}%-${(team2WinProbability * 100).toInt()}%',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Team 2 Box
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Handle team box click if needed
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Team 2 dropdown
                                    DropdownButtonFormField<String>(
                                      value: selectedTeam2,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: themeProvider.isDarkMode ? Colors.white30 : Colors.grey.shade400),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: const Color(0xFF365772)),
                                        ),
                                      ),
                                      dropdownColor: themeProvider.isDarkMode ? Colors.grey[850] : const Color(0xFFF4F4F4),
                                      hint: Text(
                                        'Select Team',
                                        style: GoogleFonts.poppins(fontSize: 12, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                                      ),
                                      items: sampleTeams.map((team) {
                                        return DropdownMenuItem(
                                          value: team,
                                          child: Text(
                                            team,
                                            style: GoogleFonts.poppins(fontSize: 12, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() => selectedTeam2 = value);
                                        if (selectedTeam1 != null && value != null) {
                                          updatePrediction();
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    // Team 2 Logo
                                    if (selectedTeam2 != null)
                                      Container(
                                        height: 120,
                                        width: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: LogoHelper.buildTeamLogo(selectedTeam2!, 120),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Win probability bar
                      if (selectedTeam1 != null && selectedTeam2 != null) ...[                      
                        const SizedBox(height: 16),
                        Stack(
                          children: [
                            // Background bar
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            // Fill bar (team 1 probability)
                            FractionallySizedBox(
                              widthFactor: team1WinProbability, // Use actual probability from prediction
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF4863A0),
                                      const Color(0xFF365772),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Team probability labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedTeam1 ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                            Text(
                              selectedTeam2 ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Player adjustments section (remains as is, but we modify how the team selection works)
              PlayerAdjustmentsCard(
                selectedTeam1: selectedTeam1,
                selectedTeam2: selectedTeam2,
                selectedTeamForAdjustment: selectedTeamForAdjustment,
                playerAdjustments: playerAdjustments,
                playerImpactFactors: playerImpactFactors,
                onTeamForAdjustmentChanged: (value) => setState(() => selectedTeamForAdjustment = value),
                onPlayerAdjustmentChanged: (player, value) {
                  setState(() => playerAdjustments[player] = value);
                  // Update prediction when player status changes
                  updatePrediction();
                },
              ),
              
              const SizedBox(height: 16),
              
              // Performance factors card
              PerformanceFactorsCard(
                performanceFactors: performanceFactors,
                onFactorChanged: (factorName, value) {
                  setState(() {
                    performanceFactors[factorName] = value;
                  });
                  // Update prediction when a performance factor changes
                  updatePrediction();
                },
              ),
              
              const SizedBox(height: 16),
              
              if (selectedTeam1 != null && selectedTeam2 != null) ...[
                // Detailed insights card showing why the prediction was made
                if (!isLoadingPrediction) ...[
                  PredictionInsightsCard(
                    team1Name: selectedTeam1!,
                    team2Name: selectedTeam2!,
                    team1WinProb: team1WinProbability,
                    team2WinProb: team2WinProbability,
                    team1Stats: team1Stats,
                    team2Stats: team2Stats,
                    performanceFactors: performanceFactorData,
                    playerImpacts: playerImpactFactors,
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}