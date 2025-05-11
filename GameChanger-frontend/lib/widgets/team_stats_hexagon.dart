import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart'; // For computing original values

class TeamStatsHexagon extends StatelessWidget {
  final Map<String, double> team1Stats;
  final Map<String, double> team2Stats;
  final String team1Name;
  final String team2Name;
  final Color team1Color;
  final Color team2Color;
  
  // Maps to store original values (not normalized)
  final Map<String, double> team1RawStats;
  final Map<String, double> team2RawStats;
  
  const TeamStatsHexagon({
    super.key,
    required this.team1Stats,
    required this.team2Stats,
    required this.team1Name,
    required this.team2Name,
    this.team1Color = Colors.blue,
    this.team2Color = Colors.red,
    this.team1RawStats = const {
      'PPG': 106.5,
      '3PT': 36.7,
      'REB': 45.2,
      'AST': 25.8,
      'STL': 8.4,
      'BLK': 5.1,
    },
    this.team2RawStats = const {
      'PPG': 102.3,
      '3PT': 34.2,
      'REB': 42.5,
      'AST': 23.6,
      'STL': 7.6,
      'BLK': 4.2,
    },
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600; // Threshold for mobile layout
    final bool isVerySmallScreen = screenWidth < 360; // Extra small screens like older iPhones
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Team Statistics Comparison',
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(team1Name, team1Color, isDarkMode, context),
            const SizedBox(width: 24),
            _buildLegendItem(team2Name, team2Color, isDarkMode, context),
          ],
        ),
        const SizedBox(height: 12),
        
        // Stats and Hexagon chart layout - responsive
        if (isSmallScreen)
          // Mobile layout - Vertical arrangement
          Column(
            children: [
              // Hexagon chart (Top) - Adaptive sizing with no fixed height
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate an appropriate size based on screen width
                    // Use the smaller value between 65% of screen width or 200
                    final chartSize = min(screenWidth * 0.65, 200.0);
                    
                    return SizedBox(
                      width: chartSize,
                      height: chartSize,
                      child: CustomPaint(
                        painter: HexagonPainter(
                          team1Stats: team1Stats,
                          team2Stats: team2Stats,
                          team1Color: team1Color.withOpacity(0.7),
                          team2Color: team2Color.withOpacity(0.7),
                          labelColor: isDarkMode ? Colors.white : Colors.black87,
                          gridColor: isDarkMode ? Colors.white30 : Colors.black12,
                        ),
                      ),
                    );
                  }
                ),
              ),
              
              // Stats side by side
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0), // Further reduce horizontal padding for mobile
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center the stats columns
                  children: [
                    // Team 1 Stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: _buildStatLabels(
                          team1RawStats,
                          team1Color,
                          isDarkMode,
                          true,
                          context,
                          isVerySmallScreen // Pass flag for very small screens
                        ),
                      ),
                    ),
                    const SizedBox(width: 2), // Smaller space between columns
                    // Team 2 Stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: _buildStatLabels(
                          team2RawStats,
                          team2Color,
                          isDarkMode,
                          false,
                          context,
                          isVerySmallScreen, // Pass flag for very small screens
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          // Desktop layout - Original side-by-side arrangement
          Row(
            children: [
              // Team 1 Stats (Left Side)
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _buildStatLabels(
                    team1RawStats,
                    team1Color,
                    isDarkMode,
                    true, // left side
                    context,
                  ),
                ),
              ),
              
              // Hexagon chart (Center)
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 320,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(250, 250),
                      painter: HexagonPainter(
                        team1Stats: team1Stats,
                        team2Stats: team2Stats,
                        team1Color: team1Color.withOpacity(0.7),
                        team2Color: team2Color.withOpacity(0.7),
                        labelColor: isDarkMode ? Colors.white : Colors.black87,
                        gridColor: isDarkMode ? Colors.white30 : Colors.black12,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Team 2 Stats (Right Side)
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildStatLabels(
                    team2RawStats,
                    team2Color,
                    isDarkMode,
                    false, // right side
                    context,
                  ),
                ),
              ),
            ],
          ),
        
        // Insights
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stats Insights',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generateInsights(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String teamName, Color color, bool isDarkMode, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 8 : 12,
          height: isSmallScreen ? 8 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: isSmallScreen ? 3 : 6),
        Flexible(
          child: Text(
            teamName,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 10 : 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
  
  // Helper method to build stat labels for each side
  List<Widget> _buildStatLabels(Map<String, dynamic> stats, Color color, bool isDarkMode, bool isLeftSide, BuildContext context, [bool isVerySmallScreen = false]) {
    final statNames = ['PPG', 'FG3_PCT', 'REB', 'AST', 'STL', 'BLK'];
    final statLabels = ['Points', '3PT %', 'Rebounds', 'Assists', 'Steals', 'Blocks'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    final items = <Widget>[];
    
    for (int i = 0; i < statNames.length; i++) {
      final statName = statNames[i];
      final statLabel = statLabels[i];
      final statValue = stats[statName] ?? 0.0;
      final formattedValue = _formatStatValue(statName, statValue);
      
      // For small screens, we always center align the text
      // and use a more compact layout with stat name on top of value
      if (isSmallScreen) {
        // Even more compact layout for small screens
        final fontSize = isVerySmallScreen ? 8.0 : 9.0;
        final valueFontSize = isVerySmallScreen ? 9.0 : 10.0;
        
        final column = Padding(
          padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 2.0 : 3.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                statName,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isVerySmallScreen ? 1 : 2),
              Text(
                formattedValue,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: valueFontSize,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
        items.add(column);
      } else {
        // Original layout for larger screens
        final row = Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isLeftSide 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
            children: [
              if (isLeftSide) ...[              
                Text(
                  formattedValue,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  statName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ] else ...[              
                Text(
                  statName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  formattedValue,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        );
        items.add(row);
      }
    }
    
    return items;
  }
  
  // Helper to format the stat value appropriately
  String _formatStatValue(String statName, double value) {
    if (statName == '3PT') {
      return '${value.toStringAsFixed(1)}%'; // Format as percentage
    } else {
      return value.toStringAsFixed(1); // Regular format with 1 decimal
    }
  }
  
  String _generateInsights() {
    // Generate insights based on the stats comparison
    List<String> insights = [];
    
    // Find team1's strengths (stats where team1 > team2)
    List<MapEntry<String, double>> team1Strengths = [];
    List<MapEntry<String, double>> team2Strengths = [];
    
    team1Stats.forEach((stat, value) {
      final team2Value = team2Stats[stat] ?? 0;
      if (value > team2Value) {
        team1Strengths.add(MapEntry(stat, value - team2Value));
      } else if (team2Value > value) {
        team2Strengths.add(MapEntry(stat, team2Value - value));
      }
    });
    
    // Sort strengths by margin
    team1Strengths.sort((a, b) => b.value.compareTo(a.value));
    team2Strengths.sort((a, b) => b.value.compareTo(a.value));
    
    // Generate insights text
    if (team1Strengths.isNotEmpty) {
      final topStrengths = team1Strengths.take(2).map((e) => _formatStatName(e.key)).join(' and ');
      insights.add('$team1Name has an advantage in $topStrengths.');
    }
    
    if (team2Strengths.isNotEmpty) {
      final topStrengths = team2Strengths.take(2).map((e) => _formatStatName(e.key)).join(' and ');
      insights.add('$team2Name counters with superior $topStrengths.');
    }
    
    // Add conclusion based on overall comparison
    int team1HigherStats = team1Strengths.length;
    int team2HigherStats = team2Strengths.length;
    
    if (team1HigherStats > team2HigherStats) {
      insights.add('$team1Name shows statistical advantages in more categories, supporting their higher win probability.');
    } else if (team2HigherStats > team1HigherStats) {
      insights.add('Despite $team2Name having better stats in more areas, other factors like home court or recent form might be favoring $team1Name.');
    } else {
      insights.add('The teams are statistically well-matched, suggesting a close game.');
    }
    
    return insights.join(' ');
  }
  
  String _formatStatName(String statName) {
    // Format stat names for readability
    switch (statName) {
      case 'PPG':
        return 'scoring';
      case '3PT':
        return '3-point shooting';
      case 'REB':
        return 'rebounding';
      case 'AST':
        return 'assists';
      case 'STL':
        return 'steals';
      case 'BLK':
        return 'blocks';
      default:
        return statName.toLowerCase();
    }
  }
}

class HexagonPainter extends CustomPainter {
  final Map<String, double> team1Stats;
  final Map<String, double> team2Stats;
  final Color team1Color;
  final Color team2Color;
  final Color labelColor;
  final Color gridColor;
  
  HexagonPainter({
    required this.team1Stats,
    required this.team2Stats,
    required this.team1Color,
    required this.team2Color,
    required this.labelColor,
    required this.gridColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.8;
    
    // Draw grid and labels
    _drawHexagonGrid(canvas, center, radius);
    
    // Draw team stats
    _drawTeamStats(canvas, center, radius, team1Stats, team1Color);
    _drawTeamStats(canvas, center, radius, team2Stats, team2Color);
  }
  
  void _drawHexagonGrid(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5; // Even thinner lines for cleaner appearance on small screens
    
    // Draw concentric hexagons (5 levels)
    for (int i = 1; i <= 5; i++) {
      final levelRadius = radius * i / 5;
      final path = Path();
      
      for (int j = 0; j < 6; j++) {
        final angle = j * pi / 3;
        final x = center.dx + levelRadius * cos(angle);
        final y = center.dy + levelRadius * sin(angle);
        
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      path.close();
      canvas.drawPath(path, paint);
    }
    
    // Draw axes
    final statNames = ['PPG', '3PT', 'REB', 'AST', 'STL', 'BLK'];
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      // Draw axis line
      canvas.drawLine(
        center,
        Offset(x, y),
        paint,
      );
      
      // Draw label - More compact positioning for small screens
      final labelOffset = Offset(
        center.dx + (radius + 15) * cos(angle) - 10,
        center.dy + (radius + 15) * sin(angle) - 8,
      );
      
      textPainter.text = TextSpan(
        text: statNames[i],
        style: TextStyle(
          color: labelColor,
          fontSize: 8, // Even smaller font size for axis labels
          fontWeight: FontWeight.bold,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(canvas, labelOffset);
    }
  }
  
  void _drawTeamStats(Canvas canvas, Offset center, double radius, Map<String, double> stats, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final statNames = ['PPG', '3PT', 'REB', 'AST', 'STL', 'BLK'];
    bool firstPoint = true;
    
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final statName = statNames[i];
      final statValue = stats[statName] ?? 0.0;
      
      // Normalize value between 0 and 1
      final normalizedValue = statValue.clamp(0.0, 1.0);
      
      final distance = radius * normalizedValue;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);
      
      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
    
    // Draw stroke around the filled shape
    final strokePaint = Paint()
      ..color = color.withOpacity(1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawPath(path, strokePaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
