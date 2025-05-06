import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/game_model.dart';
import '../../providers/theme_provider.dart';
import '../../services/prediction_service.dart';
import '../../services/team_stats_service.dart';
import '../../widgets/team_stats_hexagon.dart';

class TransparencyPage extends StatefulWidget {
  final Game game;

  const TransparencyPage({super.key, required this.game});

  @override
  State<TransparencyPage> createState() => _TransparencyPageState();
}

class _TransparencyPageState extends State<TransparencyPage> {
  int _selectedTabIndex = 0;

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
      // Fetch predictions and team stats in parallel
      final predictionFuture = PredictionService.predictWithPerformanceFactors(
        widget.game.team1Name,
        widget.game.team2Name,
        {}, // Empty player adjustments, get baseline prediction
        {
          'home_court_advantage': 5,
          'rest_days_impact': 5,
          'recent_form_weight': 5,
        },
      );
      
      // Fetch real team statistics from CSV data
      final teamStatsFuture = TeamStatsService.getTeamStats(
        widget.game.team1Name,
        widget.game.team2Name,
      );
      
      // Wait for both futures to complete
      final results = await Future.wait([predictionFuture, teamStatsFuture]);
      final predictionResult = results[0];
      final teamStatsResult = results[1];
      
      // Process the team stats to get both normalized and raw values
      final processedStats = TeamStatsService.processTeamStats(
        teamStatsResult,
        widget.game.team1Name,
        widget.game.team2Name,
      );
      
      setState(() {
        // Set prediction data
        predictionData = predictionResult;
        keyFactors = predictionResult['explanation_data'] ?? {};
        playerImpacts = predictionResult['player_impacts'] ?? {};
        historicalData = predictionResult['historical_data'] ?? {};
        
        // Set team stats from the real data
        team1Stats = processedStats['team1Stats'] ?? team1Stats;
        team2Stats = processedStats['team2Stats'] ?? team2Stats;
        team1RawStats = processedStats['team1RawStats'] ?? team1RawStats;
        team2RawStats = processedStats['team2RawStats'] ?? team2RawStats;
        
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching analysis data: $e');
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final winningTeam = widget.game.team1WinProbability > widget.game.team2WinProbability 
        ? widget.game.team1Name 
        : widget.game.team2Name;
    final losingTeam = widget.game.team1WinProbability > widget.game.team2WinProbability 
        ? widget.game.team2Name 
        : widget.game.team1Name;
    
    // Get team strengths and weaknesses from explanation data
    List<String> winningFactors = [];
    List<String> losingFactors = [];
    
    if (keyFactors.containsKey('team_strengths')) {
      if (keyFactors['team_strengths'].containsKey(winningTeam)) {
        winningFactors = List<String>.from(keyFactors['team_strengths'][winningTeam]);
      }
    }
    
    if (keyFactors.containsKey('team_weaknesses')) {
      if (keyFactors['team_weaknesses'].containsKey(losingTeam)) {
        losingFactors = List<String>.from(keyFactors['team_weaknesses'][losingTeam]);
      }
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
    
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hexagon Chart Section
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: TeamStatsHexagon(
              team1Stats: team1Stats,
              team2Stats: team2Stats,
              team1Name: widget.game.team1Name,
              team2Name: widget.game.team2Name,
              team1Color: Colors.blue,
              team2Color: Colors.red,
              team1RawStats: team1RawStats,
              team2RawStats: team2RawStats,
            ),
          ),
          
          // Divider
          Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          
          // Factors Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Winning team strengths
                Text(
                  'Why $winningTeam Wins',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                ...winningFactors.map((factor) => _buildFactorRow(
                  factor: factor,
                  isPositive: true,
                  isDarkMode: isDarkMode,
                )),
                
                const SizedBox(height: 16),
                
                // Losing team weaknesses
                Text(
                  'Why $losingTeam Falls Short',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                ...losingFactors.map((factor) => _buildFactorRow(
                  factor: factor,
                  isPositive: false,
                  isDarkMode: isDarkMode,
                )),
              ],
            ),
          ),
        ],
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
      sortedPlayers = playerImpacts.entries.toList()
        ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    }
    
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Player Impact',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            if (sortedPlayers.isEmpty)
              Text(
                'No player impact data available',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              )
            else
              ...sortedPlayers.take(10).map((entry) => Padding(
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
                            '${((entry.value is double ? entry.value : 0.1) * 100).toStringAsFixed(1)}%',
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
