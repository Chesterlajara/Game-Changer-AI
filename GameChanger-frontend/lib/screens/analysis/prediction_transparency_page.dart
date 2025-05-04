import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/prediction_model.dart';
import '../../providers/theme_provider.dart';

class PredictionTransparencyPage extends StatefulWidget {
  final Prediction prediction;

  const PredictionTransparencyPage({super.key, required this.prediction});

  @override
  State<PredictionTransparencyPage> createState() => _TransparencyPageState();
}

class _TransparencyPageState extends State<PredictionTransparencyPage> {
  int _selectedTabIndex = 0;

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
        backgroundColor: isDark ? const Color(0xFF2D3748) : Colors.transparent,
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
          children: [
            _GameSummaryCard(prediction: widget.prediction),
            const SizedBox(height: 20),
            _buildTabBar(),
            const SizedBox(height: 20),
            _buildTabContent(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? const Color(0xFF2D3748) : null,
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
        currentIndex: 0,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
        onTap: (index) {
          if (Navigator.canPop(context)) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
      ),
    );
  }

  Widget _buildTabBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final List<String> tabs = ['Key factors', 'Players', 'History'];
    final double tabWidth = 103;
    final double tabHeight = 27;
    final double containerWidth = 342;
    final double containerHeight = 39;
    final double borderWidth = 0.2;
    final double innerWidth = containerWidth - (2 * borderWidth);
    final double horizontalPadding = (innerWidth - (tabs.length * tabWidth)) / 2;

    final Color selectedColor = isDark ? Colors.white : Colors.black;
    final Color unselectedColor = isDark ? Colors.grey[400]! : const Color(0xFF4B5563);
    final Color tabContainerBg = isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9);
    final Color tabContainerBorder = isDark ? Colors.grey[600]!.withOpacity(0.5) : const Color(0xFF374151).withOpacity(0.30);
    final Color selectedBg = isDark ? Colors.grey[700]! : Colors.white;

    return Container(
      width: containerWidth,
      height: containerHeight,
      decoration: BoxDecoration(
        color: tabContainerBg,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: tabContainerBorder, width: borderWidth),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: horizontalPadding + (_selectedTabIndex * tabWidth),
            child: Container(
              width: tabWidth,
              height: tabHeight,
              decoration: BoxDecoration(
                color: selectedBg,
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(tabs.length, (index) {
                final bool isSelected = _selectedTabIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  child: Container(
                    width: tabWidth,
                    height: tabHeight,
                    color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Text(
                      tabs[index],
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? selectedColor : unselectedColor,
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
    final List<String> tabs = ['Key factors', 'Players', 'History'];
    return Center(
      child: Text(
        'Content for: ${tabs[_selectedTabIndex]}',
        style: GoogleFonts.poppins(color: Provider.of<ThemeProvider>(context).isDarkMode ? Colors.white : Colors.black),
      ),
    );
  }
}

class _GameSummaryCard extends StatelessWidget {
  final Prediction prediction;

  const _GameSummaryCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final Color cardBgColor = isDark ? Colors.grey[800]! : Colors.white;
    final Color cardBorderColor = isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB);
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color secondaryTextColor = isDark ? Colors.grey[400]! : Colors.black.withOpacity(0.6);

    final teamTextStyle = GoogleFonts.poppins(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    final labelTextStyle = GoogleFonts.poppins(
      color: secondaryTextColor,
      fontSize: 9,
      fontWeight: FontWeight.w400,
    );
    final winProbValueStyle = GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    final winProbLabelStyle = GoogleFonts.poppins(
      fontSize: 10,
      color: secondaryTextColor,
    );

    final logoBuilder = _TransparencyPageState()._buildLogo;

    return Container(
      width: 342,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: cardBorderColor, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    logoBuilder(prediction.team1LogoPath, 40.0),
                    const SizedBox(height: 4),
                    Text(prediction.team1Name, style: teamTextStyle),
                    Text('(Home)', style: labelTextStyle),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Win Probability', style: winProbLabelStyle),
                      const SizedBox(height: 4),
                      Text(
                        '${(prediction.team1WinProbability * 100).toStringAsFixed(0)}% - ${(prediction.team2WinProbability * 100).toStringAsFixed(0)}%',
                        style: winProbValueStyle,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    logoBuilder(prediction.team2LogoPath, 40.0),
                    const SizedBox(height: 4),
                    Text(prediction.team2Name, style: teamTextStyle),
                    Text('(Away)', style: labelTextStyle),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: prediction.team1WinProbability,
                backgroundColor: Colors.grey[600]!,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF9333EA)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}