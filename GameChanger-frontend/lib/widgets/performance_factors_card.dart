import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PerformanceFactorsCard extends StatefulWidget {
  final Map<String, int> performanceFactors;
  final Function(String, int) onFactorChanged;

  const PerformanceFactorsCard({
    super.key,
    required this.performanceFactors,
    required this.onFactorChanged,
  });

  @override
  State<PerformanceFactorsCard> createState() => _PerformanceFactorsCardState();
}

class _PerformanceFactorsCardState extends State<PerformanceFactorsCard> {
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    double screenWidth = MediaQuery.of(context).size.width;

    double getFontSize(double baseSize) {
      if (screenWidth < 600) {
        return baseSize * 0.9;
      } else if (screenWidth < 1200) {
        return baseSize;
      } else {
        return baseSize * 1.1;
      }
    }

    return Card(
      color: isDarkMode ? Colors.grey[850] : const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Adjust corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Performance Factors',
                    style: GoogleFonts.poppins(
                      fontSize: getFontSize(15),
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Home Court Advantage slider
            _buildFactorSlider(
              context: context,
              factorName: 'home_court_advantage',
              displayName: 'Home Court Advantage',
              iconData: Icons.home,
              description: 'Boost for the home team',
              isDarkMode: isDarkMode,
              getFontSize: getFontSize,
            ),
            
            const SizedBox(height: 12),
            
            // Rest Days Impact slider
            _buildFactorSlider(
              context: context,
              factorName: 'rest_days_impact',
              displayName: 'Rest Days Impact',
              iconData: Icons.hotel,
              description: 'Impact of extra rest days',
              isDarkMode: isDarkMode,
              getFontSize: getFontSize,
            ),
            
            const SizedBox(height: 12),
            
            // Recent Form Weight slider
            _buildFactorSlider(
              context: context,
              factorName: 'recent_form_weight',
              displayName: 'Recent Form Weight',
              iconData: Icons.trending_up,
              description: 'Importance of recent performances',
              isDarkMode: isDarkMode,
              getFontSize: getFontSize,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFactorSlider({
    required BuildContext context,
    required String factorName,
    required String displayName,
    required IconData iconData,
    required String description,
    required bool isDarkMode,
    required double Function(double) getFontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              iconData,
              size: 18,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              displayName,
              style: GoogleFonts.poppins(
                fontSize: getFontSize(14),
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getFactorColor(widget.performanceFactors[factorName] ?? 5, isDarkMode),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  '${widget.performanceFactors[factorName] ?? 5}',
                  style: GoogleFonts.poppins(
                    fontSize: getFontSize(14),
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: getFontSize(12),
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF365772),
            inactiveTrackColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            thumbColor: const Color(0xFF000173),
            overlayColor: const Color(0x29000173),
            trackHeight: 4,
          ),
          child: Slider(
            value: (widget.performanceFactors[factorName] ?? 5).toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (value) {
              widget.onFactorChanged(factorName, value.round());
            },
          ),
        ),
      ],
    );
  }
  
  Color _getFactorColor(int value, bool isDarkMode) {
    if (value <= 3) {
      return Color(0xFFCF6679); // Low impact - reddish
    } else if (value <= 6) {
      return isDarkMode ? Colors.grey[600]! : Colors.amber[300]!; // Medium impact - amber
    } else {
      return Color(0xFF7FD858); // High impact - green
    }
  }
}
