import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:google_fonts/google_fonts.dart';

class PerformanceFactorsCard extends StatelessWidget {
  final double homeCourtAdvantage;
  final double restDaysImpact;
  final double recentFormWeight;
  final ValueChanged<double> onHomeCourtChanged;
  final ValueChanged<double> onRestDaysChanged;
  final ValueChanged<double> onRecentFormChanged;

  const PerformanceFactorsCard({
    super.key,
    required this.homeCourtAdvantage,
    required this.restDaysImpact,
    required this.recentFormWeight,
    required this.onHomeCourtChanged,
    required this.onRestDaysChanged,
    required this.onRecentFormChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? Colors.grey[850] : const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Factors',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection('Home Court Advantage', homeCourtAdvantage, onHomeCourtChanged, isDarkMode),
            const SizedBox(height: 16),
            _buildSection('Rest Days Impact', restDaysImpact, onRestDaysChanged, isDarkMode),
            const SizedBox(height: 16),
            _buildSection('Recent Form Weight', recentFormWeight, onRecentFormChanged, isDarkMode),
          ],
        ),
      ),
    );
  }

  String _getLabel(double value) {
    if (value < 3) return 'Low';
    if (value < 7) return 'Medium';
    return 'High';
  }

  Widget _buildSection(String title, double value, ValueChanged<double> onChanged, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              _getLabel(value),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.white54 : Colors.grey,
              ),
            ),
          ],
        ),
        FlutterSlider(
          values: [value],
          max: 10,
          min: 0,
          step: FlutterSliderStep(step: 0.1),
          handler: FlutterSliderHandler(
            decoration: const BoxDecoration(),
            child: Icon(
              Icons.circle,
              size: 10,
              color: isDarkMode? Colors.white: Color(0xFF365772),
            ),
          ),
          trackBar: FlutterSliderTrackBar(
            activeTrackBarHeight: 4,
            inactiveTrackBarHeight: 4,
            activeTrackBar: BoxDecoration(
              color: isDarkMode? Colors.white: Color(0xFF365772),
              borderRadius: BorderRadius.circular(25),
            ),
            inactiveTrackBar: BoxDecoration(
              color: isDarkMode ? Colors.grey[600]! : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          tooltip: FlutterSliderTooltip(
            alwaysShowTooltip: false,
            format: (String val) => double.parse(val).toStringAsFixed(1),
          ),
          onDragging: (handlerIndex, lowerValue, upperValue) {
            onChanged(lowerValue);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.white54 : Colors.black,
              ),
            ),
            Text(
              '5',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.white54 : Colors.black,
              ),
            ),
            Text(
              '10',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.white54 : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }
}