import 'package:flutter/material.dart';
import '../models/prediction_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/logo_helper.dart';
import '../screens/analysis/prediction_transparency_page.dart';
import 'package:google_fonts/google_fonts.dart';

class PredictionCard extends StatelessWidget {
  final Prediction prediction;

  const PredictionCard({super.key, required this.prediction});
  
  // Helper to build team logo with border
  Widget _buildTeamLogo(String logoPath, double size, Color borderColor) {
    // Use the unified LogoHelper to handle logo loading, but wrap in a bordered container
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
      ),
      child: LogoHelper.buildTeamLogo(logoPath, size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final Color cardBgColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color cardBorderColor = isDarkMode ? Colors.grey[700]! : const Color(0xFFE5E7EB);
    final Color textColor = isDarkMode ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.black.withOpacity(0.6);
    final Color probabilityBarBg = isDarkMode ? Colors.grey[600]! : const Color(0xFFD9D9D9);

    return Card(
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PredictionTransparencyPage(prediction: prediction),
                      ),
                    );
                    print('Navigate to Analysis for ${prediction.team1Name} vs ${prediction.team2Name}');
                  },
                  icon: Text(
                    'View Analysis',
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  label: SvgPicture.asset(
                    'assets/icons/view_analysis_arrow.svg',
                    height: 12,
                    colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Team 1 Info
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTeamLogo(prediction.team1LogoPath, 40, cardBorderColor),
                    const SizedBox(height: 5),
                    Text(
                      prediction.team1Name,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 11,
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
                        fontSize: 8,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(prediction.team1WinProbability * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '-',
                            style: GoogleFonts.poppins(
                              color: secondaryTextColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Text(
                          '${(prediction.team2WinProbability * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  ],
                ),

                // Team 2 Info
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTeamLogo(prediction.team2LogoPath, 40, cardBorderColor),
                    const SizedBox(height: 5),
                    Text(
                      prediction.team2Name,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: SizedBox(
                width: double.infinity,
                height: 6,
                child: Stack(
                  children: [
                    Container(
                      color: probabilityBarBg,
                    ),
                    FractionallySizedBox(
                      widthFactor: prediction.team1WinProbability,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode? Colors.white: const Color(0xFF365772),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (prediction.keyFactors.isNotEmpty) ...[
              Text(
                'Key Factors',
                style: GoogleFonts.poppins(
                  color: secondaryTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: prediction.keyFactors.map((factor) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 10,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            factor,
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}