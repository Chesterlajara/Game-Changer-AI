import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_model.dart';
import '../utils/logo_helper.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../screens/analysis/transparency_page.dart'; // Import the new page
import 'package:google_fonts/google_fonts.dart';


class GameCard extends StatelessWidget {
  final Game game;


  const GameCard({super.key, required this.game});


  // Helper to format TimeOfDay (e.g., 8:00 AM)
  String _formatGameTime(TimeOfDay time) {
    // Create a DateTime object with today's date and the game's time
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    // Use intl package for formatting
    return DateFormat('h:mm a').format(dt); // e.g., 8:00 AM
  }
 
  // Helper to build team logo from URL or team name
  Widget _buildTeamLogo(String logoPath, double size) {
    // Use the unified LogoHelper to handle logo loading and fallbacks
    return LogoHelper.buildTeamLogo(logoPath, size);
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;


    // Define colors based on theme
    final Color cardBgColor = isDark ? Colors.grey[800]! : Colors.white;
    final Color cardBorderColor = isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.black.withOpacity(0.6);
    final Color probabilityBarBg = isDark ? Colors.grey[600]! : const Color(0xFFD9D9D9);
    final Color liveBadgeBg = isDark ? const Color(0xFF5A2D2D) : const Color(0xFFFEE2E2);
    final Color liveBadgeText = isDark ? Colors.red[200]! : const Color(0xFF991B1B);
    final Color analysisButtonTextColor = isDark ? Colors.white : Colors.black;


    return Container(
      width: 342,
      // height: 127, // Height can be dynamic based on content
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorderColor, width: 1),
        // Opacity can be applied here if needed, but might affect children
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make column height fit content
        children: [
          // Top Row: Live Badge / Time and View Analysis
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (game.status == GameStatus.live)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: liveBadgeBg,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Live',
                    style: GoogleFonts.poppins(
                      color: liveBadgeText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else if (game.status == GameStatus.upcoming && game.gameTime != null)
                Text(
                  _formatGameTime(game.gameTime!),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF000000), 
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                const SizedBox(height: 15), 
             
              // View Analysis Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end, 
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Navigate to the TransparencyPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TransparencyPage(game: game)), // Pass game object
                      );
                      print('Navigate to Analysis for ${game.team1Name} vs ${game.team2Name}'); 
                    },
                    // Swapped icon and label
                    icon: Text(
                      'View Analysis',
                      style: GoogleFonts.poppins(
                        color: analysisButtonTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    label: SvgPicture.asset(
                      'assets/icons/view_analysis_arrow.svg',
                      height: 12,
                      colorFilter: ColorFilter.mode(analysisButtonTextColor, BlendMode.srcIn),
                    ),


                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),


          // Middle Row: Logos, Names, Probabilities
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    // Team 1 Info
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Add Container around the logo
        Container(
          width: 40,
          height: 40,
          margin: EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: cardBorderColor, width: 1), 
        
          ),
          child: _buildTeamLogo(game.team1LogoPath, 40),
        ),
        const SizedBox(height: 5),
        Text(
          game.team1Name,
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
   
    // Probabilities
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Win Probability',
          style: GoogleFonts.poppins(
            color: secondaryTextColor,
            fontSize: 10,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Team 1 Probability
            Text(
              '${(game.team1WinProbability * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: (game.team1WinProbability > game.team2WinProbability)
                    ? 26 
                    : 22, 
                fontWeight: FontWeight.w500,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '-',
                style: GoogleFonts.poppins(
                  color: secondaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            // Team 2 Probability
            Text(
              '${(game.team2WinProbability * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: (game.team2WinProbability > game.team1WinProbability)
                    ? 23 
                    : 18, 
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),


    // Team 2 Info
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Add Container around the logo
        Container(
          width: 40,
          height: 40,
          margin: EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: cardBorderColor, width: 1), 
        
          ),
          child: _buildTeamLogo(game.team2LogoPath, 40),
        ),
        const SizedBox(height: 5),
        Text(
          game.team2Name,
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ],
),


          const SizedBox(height: 10),


          // Bottom Row: Probability Bar
          ClipRRect(
             borderRadius: BorderRadius.circular(100),
             child: SizedBox(
                width: 322,
                height: 6,
                child: Stack(
                  children: [
                    Container(
                      color: probabilityBarBg, 
                    ),
                    FractionallySizedBox(
                      widthFactor: game.team1WinProbability, 
                      child: Container(
                         decoration: BoxDecoration(
                            color: const Color(0xFF365772),
                            borderRadius: BorderRadius.circular(100), 
                         ),
                      ),
                    ),
                  ],
                ),
             ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}


