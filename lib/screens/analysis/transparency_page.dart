import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/game_model.dart';
import '../../providers/theme_provider.dart';

class TransparencyPage extends StatefulWidget {
  final Game game;

  const TransparencyPage({super.key, required this.game});

  @override
  State<TransparencyPage> createState() => _TransparencyPageState();
}

class _TransparencyPageState extends State<TransparencyPage> {
  int _selectedTabIndex = 0;

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
            _buildTabContent(), // Add placeholder for tab content
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
    // Replace this with actual content based on _selectedTabIndex
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
