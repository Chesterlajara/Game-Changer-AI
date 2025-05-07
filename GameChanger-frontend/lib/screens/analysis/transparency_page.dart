import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../models/game_model.dart';
import '../../providers/theme_provider.dart';
import '../../utils/hex_color.dart';
import '../../utils/logo_helper.dart';
import '../../services/prediction_service.dart';
import '../../services/team_stats_service.dart';
import '../../services/game_analysis_service.dart';
import '../../widgets/team_stats_hexagon.dart';
import '../../data/player_data.dart';
import '../../data/nba_teams.dart';
import '../../data/team_matchup_data.dart';

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
    'FG3_PCT': 0.5,
    'REB': 0.7,
    'AST': 0.4,
    'STL': 0.5,
    'BLK': 0.3,
  };
  
  Map<String, double> team2Stats = {
    'PPG': 0.7,
    'FG3_PCT': 0.4,
    'REB': 0.6,
    'AST': 0.6,
    'STL': 0.4,
    'BLK': 0.5,
  };

  // Raw stats for display
  Map<String, dynamic> team1RawStats = {
    'PPG': 108.2,
    'FG3_PCT': 36.5,
    'REB': 44.2,
    'AST': 25.8,
    'STL': 7.3,
    'BLK': 4.2,
  };
  
  Map<String, dynamic> team2RawStats = {
    'PPG': 112.4,
    'FG3_PCT': 34.8,
    'REB': 41.6,
    'AST': 28.1,
    'STL': 6.7,
    'BLK': 5.3,
  };
  
  @override
  void initState() {
    super.initState();
    _fetchAnalysisData();
  }
  
  // Fetch analysis data from backend or CSV files
  Future<void> _fetchAnalysisData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Try to load from backend first
      final gameId = '1'; // Hardcoded for demo
      
      // Initialize data holders
      Map<String, dynamic> analysisData = {};
      Map<String, dynamic> playerImpactsData = {};
      Map<String, dynamic> keyFactorsData = {};
      Map<String, dynamic> historicalMatchupData = {};
      
      // Try to fetch team stats directly
      try {
        final teamStatsUrl = 'http://localhost:5000/api/team-stats/${widget.game.team1Name}/${widget.game.team2Name}';
        final teamStatsResponse = await http.get(Uri.parse(teamStatsUrl));
        
        if (teamStatsResponse.statusCode == 200) {
          // Successfully retrieved team stats
          final Map<String, dynamic> processedStats = _normalizeTeamStats(
            teamStatsResponse.body,
            team1Stats,
            team2Stats,
            team1RawStats,
            team2RawStats
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
      
      // APPROACH 2: Load player data directly from CSV files
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
        
        // PART 1: Load player data from CSV files for player impacts
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
          playerImpactsData = extractedPlayerImpacts;
        }
        
        // PART 2: Load historical matchup data from CSV files
        print('Loading head-to-head history data from CSV...');
        
        // Get the actual head-to-head matchups from the CSV file
        final headToHeadMatchups = await TeamMatchupData.getHeadToHeadMatchups(
          widget.game.team1Name, 
          widget.game.team2Name,
          limit: 5 // Show the 5 most recent matchups
        );
        
        print('Loaded ${headToHeadMatchups.length} historical matchups');
        
        // Convert the matchup data to the format expected by the UI
        final List<Map<String, dynamic>> matchupData = headToHeadMatchups.map((matchup) => {
          'date': matchup.date,
          'team1': matchup.team1,
          'team2': matchup.team2,
          'score1': matchup.score1.toString(),
          'score2': matchup.score2.toString(),
          'location': matchup.location,
        }).toList();
        
        // Add historical matchup data to the historicalMatchupData
        historicalMatchupData['head_to_head'] = matchupData;
        print('Added ${matchupData.length} historical matchups to UI data');
        
      } catch (e) {
        print('Error loading data from CSV files: $e');
        
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
        
        playerImpactsData = fallbackImpacts;
      }
      
      // Try to fetch game analysis data from the backend
      try {
        print('Fetching game analysis from backend...');
        final gameAnalysisResult = await GameAnalysisService.getGameAnalysis(gameId);
        
        if (gameAnalysisResult.isNotEmpty) {
          // Extract key factors
          if (gameAnalysisResult.containsKey('key_factors')) {
            keyFactorsData = gameAnalysisResult['key_factors'] as Map<String, dynamic>;
          }
          
          // Add any other data from game analysis to the predictionData
          analysisData = gameAnalysisResult;
        }
      } catch (e) {
        print('Error fetching game analysis: $e');
      }
      
      // Update the state with all the data
      setState(() {
        predictionData = analysisData;
        playerImpacts = playerImpactsData;
        keyFactors = keyFactorsData;
        historicalData = historicalMatchupData;
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
      'FG3_PCT': 45.0,  // Max 3-point percentage
      'REB': 55.0,  // Max rebounds
      'AST': 35.0,  // Max assists
      'STL': 12.0,  // Max steals
      'BLK': 8.0,   // Max blocks
    };
    
    // Map keys from API to our display names if needed
    final keyMapping = {
      'PTS': 'PPG',
      '3PT_PCT': 'FG3_PCT',
    };
    
    // Process each stat
    rawStats.forEach((key, value) {
      // Map the key if needed
      final displayKey = keyMapping[key] ?? key;
      
      // Check if this is a stat we want to display
      if (maxValues.containsKey(displayKey)) {
        // Convert to double if needed
        final doubleValue = value is double ? value : double.tryParse(value.toString()) ?? 0.0;
        
        // Normalize to 0-1 scale
        targetStats[displayKey] = (doubleValue / (maxValues[displayKey] ?? 100.0)).clamp(0.0, 1.0);
      }
    });
  }
  
  // Helper method to normalize team stats from CSV data
  Map<String, dynamic> _normalizeTeamStats(String data, Map<String, double> team1Stats, Map<String, double> team2Stats,
      Map<String, dynamic> team1RawStats, Map<String, dynamic> team2RawStats) {
    // Parse JSON data
    Map<String, dynamic> parsedData = {};
    try {
      parsedData = json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing team stats: $e');
      return {
        'team1Stats': team1Stats,
        'team2Stats': team2Stats,
        'team1RawStats': team1RawStats,
        'team2RawStats': team2RawStats,
      };
    }
    
    // Extract team stats from parsed data
    if (parsedData.containsKey('team1_stats') && parsedData.containsKey('team2_stats')) {
      Map<String, dynamic> team1Data = parsedData['team1_stats'] as Map<String, dynamic>;
      Map<String, dynamic> team2Data = parsedData['team2_stats'] as Map<String, dynamic>;
      
      // Normalize and set team 1 stats
      _normalizeAndSetTeamStats(team1Data, team1Stats);
      
      // Normalize and set team 2 stats
      _normalizeAndSetTeamStats(team2Data, team2Stats);
      
      // Store raw values for display
      team1Data.forEach((key, value) {
        team1RawStats[key] = value;
      });
      
      team2Data.forEach((key, value) {
        team2RawStats[key] = value;
      });
    }
    
    return {
      'team1Stats': team1Stats,
      'team2Stats': team2Stats,
      'team1RawStats': team1RawStats,
      'team2RawStats': team2RawStats,
    };
  }
  
  // Helper method to get color for player impact visualization
  Color _getImpactColor(double impact) {
    // Use green for positive impact (team 1) and red for negative impact (team 2)
    if (impact > 0) {
      // Team 1 - green shade by magnitude
      final magnitude = (impact * 5).clamp(0.3, 1.0);
      return Color.fromRGBO(0, (150 * magnitude).toInt(), 0, 1.0);
    } else {
      // Team 2 - red shade by magnitude
      final magnitude = (impact.abs() * 5).clamp(0.3, 1.0);
      return Color.fromRGBO((150 * magnitude).toInt(), 0, 0, 1.0);
    }
  }

  // Helper method to format date time
  String _formatDateTime(String dateTimeString) {
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return _formatDate(dateTime) + ', ' + _formatTime(dateTime.toString().split(' ')[1]);
    } catch (e) {
      return dateTimeString; // Return the original string if parsing fails
    }
  }
  
  // Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    
    final gameDay = DateTime(date.year, date.month, date.day);
    
    String datePart;
    if (gameDay == today) {
      datePart = 'Today';
    } else if (gameDay == tomorrow) {
      datePart = 'Tomorrow';
    } else if (gameDay == yesterday) {
      datePart = 'Yesterday';
    } else {
      datePart = DateFormat('MMM d').format(date); // e.g., May 1
    }

    return datePart;
  }
  
  // Format time for display
  String _formatTime(String timeString) {
    try {
      // Assuming timeString is in format "HH:mm:ss"
      final parts = timeString.split(':');
      if (parts.length < 2) return '';
      
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      
      // Convert to 12-hour format
      hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '$hour:$minute $period';
    } catch (e) {
      return timeString; // Return the original string if parsing fails
    }
  }
  
  // Helper method to get local logo path based on team name or abbreviation
  String _getLocalLogoPath(String teamNameOrPath) {
    // Extract team name from the path or URL if needed
    String teamName = teamNameOrPath.toLowerCase();
    
    // Extract team name from NBA CDN URLs
    if (teamName.contains('cdn.nba.com')) {
      // Extract team ID from the URL path
      RegExp teamIdRegex = RegExp(r'nba/(\d+)/global');
      var match = teamIdRegex.firstMatch(teamName);
      
      if (match != null) {
        String teamId = match.group(1) ?? '';
        // Map NBA team IDs to team names
        Map<String, String> teamIdMap = {
          '1610612747': 'okc', // Thunder
          '1610612742': 'dallas', // Mavericks
          '1610612744': 'gsw', // Warriors
          '1610612751': 'nets', // Nets
          '1610612745': 'nba-houston-rockets-logo-2020', // Rockets
          '1610612759': 'spurs', // Spurs
          '1610612748': 'miami heat', // Heat
          '1610612752': 'knicks', // Knicks
          // Add more mappings as needed
        };
        
        if (teamIdMap.containsKey(teamId)) {
          return teamIdMap[teamId]!;
        }
      }
    }
    
    // Process common team names or abbreviations
    if (teamName.contains('warriors')) return 'gsw';
    if (teamName.contains('lakers')) return 'lakers';
    if (teamName.contains('heat')) return 'miami heat';
    if (teamName.contains('celtics')) return 'celtics';
    if (teamName.contains('mav')) return 'dallas';
    if (teamName.contains('thunder') || teamName.contains('okc')) return 'okc';
    if (teamName.contains('net')) return 'nets';
    if (teamName.contains('spur')) return 'spurs';
    if (teamName.contains('knick')) return 'knicks';
    if (teamName.contains('rocket')) return 'nba-houston-rockets-logo-2020';
    if (teamName.contains('jazz')) return 'jazz';
    if (teamName.contains('buck')) return 'bucks';
    if (teamName.contains('cav')) return 'cavs';
    if (teamName.contains('bull')) return 'chicago bulls';
    if (teamName.contains('clippers')) return 'clippers';
    if (teamName.contains('grizzl')) return 'grizzlies';
    if (teamName.contains('hawk')) return 'hawks';
    if (teamName.contains('hornet')) return 'hornets';
    if (teamName.contains('king')) return 'kings';
    if (teamName.contains('nugget')) return 'nuggets';
    if (teamName.contains('magic')) return 'orlando magic';
    if (teamName.contains('pacer')) return 'pacers';
    if (teamName.contains('suns') || teamName.contains('phoenix')) return 'phoenix suns';
    if (teamName.contains('piston')) return 'pistons';
    if (teamName.contains('raptor')) return 'raptors';
    if (teamName.contains('sixers') || teamName.contains('76ers')) return 'sixers';
    if (teamName.contains('wolves') || teamName.contains('timberwolves')) return 'timberwolves';
    if (teamName.contains('blazers')) return 'trail blazers';
    if (teamName.contains('wizard')) return 'wizards';
    if (teamName.contains('pelican') || teamName.contains('new orleans')) return 'new orleans';
    
    // Default fallback
    return teamNameOrPath;
  }
  
  // Build logo widget with default size (convenience method)
  Widget _buildLogoWithDefaultSize(String logoPath) {
    return _buildLogo(logoPath, 80.0);
  }

  Widget _buildLogo(String logoPath, double size) {
    print('TransparencyPage logo path: $logoPath');
    
    // Use LogoHelper to handle logo loading and display
    return SizedBox(
      width: size,
      height: size,
      child: LogoHelper.buildTeamLogo(logoPath, size)
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final Color iconColor = isDark ? Colors.white : const Color(0xFF1D1B20);
    final Color titleColor = const Color(0xFF365772);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF4F4F4),
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
    );
  }
  
  // Build the tab bar
  Widget _buildTabBar() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200];
    final selectedColor = isDarkMode ? Colors.white : Colors.black;
    final unselectedColor = isDarkMode ? Colors.white70 : Colors.black54;
    final selectedTabColor = const Color(0xFF365772);
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // Key Factors tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? selectedTabColor : backgroundColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Key Factors',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                    color: _selectedTabIndex == 0 ? Colors.white : unselectedColor,
                  ),
                ),
              ),
            ),
          ),
          // Players tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? selectedTabColor : backgroundColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Players',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                    color: _selectedTabIndex == 1 ? Colors.white : unselectedColor,
                  ),
                ),
              ),
            ),
          ),
          // History tab
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 2 ? selectedTabColor : backgroundColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'History',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: _selectedTabIndex == 2 ? FontWeight.bold : FontWeight.normal,
                    color: _selectedTabIndex == 2 ? Colors.white : unselectedColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build the content for the selected tab
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
  
  // Key Factors Tab Content
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
                    team2Name: widget.game.team2Name,
                    team2Stats: team2Stats,
                    team1Color: Colors.blue,
                    team2Color: Colors.red,
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
  
  // Stats comparison table widget
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
      {'label': '3-Point %', 'team1Key': 'FG3_PCT', 'team2Key': 'FG3_PCT', 'format': '%.1f%%'},
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
            const SizedBox(height: 12),
            
            // Stat rows
            ...comparisonStats.map((stat) {
              // Get values from raw stats with fallbacks
              final team1Key = stat['team1Key'] as String;
              final team2Key = stat['team2Key'] as String;
              final format = stat['format'] as String;
              
              double team1Value = 0.0;
              double team2Value = 0.0;
              
              // Try to get values from raw stats, use defaults if not found
              if (team1RawStats.containsKey(team1Key)) {
                final value = team1RawStats[team1Key];
                team1Value = value is double ? value : 0.0;
              }
              
              if (team2RawStats.containsKey(team2Key)) {
                final value = team2RawStats[team2Key];
                team2Value = value is double ? value : 0.0;
              }
              
              // Format the values as strings
              String team1Str = format.contains('%') 
                  ? format.replaceAll('%.1f', (team1Value).toStringAsFixed(1))
                  : format.replaceAll('%.1f', team1Value.toStringAsFixed(1));
              
              String team2Str = format.contains('%') 
                  ? format.replaceAll('%.1f', (team2Value).toStringAsFixed(1))
                  : format.replaceAll('%.1f', team2Value.toStringAsFixed(1));
              
              // Determine which team has better stats (for highlighting)
              final bool team1Better = team1Value > team2Value;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
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
  
  Widget _buildFactorRow({
    required String factor,
    required bool isPositive,
    required bool isDarkMode,
  }) {
    final Color iconColor = isPositive ? Colors.green : Colors.red;
    final IconData icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              factor,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
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
          ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
      }
    }
    
    // Fallback to placeholder data if no real data is available
    if (sortedPlayers.isEmpty) {
      final Map<String, double> placeholderImpacts = {
        "${widget.game.team1Name} Star Player": 0.15,
        "${widget.game.team1Name} Second Option": 0.10,
        "${widget.game.team1Name} Role Player": 0.07,
        "${widget.game.team2Name} Star Player": -0.15,
        "${widget.game.team2Name} Second Option": -0.10,
        "${widget.game.team2Name} Role Player": -0.07,
      };
      
      sortedPlayers = placeholderImpacts.entries.toList()
        ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
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
            Text('Key Player Impacts', style: headerStyle),
            const SizedBox(height: 4),
            Text(
              'Players who contribute most significantly to their team\'s win probability',
              style: infoStyle,
            ),
            const SizedBox(height: 16),
            
            // Player impact bars
            ...sortedPlayers.take(6).map((entry) {
              final playerName = entry.key;
              final impact = entry.value is double ? entry.value as double : 0.0;
              final absImpact = impact.abs();
              
              // Determine which team this player is on
              final isTeam1 = impact > 0;
              final teamName = isTeam1 ? widget.game.team1Name : widget.game.team2Name;
              
              // Set colors based on team
              final barColor = isTeam1 ? Colors.blue.shade700 : Colors.red.shade700;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            playerName,
                            style: playerNameStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$teamName', 
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Impact value
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${(absImpact * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: barColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Impact bar
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: absImpact * 5, // Scale for better visualization
                              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(barColor),
                              minHeight: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Players Tab Content with team selection toggle
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
                    borderRadius: BorderRadius.circular(25),
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
              ? (isDarkMode ? Colors.blue[700] : const Color(0xFF365772))
              : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
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

  // History Tab Content - displaying head-to-head data from CSV
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${matchup['date'] ?? 'Unknown Date'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          if (matchup.containsKey('location'))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                matchup['location'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${matchup['team1'] ?? widget.game.team1Name}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
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
                          Expanded(
                            child: Text(
                              '${matchup['team2'] ?? widget.game.team2Name}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              textAlign: TextAlign.right,
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

// Game Summary Card Widget
class _GameSummaryCard extends StatelessWidget {
  final Game game;
  
  const _GameSummaryCard({required this.game});
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    // Card theme styling
    final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final cardBorderColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final double logoSize = 60.0;
    
    // Text styling
    final teamTextStyle = GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : Colors.black,
    );
    
    final labelTextStyle = GoogleFonts.poppins(
      fontSize: 12,
      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
    );
    
    final winProbLabelStyle = GoogleFonts.poppins(
      fontSize: 12,
      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
    );
    
    final winProbValueStyle = GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF365772),
    );
    
    // Logo builder function using the centralized LogoHelper
    Widget logoBuilder(String? logoPath, double size) {
      if (logoPath == null || logoPath.isEmpty) {
        return SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.sports_basketball,
            size: size * 0.8,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
        );
      }
      return LogoHelper.buildTeamLogo(logoPath, size);
    }
    
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12.0),
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
                       Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${(game.team1WinProbability * 100).toStringAsFixed(0)}%',
                              style: winProbValueStyle.copyWith(
                                fontSize: game.team1WinProbability >= game.team2WinProbability ? 29: 25,
                              ),
                            ),
                            const TextSpan(
                              text: ' - ',
                              style: TextStyle(fontSize: 20),
                            ),
                            TextSpan(
                              text: '${(game.team2WinProbability * 100).toStringAsFixed(0)}%',
                              style: winProbValueStyle.copyWith(
                                fontSize: game.team2WinProbability > game.team1WinProbability ? 29: 25,
                              ),
                            ),
                          ],
                        ),
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
         ],
      ),
    );
  }
}


