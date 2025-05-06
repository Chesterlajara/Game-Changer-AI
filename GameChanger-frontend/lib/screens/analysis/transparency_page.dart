import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../models/game_model.dart';
import '../../providers/theme_provider.dart';
import '../../services/prediction_service.dart';
import '../../services/team_stats_service.dart';
import '../../services/game_analysis_service.dart';
import '../../widgets/team_stats_hexagon.dart';
import '../../data/player_data.dart';
import '../../data/nba_teams.dart';

class TransparencyPage extends StatefulWidget {
  final Game game;

  const TransparencyPage({super.key, required this.game});

  @override
  State<TransparencyPage> createState() => _TransparencyPageState();
}

class _TransparencyPageState extends State<TransparencyPage> {
  int _selectedTabIndex = 0;
  String _selectedTeamFilter = 'Top'; // For standings
  String _selectedStatFilter = 'Wins'; // For standings
  String _selectedFactorFilter = 'All'; // For key factors
  String _selectedPlayerTeam = 'All'; // For players tab - 'Team1', 'Team2', or 'All'

  // Data holders
  bool isLoading = true;
  Map<String, dynamic> predictionData = {};
  Map<String, dynamic> keyFactors = {};
  Map<String, dynamic> playerImpacts = {};
  Map<String, dynamic> historicalData = {};
  
  // Team statistics for the hexagon chart
  Map<String, double> team1Stats = {
    'PPG': 0.6,
    '3PT': 0.5,
    'REB': 0.7,
    'AST': 0.4,
    'STL': 0.5,
    'BLK': 0.3,
  };
  
  Map<String, double> team2Stats = {
    'PPG': 0.4,
    '3PT': 0.3,
    'REB': 0.3,
    'AST': 0.6,
    'STL': 0.7,
    'BLK': 0.5,
  };
  
  // Raw team statistics (actual values, not normalized)
  Map<String, double> team1RawStats = {
    'PPG': 106.5,
    '3PT': 36.7,
    'REB': 45.2,
    'AST': 25.8,
    'STL': 8.4,
    'BLK': 5.1,
  };
  
  Map<String, double> team2RawStats = {
    'PPG': 102.3,
    '3PT': 34.2,
    'REB': 42.5,
    'AST': 23.6,
    'STL': 7.6,
    'BLK': 4.2,
  };

  @override
  void initState() {
    super.initState();
    _fetchAnalysisData();
  }

  Future<void> _fetchAnalysisData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      print('Starting data fetch for teams: ${widget.game.team1Name} vs ${widget.game.team2Name}');
      
      // APPROACH 1: Try direct API call with team names
      // Use a POST request directly to Flask backend to get both team stats
      try {
        final teamStatsResponse = await http.post(
          Uri.parse('http://localhost:5000/get-team-stats'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'team1': widget.game.team1Name,
            'team2': widget.game.team2Name,
          }),
        );
        
        print('Team stats API response code: ${teamStatsResponse.statusCode}');
        
        if (teamStatsResponse.statusCode == 200) {
          final teamStatsData = jsonDecode(teamStatsResponse.body);
          print('Team stats data received: ${teamStatsData.keys}');
          
          // Process the team stats to get both normalized and raw values
          final processedStats = TeamStatsService.processTeamStats(
            teamStatsData,
            widget.game.team1Name,
            widget.game.team2Name,
          );
          
          // Set processed team stats
          setState(() {
            team1Stats = processedStats['team1Stats'] ?? team1Stats;
            team2Stats = processedStats['team2Stats'] ?? team2Stats;
            team1RawStats = processedStats['team1RawStats'] ?? team1RawStats;
            team2RawStats = processedStats['team2RawStats'] ?? team2RawStats;
          });
        }
      } catch (e) {
        print('Error fetching team stats directly: $e');
      }
      
      // APPROACH 2: Load player data directly from CSV files like the Experiment page does
      try {
        print('Loading player data from CSV files...');
        print('=== DEBUG INFO ===');
        print('Game details: ${widget.game.team1Name} vs ${widget.game.team2Name}');
        
        // First, let's get all available team names in the system
        final allTeamNames = NbaTeams.getAllTeamNames();
        print('All team names in system: $allTeamNames');
        
        // Get the teams' abbreviations - we need to handle the exact team names from the game
        String team1Name = widget.game.team1Name;
        String team2Name = widget.game.team2Name;
        
        print('Exact team names from game: "$team1Name" vs "$team2Name"');
        
        // Try to find the team abbreviations - handle common variations
        String team1Abbreviation = '';
        String team2Abbreviation = '';
        
        // Try direct lookup first
        team1Abbreviation = NbaTeams.getTeamAbbreviation(team1Name) ?? '';
        team2Abbreviation = NbaTeams.getTeamAbbreviation(team2Name) ?? '';
        
        print('After direct lookup: "$team1Abbreviation" vs "$team2Abbreviation"');
        
        // Handle common team name variations and partial matches
        if (team1Abbreviation.isEmpty) {
          // Try to find partial matches
          for (var entry in NbaTeams.abbreviationToName.entries) {
            if (team1Name.contains(entry.value) || entry.value.contains(team1Name)) {
              team1Abbreviation = entry.key;
              print('Found partial match for team 1: $team1Name -> ${entry.value} -> $team1Abbreviation');
              break;
            }
          }
          
          // Fallback to common names if still empty
          if (team1Abbreviation.isEmpty) {
            if (team1Name.toLowerCase().contains('lakers')) team1Abbreviation = 'LAL';
            else if (team1Name.toLowerCase().contains('warriors')) team1Abbreviation = 'GSW';
            else if (team1Name.toLowerCase().contains('celtics')) team1Abbreviation = 'BOS';
            else if (team1Name.toLowerCase().contains('bucks')) team1Abbreviation = 'MIL';
            else if (team1Name.toLowerCase().contains('nuggets')) team1Abbreviation = 'DEN';
            else if (team1Name.toLowerCase().contains('mavericks')) team1Abbreviation = 'DAL';
            else if (team1Name.toLowerCase().contains('thunder')) team1Abbreviation = 'OKC';
            
            if (team1Abbreviation.isNotEmpty) {
              print('Used name pattern match for team 1: $team1Name -> $team1Abbreviation');
            }
          }
        }
        
        if (team2Abbreviation.isEmpty) {
          // Try to find partial matches
          for (var entry in NbaTeams.abbreviationToName.entries) {
            if (team2Name.contains(entry.value) || entry.value.contains(team2Name)) {
              team2Abbreviation = entry.key;
              print('Found partial match for team 2: $team2Name -> ${entry.value} -> $team2Abbreviation');
              break;
            }
          }
          
          // Fallback to common names if still empty
          if (team2Abbreviation.isEmpty) {
            if (team2Name.toLowerCase().contains('lakers')) team2Abbreviation = 'LAL';
            else if (team2Name.toLowerCase().contains('warriors')) team2Abbreviation = 'GSW';
            else if (team2Name.toLowerCase().contains('celtics')) team2Abbreviation = 'BOS';
            else if (team2Name.toLowerCase().contains('bucks')) team2Abbreviation = 'MIL';
            else if (team2Name.toLowerCase().contains('nuggets')) team2Abbreviation = 'DEN';
            else if (team2Name.toLowerCase().contains('mavericks')) team2Abbreviation = 'DAL';
            else if (team2Name.toLowerCase().contains('thunder')) team2Abbreviation = 'OKC';
            
            if (team2Abbreviation.isNotEmpty) {
              print('Used name pattern match for team 2: $team2Name -> $team2Abbreviation');
            }
          }
        }
        
        print('Final team abbreviations: "$team1Abbreviation" vs "$team2Abbreviation"');
        
        // For demo purposes, if we can't find the abbreviations, use LAL and GSW
        if (team1Abbreviation.isEmpty) {
          team1Abbreviation = 'LAL';
          print('WARNING: Using default LAL for team 1');
        }
        if (team2Abbreviation.isEmpty) {
          team2Abbreviation = 'GSW';
          print('WARNING: Using default GSW for team 2');
        }
        
        // Load player data from CSV files
        final playersByTeam = await PlayerData.loadPlayerData();
        
        print('Player data loaded, found ${playersByTeam.keys.length} teams');
        print('Available teams: ${playersByTeam.keys.toList()}');
        
        // Create player impacts map from CSV data
        Map<String, double> extractedPlayerImpacts = {};
        
        // If exact teams not found, use the first two teams available from CSV
        List<String> teamsToUse = [];
        
        // First try to use the resolved abbreviations
        if (playersByTeam.containsKey(team1Abbreviation)) {
          teamsToUse.add(team1Abbreviation);
        }
        if (playersByTeam.containsKey(team2Abbreviation)) {
          teamsToUse.add(team2Abbreviation);
        }
        
        // If we don't have two teams yet, use whatever teams are available from the CSV
        if (teamsToUse.length < 2 && playersByTeam.keys.length >= 2) {
          print('Falling back to available teams from CSV');
          final availableTeams = playersByTeam.keys.toList();
          // Don't duplicate teams already added
          for (var team in availableTeams) {
            if (!teamsToUse.contains(team) && teamsToUse.length < 2) {
              teamsToUse.add(team);
            }
          }
        }
        
        print('Using teams: $teamsToUse');
        
        // Process team 1 (positive impact)
        if (teamsToUse.isNotEmpty) {
          final team1 = teamsToUse[0];
          final team1Players = playersByTeam[team1] ?? [];
          print('Using ${team1Players.length} players for team 1 ($team1)');
          
          for (final player in team1Players) {
            // Calculate impact factor as in the backend
            final rawImpact = (0.4 * player.points + 
                            0.2 * player.rebounds + 
                            0.2 * player.assists + 
                            0.1 * player.steals + 
                            0.1 * player.blocks) / 100.0;
            final impact = rawImpact.clamp(0.01, 0.20);
            
            // Add to impacts map - positive for team 1
            extractedPlayerImpacts[player.playerName] = impact;
            print('Added player ${player.playerName} with impact $impact');
          }
        }
        
        // Process team 2 (negative impact)
        if (teamsToUse.length > 1) {
          final team2 = teamsToUse[1];
          final team2Players = playersByTeam[team2] ?? [];
          print('Using ${team2Players.length} players for team 2 ($team2)');
          
          for (final player in team2Players) {
            // Calculate impact factor as in the backend
            final rawImpact = (0.4 * player.points + 
                            0.2 * player.rebounds + 
                            0.2 * player.assists + 
                            0.1 * player.steals + 
                            0.1 * player.blocks) / 100.0;
            final impact = rawImpact.clamp(0.01, 0.20);
            
            // Add to impacts map - negative for team 2 (by convention)
            extractedPlayerImpacts[player.playerName] = -impact;
            print('Added player ${player.playerName} with impact ${-impact}');
          }
        }
        
        if (extractedPlayerImpacts.isNotEmpty) {
          print('Generated ${extractedPlayerImpacts.length} player impacts from CSV data');
          setState(() {
            playerImpacts = extractedPlayerImpacts;
          });
        } else {
          throw Exception('No player impacts generated from CSV data');
        }
      } catch (e) {
        print('Error loading player data from CSV: $e');
        
        // Fallback player impacts - use team-specific players instead of generic ones
        final String team1Name = widget.game.team1Name;
        final String team2Name = widget.game.team2Name;
        
        // Create fallback data based on common team names
        Map<String, double> fallbackImpacts = {};
        
        if (team1Name.contains('Lakers')) {
          fallbackImpacts['LeBron James'] = 0.15;
          fallbackImpacts['Anthony Davis'] = 0.12;
          fallbackImpacts['Austin Reaves'] = 0.08;
        } else if (team1Name.contains('Warriors')) {
          fallbackImpacts['Stephen Curry'] = 0.18;
          fallbackImpacts['Draymond Green'] = 0.10;
          fallbackImpacts['Klay Thompson'] = 0.09;
        } else if (team1Name.contains('Bucks')) {
          fallbackImpacts['Giannis Antetokounmpo'] = 0.20;
          fallbackImpacts['Damian Lillard'] = 0.14;
        } else {
          // Generic team 1 players if no match
          fallbackImpacts['Team 1 Star Player'] = 0.15;
          fallbackImpacts['Team 1 Second Option'] = 0.10;
        }
        
        if (team2Name.contains('Nuggets')) {
          fallbackImpacts['Nikola Jokić'] = -0.17;
          fallbackImpacts['Jamal Murray'] = -0.12;
          fallbackImpacts['Aaron Gordon'] = -0.09;
        } else if (team2Name.contains('Celtics')) {
          fallbackImpacts['Jayson Tatum'] = -0.16;
          fallbackImpacts['Jaylen Brown'] = -0.15;
        } else if (team2Name.contains('Mavericks')) {
          fallbackImpacts['Luka Dončić'] = -0.19;
          fallbackImpacts['Kyrie Irving'] = -0.15;
        } else {
          // Generic team 2 players if no match
          fallbackImpacts['Team 2 Star Player'] = -0.15;
          fallbackImpacts['Team 2 Second Option'] = -0.10;
        }
        
        setState(() {
          playerImpacts = fallbackImpacts;
        });
      }
      
      // APPROACH 3: Try game analysis endpoint as a last resort
      try {
        final gameAnalysisResult = await GameAnalysisService.getGameAnalysis('1');
        print('Game Analysis Result Keys: ${gameAnalysisResult.keys}');
        
        if (gameAnalysisResult.isNotEmpty) {
          // Extract key factors
          Map<String, dynamic> extractedKeyFactors = {};
          if (gameAnalysisResult.containsKey('key_factors')) {
            extractedKeyFactors = gameAnalysisResult['key_factors'] as Map<String, dynamic>;
          }
          
          setState(() {
            keyFactors = extractedKeyFactors;
            predictionData = gameAnalysisResult;
          });
        }
      } catch (e) {
        print('Error fetching game analysis: $e');
      }
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error in _fetchAnalysisData: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Helper method to normalize team stats for the hexagon chart and also set raw stats
  void _normalizeAndSetTeamStats(Map<String, dynamic> rawStats, Map<String, double> targetStats) {
    // Define max values for normalization
    final maxValues = {
      'PPG': 120.0, // Max points per game
      '3PT': 45.0,  // Max 3-point percentage
      'REB': 55.0,  // Max rebounds
      'AST': 35.0,  // Max assists
      'STL': 12.0,  // Max steals
      'BLK': 8.0,   // Max blocks
    };
    
    // Map API stat names to our display names if needed
    final statMapping = {
      'points_per_game': 'PPG',
      'three_point_percentage': '3PT',
      'rebounds_per_game': 'REB',
      'assists_per_game': 'AST',
      'steals_per_game': 'STL',
      'blocks_per_game': 'BLK',
    };
    
    // Process stats for both normalized chart values and raw display values
    Map<String, double> rawValues = {};
    
    rawStats.forEach((key, value) {
      final displayKey = statMapping[key] ?? key;
      if (maxValues.containsKey(displayKey) && value is num) {
        // Store the raw value for display
        rawValues[displayKey] = value.toDouble();
        
        // Calculate normalized value for the chart
        final normalized = (value / maxValues[displayKey]!).clamp(0.0, 1.0);
        targetStats[displayKey] = normalized;
      }
    });
    
    // Add fallback values for missing stats
    maxValues.keys.forEach((key) {
      if (!targetStats.containsKey(key)) {
        targetStats[key] = 0.5; // Default normalized value
      }
      
      // Update the corresponding raw stats collection
      if (rawStats == team1Stats) {
        if (rawValues.containsKey(key)) {
          team1RawStats[key] = rawValues[key]!;
        }
      } else if (rawStats == team2Stats) {
        if (rawValues.containsKey(key)) {
          team2RawStats[key] = rawValues[key]!;
        }
      }
    });
  }
  
  // Helper method to normalize team stats for the hexagon chart from CSV data
  void _normalizeTeamStats(Map<String, dynamic> rawStats, Map<String, dynamic> normalizedStats, Map<String, double> rawStatsOutput) {
    // Define max values for normalization
    final maxValues = {
      'PPG': 120.0, // Max points per game
      '3PT': 45.0,  // Max 3-point percentage
      'REB': 55.0,  // Max rebounds
      'AST': 35.0,  // Max assists
      'STL': 12.0,  // Max steals
      'BLK': 8.0,   // Max blocks
    };
    
    // Map CSV stat names to our display names
    final statMapping = {
      'PTS': 'PPG',
      'FG3_PCT': '3PT',
      'REB': 'REB',
      'AST': 'AST',
      'STL': 'STL',
      'BLK': 'BLK',
    };
    
    // Process each stat from CSV data format
    statMapping.forEach((csvKey, displayKey) {
      if (rawStats.containsKey(csvKey) && rawStats[csvKey] is num) {
        final rawValue = (rawStats[csvKey] as num).toDouble();
        final maxValue = maxValues[displayKey];
        
        // Store raw value for display
        rawStatsOutput[displayKey] = rawValue;
        
        // Calculate normalized value for the chart
        if (maxValue != null) {
          final normalizedValue = (rawValue / maxValue).clamp(0.0, 1.0);
          normalizedStats[displayKey] = normalizedValue;
        }
      } else {
        // Fallback if stat is missing
        normalizedStats[displayKey] = 0.5; // Default normalized value
      }
    });
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  String _formatDateTime(DateTime date, TimeOfDay? time) {
    String datePart;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final gameDay = DateTime(date.year, date.month, date.day);

    if (gameDay == today) {
      datePart = 'Today';
    } else if (gameDay == tomorrow) {
      datePart = 'Tomorrow';
    } else if (gameDay == yesterday) {
      datePart = 'Yesterday';
    } else {
      datePart = DateFormat('MMM d').format(date); // e.g., May 1
    }

    String timePart = _formatTime(time);
    return timePart.isEmpty ? datePart : '$datePart, $timePart';
  }

  Widget _buildLogo(String logoPath, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/logos/$logoPath',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.sports_basketball, size: size * 0.8, color: Colors.grey);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final Color iconColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color titleColor = const Color(0xFF9333EA);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2D3748) : Colors.transparent, // Match GamePage AppBar color
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/arrow_back.svg',
            height: 24,
            width: 24,
            colorFilter: isDark ? ColorFilter.mode(iconColor, BlendMode.srcIn) : null,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Game Analysis',
          style: GoogleFonts.poppins(
            color: titleColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              themeProvider.toggleTheme(!isDark);
            },
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // crossAxisAlignment removed - card handles its own alignment
          children: [
            _GameSummaryCard(game: widget.game), // Card now includes details
            const SizedBox(height: 20), // Space between card and tab bar
            _buildTabBar(), // Add the tab bar
            const SizedBox(height: 20), // Space below tab bar
            _buildTabContent(), // Implemented tab content
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? const Color(0xFF2D3748) : null, // Match MainScreen dark color
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Game',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.query_stats),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined),
            label: 'Experiment',
          ),
        ],
        currentIndex: 0, // Default to first item, as this page doesn't manage main index
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
        onTap: (index) {
          // Simple pop navigation, as this page isn't the main navigation host
          if (Navigator.canPop(context)) {
             Navigator.popUntil(context, (route) => route.isFirst);
          }
          // TODO: Optionally, implement navigation to the actual main screen tabs
          // if the structure allows, but pop is safer for now.
        },
      ),
    );
  }

  // Helper methods for UI components
  Color _getImpactColor(double impact) {
    if (impact > 0.2) return Colors.green[700]!;
    if (impact > 0.1) return Colors.green[500]!;
    if (impact > 0.05) return Colors.amber[700]!;
    return Colors.orange[400]!;
  }

  Widget _buildFactorRow({
    required String factor,
    required bool isPositive,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.add_circle : Icons.remove_circle,
            size: 16,
            color: isPositive 
                ? (isDarkMode ? Colors.green[400] : Colors.green[700])
                : (isDarkMode ? Colors.red[400] : Colors.red[700]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              factor,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final themeProvider = Provider.of<ThemeProvider>(context); // Get theme provider
    final isDark = themeProvider.isDarkMode;

    final List<String> tabs = ['Key factors', 'Players', 'History'];
    final double tabWidth = 103;
    final double tabHeight = 27;
    final double containerWidth = 342;
    final double containerHeight = 39;
    final double borderWidth = 0.2;
    final double innerWidth = containerWidth - (2 * borderWidth);
    final double horizontalPadding = (innerWidth - (tabs.length * tabWidth)) / 2;

    // Define theme-aware colors
    final Color selectedColor = isDark ? Colors.white : Colors.black;
    final Color unselectedColor = isDark ? Colors.grey[400]! : const Color(0xFF4B5563);
    final Color tabContainerBg = isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9); // Match GamePage
    final Color tabContainerBorder = isDark ? Colors.grey[600]!.withOpacity(0.5) : const Color(0xFF374151).withOpacity(0.30); // Match GamePage
    final Color selectedBg = isDark ? Colors.grey[700]! : Colors.white; // Match GamePage

    return Container(
      width: containerWidth,
      height: containerHeight,
      decoration: BoxDecoration(
        color: tabContainerBg, // Apply theme-aware bg
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: tabContainerBorder, width: borderWidth), // Apply theme-aware border
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated Background for Selected Tab
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: horizontalPadding + (_selectedTabIndex * tabWidth),
            child: Container(
              width: tabWidth,
              height: tabHeight,
              decoration: BoxDecoration(
                color: selectedBg, // Apply theme-aware selected bg
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
          ),
          // Tab Texts
          Padding(
             padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out tabs
               children: List.generate(tabs.length, (index) {
                 final bool isSelected = _selectedTabIndex == index;
                 return GestureDetector(
                   onTap: () {
                     setState(() {
                       _selectedTabIndex = index;
                     });
                   },
                   child: Container(
                      // Ensure the container covers the tappable area
                      width: tabWidth,
                      height: tabHeight,
                      color: Colors.transparent, // Make container tappable but invisible
                      alignment: Alignment.center,
                      child: Text(
                       tabs[index],
                       style: GoogleFonts.poppins(
                         fontSize: 10,
                         fontWeight: FontWeight.w500,
                         color: isSelected ? selectedColor : unselectedColor, // Apply theme-aware text color
                       ),
                     ),
                   ),
                 );
               }),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildKeyFactorsTab();
      case 1:
        return _buildPlayersTab();
      case 2:
        return _buildHistoryTab();
      default:
        return _buildKeyFactorsTab();
    }
  }

  Widget _buildKeyFactorsTab() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hexagon radar chart comparing team stats
                  TeamStatsHexagon(
                    team1Name: widget.game.team1Name,
                    team1Stats: team1Stats,
                    team1RawStats: team1RawStats,
                    team2Name: widget.game.team2Name,
                    team2Stats: team2Stats,
                    team2RawStats: team2RawStats,
                  ),
                  const SizedBox(height: 24),
                  
                  // Head-to-head statistical comparison
                  _buildStatsComparisonTable(),
                  const SizedBox(height: 24),
                  
                  // Key Factors Explanation card
                  _buildKeyFactorsExplanation(),
                  const SizedBox(height: 24),
                  
                  // Player impact visualization
                  _buildPlayerImpactVisualization(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildStatsComparisonTable() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    // Text styles
    final headerStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
    );
    
    final statLabelStyle = GoogleFonts.poppins(
      fontSize: 12,
      color: isDark ? Colors.white70 : Colors.grey[800],
    );
    
    final statValueStyle = GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Colors.black,
    );
    
    // Determine which stats to compare
    final comparisonStats = [
      {'label': 'Points Per Game', 'team1Key': 'PPG', 'team2Key': 'PPG', 'format': '%.1f'},
      {'label': '3-Point %', 'team1Key': '3PT', 'team2Key': '3PT', 'format': '%.1f%%'},
      {'label': 'Rebounds', 'team1Key': 'REB', 'team2Key': 'REB', 'format': '%.1f'},
      {'label': 'Assists', 'team1Key': 'AST', 'team2Key': 'AST', 'format': '%.1f'},
      {'label': 'Steals', 'team1Key': 'STL', 'team2Key': 'STL', 'format': '%.1f'},
      {'label': 'Blocks', 'team1Key': 'BLK', 'team2Key': 'BLK', 'format': '%.1f'},
      {'label': 'Win %', 'team1Key': 'W_PCT', 'team2Key': 'W_PCT', 'format': '%.3f'},
    ];
    
    return Card(
      color: isDark ? Colors.grey[850] : Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistical Comparison', style: headerStyle),
            const SizedBox(height: 12),
            
            // Team headers
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.game.team1Name,
                    style: headerStyle.copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Stat',
                    style: headerStyle.copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.game.team2Name,
                    style: headerStyle.copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Head-to-head comparison rows
            ...comparisonStats.map((stat) {
              // Get values with fallback to 0
              final team1Value = team1RawStats[stat['team1Key']] ?? 0.0;
              final team2Value = team2RawStats[stat['team2Key']] ?? 0.0;
              
              // Determine which team has the advantage for this stat
              final team1Better = team1Value > team2Value;
              
              // Format the values according to the format string
              final formatStr = stat['format'] as String;
              final team1Str = formatStr.contains('%%') 
                  ? formatStr.replaceFirst('%%', '%').replaceAll('%.1f', '${team1Value.toStringAsFixed(1)}')
                  : formatStr.replaceAll('%.1f', '${team1Value.toStringAsFixed(1)}').replaceAll('%.3f', '${team1Value.toStringAsFixed(3)}');
                  
              final team2Str = formatStr.contains('%%') 
                  ? formatStr.replaceFirst('%%', '%').replaceAll('%.1f', '${team2Value.toStringAsFixed(1)}')
                  : formatStr.replaceAll('%.1f', '${team2Value.toStringAsFixed(1)}').replaceAll('%.3f', '${team2Value.toStringAsFixed(3)}');
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Team 1 value
                    Expanded(
                      child: Text(
                        team1Str,
                        style: statValueStyle.copyWith(
                          color: team1Better ? Colors.green : isDark ? Colors.white : Colors.black,
                          fontWeight: team1Better ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Stat label
                    Expanded(
                      child: Text(
                        stat['label'] as String,
                        style: statLabelStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Team 2 value
                    Expanded(
                      child: Text(
                        team2Str,
                        style: statValueStyle.copyWith(
                          color: !team1Better ? Colors.green : isDark ? Colors.white : Colors.black,
                          fontWeight: !team1Better ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildKeyFactorsExplanation() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    // Text styles
    final headerStyle = GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
    );
    
    final subheaderStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Colors.black87,
    );
    
    final bodyStyle = GoogleFonts.poppins(
      fontSize: 13,
      color: isDark ? Colors.white70 : Colors.black54,
    );
    
    // Determine winning and losing team
    final winningTeam = widget.game.team1WinProbability > widget.game.team2WinProbability 
        ? widget.game.team1Name 
        : widget.game.team2Name;
    final losingTeam = widget.game.team1WinProbability > widget.game.team2WinProbability 
        ? widget.game.team2Name 
        : widget.game.team1Name;
    
    // Get explanation factors from the backend data
    List<String> winningFactors = [];
    List<String> losingFactors = [];
    
    if (keyFactors.containsKey('team_strengths') && 
        keyFactors['team_strengths'].containsKey(winningTeam)) {
      winningFactors = List<String>.from(keyFactors['team_strengths'][winningTeam]);
    }
    
    if (keyFactors.containsKey('team_weaknesses') && 
        keyFactors['team_weaknesses'].containsKey(losingTeam)) {
      losingFactors = List<String>.from(keyFactors['team_weaknesses'][losingTeam]);
    }
    
    // Additional context from key factors
    String matchupContext = '';
    if (keyFactors.containsKey('matchup_context')) {
      matchupContext = keyFactors['matchup_context'] as String? ?? '';
    }
    
    // Fallback if backend doesn't provide data
    if (winningFactors.isEmpty) {
      winningFactors = [
        'Superior offensive efficiency',
        'Better rebounding performance',
        'Higher 3-point shooting percentage',
      ];
    }
    
    if (losingFactors.isEmpty) {
      losingFactors = [
        'Weak perimeter defense',
        'Poor rebounding against larger teams',
        'Low 3-point shooting percentage',
      ];
    }
    
    if (matchupContext.isEmpty) {
      matchupContext = 'Based on recent performance and statistical analysis, $winningTeam has a higher probability of winning this game.';
    }
    
    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card title
            Text('Key Prediction Factors', style: headerStyle),
            const SizedBox(height: 16),
            
            // Matchup context paragraph
            Text(matchupContext, style: bodyStyle),
            const SizedBox(height: 16),
            
            // Winning team strengths
            Text(
              'Why $winningTeam is Favored:',
              style: subheaderStyle,
            ),
            const SizedBox(height: 8),
            ...winningFactors.map((factor) => _buildFactorRow(
              factor: factor,
              isPositive: true,
              isDarkMode: isDark,
            )),
            
            const SizedBox(height: 16),
            
            // Losing team weaknesses
            Text(
              'Why $losingTeam Falls Short:',
              style: subheaderStyle,
            ),
            const SizedBox(height: 8),
            ...losingFactors.map((factor) => _buildFactorRow(
              factor: factor,
              isPositive: false,
              isDarkMode: isDark,
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlayerImpactVisualization() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    // Text styles
    final headerStyle = GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
    );
    
    final playerNameStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Colors.black87,
    );
    
    final infoStyle = GoogleFonts.poppins(
      fontSize: 12,
      fontStyle: FontStyle.italic,
      color: isDark ? Colors.grey[400] : Colors.grey[600],
    );
    
    // Get sorted players by impact
    List<MapEntry<String, dynamic>> sortedPlayers = [];
    
    // First try to use the player impacts from the prediction service
    if (playerImpacts.isNotEmpty) {
      sortedPlayers = playerImpacts.entries.toList()
        ..sort((a, b) => (b.value as num).abs().compareTo((a.value as num).abs()));
    } 
    // If no player impacts are available, generate them from team player data
    else if (predictionData.containsKey('team1_players') || predictionData.containsKey('team2_players')) {
      // Create a temporary map to hold player impact values
      Map<String, double> generatedImpacts = {};
      
      // Process team 1 players
      if (predictionData.containsKey('team1_players') && 
          predictionData['team1_players'] is List) {
        final team1Players = predictionData['team1_players'] as List;
        for (final player in team1Players) {
          if (player is Map && player.containsKey('name') && player.containsKey('impact_factor')) {
            final name = player['name'];
            final impact = player['impact_factor'] as double;
            generatedImpacts[name] = impact;
          }
        }
      }
      
      // Process team 2 players
      if (predictionData.containsKey('team2_players') && 
          predictionData['team2_players'] is List) {
        final team2Players = predictionData['team2_players'] as List;
        for (final player in team2Players) {
          if (player is Map && player.containsKey('name') && player.containsKey('impact_factor')) {
            final name = player['name'];
            final impact = player['impact_factor'] as double;
            // Make team 2 player impacts negative by convention
            generatedImpacts[name] = -impact;
          }
        }
      }
      
      // Convert generated impacts to sortedPlayers format
      if (generatedImpacts.isNotEmpty) {
        sortedPlayers = generatedImpacts.entries.toList()
          ..sort((a, b) => (b.value).abs().compareTo((a.value).abs()));
      }
    }
    
    // Take only top players for visualization
    if (sortedPlayers.length > 5) {
      sortedPlayers = sortedPlayers.sublist(0, 5);
    }
    
    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card title
            Text('Player Impact on Prediction', style: headerStyle),
            const SizedBox(height: 8),
            
            // Info text
            Text(
              'These players have the most significant impact on the game prediction.',
              style: infoStyle,
            ),
            const SizedBox(height: 16),
            
            // Player impact bars
            if (sortedPlayers.isEmpty)
              Center(
                child: Text(
                  'No player impact data available',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              )
            else
              ...sortedPlayers.map((entry) {
                final playerName = entry.key;
                final impact = entry.value as double;
                final absImpact = impact.abs();
                final isPositive = impact > 0;
                final barColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
                
                // Get the player's team from the backend data
                String playerTeam = '';
                
                // Determine player's team based on team data from our prediction response
                if (predictionData.containsKey('team1_players') && 
                    predictionData['team1_players'] is List) {
                  final team1Players = predictionData['team1_players'] as List;
                  for (final player in team1Players) {
                    if (player is Map && player['name'] == playerName) {
                      playerTeam = widget.game.team1Name;
                      break;
                    }
                  }
                }
                
                // If not found in team1, check team2
                if (playerTeam.isEmpty && 
                    predictionData.containsKey('team2_players') && 
                    predictionData['team2_players'] is List) {
                  final team2Players = predictionData['team2_players'] as List;
                  for (final player in team2Players) {
                    if (player is Map && player['name'] == playerName) {
                      playerTeam = widget.game.team2Name;
                      break;
                    }
                  }
                }
                
                // Fallback: check team_players in keyFactors
                if (playerTeam.isEmpty && keyFactors.containsKey('team_players')) {
                  final teamPlayers = keyFactors['team_players'] as Map<String, dynamic>?;
                  if (teamPlayers != null) {
                    if (teamPlayers.containsKey(widget.game.team1Name)) {
                      final team1Players = teamPlayers[widget.game.team1Name] as List?;
                      if (team1Players != null && team1Players.contains(playerName)) {
                        playerTeam = widget.game.team1Name;
                      }
                    }
                    
                    if (playerTeam.isEmpty && teamPlayers.containsKey(widget.game.team2Name)) {
                      final team2Players = teamPlayers[widget.game.team2Name] as List?;
                      if (team2Players != null && team2Players.contains(playerName)) {
                        playerTeam = widget.game.team2Name;
                      }
                    }
                  }
                }
                
                // If we still don't have team info, provide a generic description
                if (playerTeam.isEmpty) {
                  playerTeam = "NBA";
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Player name and impact value
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$playerName ($playerTeam)',
                              style: playerNameStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(absImpact * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: barColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Impact bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          height: 8,
                          child: LinearProgressIndicator(
                            value: absImpact > 1.0 ? 1.0 : absImpact, // Cap at 100%
                            backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ),
                      
                      // Impact description
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          isPositive 
                            ? (playerTeam == widget.game.team1Name 
                               ? 'Key player for ${widget.game.team1Name}'
                               : 'Favors ${widget.game.team1Name} in prediction')
                            : (playerTeam == widget.game.team2Name 
                               ? 'Key player for ${widget.game.team2Name}'
                               : 'Favors ${widget.game.team2Name} in prediction'),
                          style: infoStyle,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    List<MapEntry<String, dynamic>> sortedPlayers = [];
    
    // Parse player impact data if available
    if (playerImpacts.isNotEmpty) {
      // Filter players based on selected team
      var filteredPlayers = playerImpacts.entries.where((entry) {
        double impact = entry.value is double ? entry.value : 0.0;
        
        if (_selectedPlayerTeam == 'All') {
          return true; // Show all players
        } else if (_selectedPlayerTeam == 'Team1') {
          return impact > 0; // Team 1 players have positive impact
        } else {
          return impact < 0; // Team 2 players have negative impact
        }
      }).toList();
      
      // Sort by absolute impact value
      sortedPlayers = filteredPlayers
        ..sort((a, b) => (b.value.abs() as num).compareTo(a.value.abs() as num));
    }
    
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team selection toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Key Player Impact',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                // Team selection segmented control
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTeamToggleButton('Team1', widget.game.team1Name),
                      _buildTeamToggleButton('All', 'All'),
                      _buildTeamToggleButton('Team2', widget.game.team2Name),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (sortedPlayers.isEmpty)
              Text(
                'No player impact data available for ${_selectedPlayerTeam == "Team1" ? widget.game.team1Name : _selectedPlayerTeam == "Team2" ? widget.game.team2Name : "selected teams"}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              )
            else
              ...sortedPlayers.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Card(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 24,
                          color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getImpactColor(entry.value is double ? entry.value : 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${((entry.value.abs() is double ? entry.value.abs() : 0.1) * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  // Helper method to build a team toggle button
  Widget _buildTeamToggleButton(String value, String label) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final isSelected = _selectedPlayerTeam == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlayerTeam = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? Colors.blue[700] : Colors.blue[600])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    List<Map<String, dynamic>> matchups = [];
    
    // Parse historical data if available
    if (historicalData.containsKey('head_to_head')) {
      try {
        matchups = List<Map<String, dynamic>>.from(historicalData['head_to_head']);
      } catch (e) {
        print('Error parsing historical data: $e');
      }
    }
    
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Head-to-Head History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            if (matchups.isEmpty)
              Text(
                'No historical matchup data available',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              )
            else
              ...matchups.map((matchup) => Card(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${matchup['date'] ?? 'Unknown Date'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${matchup['team1'] ?? widget.game.team1Name}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${matchup['score1'] ?? '0'} - ${matchup['score2'] ?? '0'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${matchup['team2'] ?? widget.game.team2Name}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _GameSummaryCard extends StatelessWidget {
  final Game game;

  const _GameSummaryCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final Color cardBgColor = isDark ? Colors.grey[800]! : Colors.white; // Match GameCard
    final Color cardBorderColor = isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB); // Match GameCard
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.black.withOpacity(0.6); // Match GameCard
    final Color detailTextColor = isDark ? Colors.grey[400]! : Colors.black.withOpacity(0.6); // Match GameCard's secondaryTextColor
    final Color probabilityBarBg = isDark ? Colors.grey[600]! : const Color(0xFFD9D9D9);
    final Color probabilityBarFill = const Color(0xFF9333EA);
    final double logoSize = 40.0;

    final teamTextStyle = GoogleFonts.poppins(
      color: textColor,
      fontSize: 11, // Adjust if needed
      fontWeight: FontWeight.w600,
    );
    final labelTextStyle = GoogleFonts.poppins(
      color: detailTextColor, // Home/Away uses detail color
      fontSize: 9, // Adjust if needed
      fontWeight: FontWeight.w400, // Adjust if needed
    );
    final winProbValueStyle = GoogleFonts.poppins(
      fontSize: 12, // Adjust size for combined display
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    final winProbLabelStyle = GoogleFonts.poppins(
      fontSize: 10,
      color: secondaryTextColor,
    );
     final detailTextStyle = GoogleFonts.poppins(
      color: detailTextColor,
      fontSize: 9,
      fontWeight: FontWeight.w400,
    );

    // Access state methods via context lookup if needed, or pass them
    // For simplicity here, assume _buildLogo is static or passed if required
    // Correct way: pass required functions/data in constructor or use Provider/InheritedWidget
    final logoBuilder = _TransparencyPageState()._buildLogo; // TEMPORARY direct access - fix if causes issues
    final dateTimeFormatter = _TransparencyPageState()._formatDateTime; // TEMPORARY

    return Container(
      width: 342,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: cardBorderColor, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start, // Align details left
         children: [
           IntrinsicHeight( // To help center probability vertically
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               crossAxisAlignment: CrossAxisAlignment.center, // Vertically align items in the row
               children: [
                 // Team 1 Column
                 Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     logoBuilder(game.team1LogoPath, logoSize),
                     const SizedBox(height: 4),
                     Text(game.team1Name, style: teamTextStyle),
                     Text('(Home)', style: labelTextStyle),
                   ],
                 ),
                 // Win Probability Column
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                     children: [
                       Text('Win Probability', style: winProbLabelStyle),
                       const SizedBox(height: 4),
                       Text(
                         '${(game.team1WinProbability * 100).toStringAsFixed(0)}% - ${(game.team2WinProbability * 100).toStringAsFixed(0)}%',
                         style: winProbValueStyle,
                       ),
                     ],
                   ),
                 ),
                 // Team 2 Column
                 Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     logoBuilder(game.team2LogoPath, logoSize),
                     const SizedBox(height: 4),
                     Text(game.team2Name, style: teamTextStyle),
                     Text('(Away)', style: labelTextStyle),
                   ],
                 ),
               ],
             ),
           ),
           const SizedBox(height: 16), // Space before progress bar
           // Progress Bar
           ClipRRect(
             borderRadius: BorderRadius.circular(100),
             child: SizedBox(
               height: 6,
               child: LinearProgressIndicator(
                 value: game.team1WinProbability,
                 backgroundColor: probabilityBarBg,
                 valueColor: AlwaysStoppedAnimation<Color>(probabilityBarFill),
               ),
             ),
           ),
           const SizedBox(height: 16), // Space before details
           // Gametime/Location Details (moved back inside)
           Text(
             'Gametime: ${dateTimeFormatter(game.gameDate, game.gameTime)}',
             style: detailTextStyle,
           ),
           const SizedBox(height: 4),
           Text(
             'Location: ${game.location}',
             style: detailTextStyle,
           ),
         ],
      ),
    );
  }
}
