import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PredictionInsightsCard extends StatelessWidget {
  final String team1Name;
  final String team2Name;
  final double team1WinProb;
  final double team2WinProb;
  final Map<String, dynamic> team1Stats;
  final Map<String, dynamic> team2Stats;
  final Map<String, dynamic> performanceFactors;
  final Map<String, double> playerImpacts;
  
  const PredictionInsightsCard({
    super.key,
    required this.team1Name,
    required this.team2Name,
    required this.team1WinProb,
    required this.team2WinProb,
    required this.team1Stats,
    required this.team2Stats,
    required this.performanceFactors,
    required this.playerImpacts,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Determine the predicted winner
    final String winningTeam = team1WinProb > team2WinProb ? team1Name : team2Name;
    final String losingTeam = team1WinProb > team2WinProb ? team2Name : team1Name;
    
    // Calculate the win margin (how decisive the prediction is)
    final double winMargin = (team1WinProb > team2WinProb)
        ? team1WinProb - team2WinProb
        : team2WinProb - team1WinProb;
        
    // Determine confidence level
    String confidenceLevel = "Uncertain";
    if (winMargin > 0.4) {
      confidenceLevel = "Very High";
    } else if (winMargin > 0.25) {
      confidenceLevel = "High";
    } else if (winMargin > 0.15) {
      confidenceLevel = "Moderate";
    } else if (winMargin > 0.05) {
      confidenceLevel = "Slight Edge";
    }
    
    // Get the top factors (strengths and weaknesses)
    List<String> winningFactors = _getWinningFactors();
    List<String> losingFactors = _getLosingFactors();
    
    // Get player impact factors
    List<MapEntry<String, double>> sortedPlayers = playerImpacts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<MapEntry<String, double>> topPlayers = sortedPlayers.take(3).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Prediction Insights',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            // Prediction Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$winningTeam is predicted to win',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: $confidenceLevel (${(winMargin * 100).toStringAsFixed(1)}% margin)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Key Factors Section
            Text(
              'Why $winningTeam Wins',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            
            // Winning team strengths
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
            
            // Losing team weaknesses
            ...losingFactors.map((factor) => _buildFactorRow(
              factor: factor,
              isPositive: false,
              isDarkMode: isDarkMode,
            )),
            
            const SizedBox(height: 16),
            
            // Key Players Impact
            if (topPlayers.isNotEmpty) ...[
              Text(
                'Key Players Impact',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              
              ...topPlayers.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: isDarkMode ? Colors.amber : Colors.amber[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getImpactColor(entry.value, isDarkMode),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(entry.value * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            const SizedBox(height: 16),
            
            // Performance Factors
            Text(
              'Performance Factors',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            
            // Home court advantage
            if (performanceFactors.containsKey('home_team')) ...[
              _buildPerformanceFactorRow(
                label: 'Home Court',
                value: performanceFactors['home_team'] == 1 
                    ? '$team1Name has home advantage'
                    : performanceFactors['home_team'] == 2
                        ? '$team2Name has home advantage'
                        : 'Neutral court',
                icon: Icons.home,
                isDarkMode: isDarkMode,
              ),
            ],
            
            // Rest days
            if (performanceFactors.containsKey('team1_rest_days') && 
                performanceFactors.containsKey('team2_rest_days')) ...[
              _buildPerformanceFactorRow(
                label: 'Rest Days',
                value: '${team1Name}: ${performanceFactors['team1_rest_days']} days, ' +
                       '${team2Name}: ${performanceFactors['team2_rest_days']} days',
                icon: Icons.hotel,
                isDarkMode: isDarkMode,
              ),
            ],
            
            // Recent form
            if (performanceFactors.containsKey('team1_recent_form') && 
                performanceFactors.containsKey('team2_recent_form')) ...[
              _buildPerformanceFactorRow(
                label: 'Recent Form',
                value: '${team1Name}: ${(performanceFactors['team1_recent_form'] * 100).toStringAsFixed(0)}% wins, ' +
                       '${team2Name}: ${(performanceFactors['team2_recent_form'] * 100).toStringAsFixed(0)}% wins',
                icon: Icons.trending_up,
                isDarkMode: isDarkMode,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  List<String> _getWinningFactors() {
    // This would ideally come from the prediction model's explanation
    // For now we'll generate some sample factors based on team stats
    List<String> factors = [
      'Superior offensive efficiency',
      'Better rebounding performance',
      'Higher 3-point shooting percentage',
      'Stronger defensive rating',
      'More depth with bench scoring',
      'More experienced roster',
    ];
    
    // Randomize to show 3-4 factors
    factors.shuffle();
    return factors.take(3).toList();
  }
  
  List<String> _getLosingFactors() {
    // This would ideally come from the prediction model's explanation
    List<String> factors = [
      'Weak perimeter defense',
      'Poor rebounding against larger teams',
      'Low 3-point shooting percentage',
      'Inconsistent scoring from starters',
      'Recent injuries affecting performance',
      'Poor performance in close games',
    ];
    
    // Randomize to show 3-4 factors
    factors.shuffle();
    return factors.take(3).toList();
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
                ? (isDarkMode ? Colors.green : Colors.green[700])
                : (isDarkMode ? Colors.red[300] : Colors.red[700]),
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
  
  Widget _buildPerformanceFactorRow({
    required String label,
    required String value,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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
  
  Color _getImpactColor(double value, bool isDarkMode) {
    if (value >= 0.15) {
      return Colors.red[700]!;
    } else if (value >= 0.10) {
      return Colors.orange[700]!;
    } else if (value >= 0.05) {
      return Colors.amber[700]!;
    } else {
      return Colors.blue[700]!;
    }
  }
}
