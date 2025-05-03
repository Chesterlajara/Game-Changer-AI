import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:game_changer_ai/providers/theme_provider.dart';
import 'package:intl/intl.dart'; // Ensure DateFormat import is present
import 'package:logging/logging.dart'; // Import logging package
import 'package:game_changer_ai/models/game_model.dart'; // Import game model
import 'package:game_changer_ai/widgets/game_card.dart'; // Import game card widget

// Setup logger for this file
final _log = Logger('GamePage');

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  DateTime selectedDate = DateTime.now(); // Initialize with today's date
  int _selectedTabIndex = 0; // State for active tab index (0: Today, 1: Upcoming, 2: Live)

  // --- Sample Game Data (Replace with actual data fetching) ---
  final List<Game> _allGames = [
    // Live Game Example (Today)
    Game(
      team1Name: 'Lakers',
      team1LogoPath: 'lakers.png',
      team1WinProbability: 0.65,
      team2Name: 'Celtics',
      team2LogoPath: 'celtics.png',
      team2WinProbability: 0.35,
      status: GameStatus.live,
      gameDate: DateTime.now(),
      location: 'Crypto.com Arena, Los Angeles', // Added location
    ),
    // Upcoming Game Example (Tomorrow)
    Game(
      team1Name: 'Nets',
      team1LogoPath: 'nets.png',
      team1WinProbability: 0.55,
      team2Name: 'Knicks',
      team2LogoPath: 'knicks.png',
      team2WinProbability: 0.45,
      status: GameStatus.upcoming,
      gameTime: const TimeOfDay(hour: 19, minute: 30), // 7:30 PM
      gameDate: DateTime.now().add(const Duration(days: 1)),
      location: 'Barclays Center, Brooklyn', // Added location
    ),
    Game(
      team1Name: 'Warriors',
      team1LogoPath: 'gsw.png',
      team1WinProbability: 0.70,
      team2Name: 'Clippers',
      team2LogoPath: 'clippers.png',
      team2WinProbability: 0.30,
      status: GameStatus.upcoming,
      gameTime: const TimeOfDay(hour: 20, minute: 00), // 8:00 PM
      gameDate: DateTime.now().add(const Duration(days: 1)), // Also tomorrow
      location: 'Chase Center, San Francisco', // Added location
    ),
    // Today (Finished/Not Live/Not Upcoming) Example
    Game(
      team1Name: 'Bucks',
      team1LogoPath: 'bucks.png',
      team1WinProbability: 0.40,
      team2Name: 'Bulls',
      team2LogoPath: 'chicago bulls.png',
      team2WinProbability: 0.60,
      status: GameStatus.today, 
      gameDate: DateTime.now(),
      location: 'United Center, Chicago', // Added location
    ),
    Game(
      team1Name: 'Heat',
      team1LogoPath: 'miami heat.png',
      team1WinProbability: 0.51,
      team2Name: 'Sixers',
      team2LogoPath: 'sixers.png',
      team2WinProbability: 0.49,
      status: GameStatus.live, 
      gameDate: DateTime.now(), // Also Live Today
      location: 'Wells Fargo Center, Philadelphia', // Added location
    ),
    // Yesterday's Game
    Game(
      team1Name: 'Spurs',
      team1LogoPath: 'spurs.png',
      team1WinProbability: 0.48,
      team2Name: 'Rockets',
      team2LogoPath: 'nba-houston-rockets-logo-2020.png',
      team2WinProbability: 0.52,
      status: GameStatus.today, // Marked as 'today' status for past finished game
      gameDate: DateTime.now().subtract(const Duration(days: 1)),
      location: 'Toyota Center, Houston', // Added location
    ),
  ];

  // Helper to compare dates ignoring time
  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Filtered list based on selected date AND tab
  List<Game> get _filteredGames {
    // Filter by date first
    List<Game> gamesOnSelectedDate = _allGames.where((game) => _isSameDate(game.gameDate, selectedDate)).toList();

    // Then filter by tab status
    switch (_selectedTabIndex) {
      case 0: // Today Tab - Show 'Live' or 'Today' status games for the selected date
        return gamesOnSelectedDate.where((game) => game.status == GameStatus.today || game.status == GameStatus.live).toList();
      case 1: // Upcoming Tab - Show 'Upcoming' status games for the selected date
        return gamesOnSelectedDate.where((game) => game.status == GameStatus.upcoming).toList();
      case 2: // Live Tab - Show only 'Live' status games for the selected date
        return gamesOnSelectedDate.where((game) => game.status == GameStatus.live).toList();
      default:
        return [];
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // Use state variable
      firstDate: DateTime(2000), // Adjust the range as needed
      lastDate: DateTime(2101),
      // Optional: Center the dialog
      builder: (BuildContext context, Widget? child) {
        return Theme(
          // You can customize the date picker theme here if needed
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.blue, // Example color
                  onPrimary: Colors.white,
                ),
          ),
          child: Center(child: child!),
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() { // Update the state variable
        selectedDate = picked;
      });
    }
  }

  // Helper method to build individual tabs
  Widget _buildTabItem(String title, int index) {
    bool isActive = _selectedTabIndex == index;
    // Access ThemeProvider for colors
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDark = themeProvider.isDarkMode;

    // Define colors based on theme
    final Color activeBgColor = isDark ? Colors.grey[700]! : Colors.white;
    final Color inactiveBgColor = Colors.transparent;
    final Color activeTextColor = isDark ? Colors.white : Colors.black;
    final Color inactiveTextColor = isDark ? Colors.grey[400]! : const Color(0xFF4B5563);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        // Active tab background
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : inactiveBgColor,
          borderRadius: BorderRadius.circular(5),
        ),
        // Fixed width and height for the active indicator area
        width: 103,
        height: 27,
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: isActive ? activeTextColor : inactiveTextColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Determine icon color based on the provider's theme state
    final iconColor = themeProvider.isDarkMode ? Colors.white : const Color(0xFF1E1E1E);
    final bool isDark = themeProvider.isDarkMode;
    final Color textColor = isDark ? Colors.white : Colors.black; // Text color for title

    // Define tab bar colors based on theme
    final Color tabBarBackgroundColor = isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9);
    final Color tabBarBorderColor = isDark ? Colors.grey[600]!.withOpacity(0.5) : const Color(0xFF374151).withOpacity(0.30);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2D3748) : Colors.transparent, // Set background color
        elevation: 0, // Keep shadow removed
        title: Text(
          'Game Changer AI',
          style: GoogleFonts.poppins(
            color: const Color(0xFF9333EA), // Keep specific title color
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // Calendar Icon
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/calendar.svg',
              width: 20,
              height: 19,
              // Apply color filter based on theme
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            onPressed: () => _selectDate(context),
            tooltip: 'Open Calendar',
          ),
          // Theme Toggle Icon
          IconButton(
            // Use themeProvider state to determine the icon
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: iconColor,
            ),
            onPressed: () {
              // Call the provider method to toggle the theme
              final bool isCurrentlyDark = themeProvider.isDarkMode;
              themeProvider.toggleTheme(!isCurrentlyDark);
            },
            // Update tooltip based on provider state
            tooltip: themeProvider.isDarkMode ? 'Switch to Light Theme' : 'Switch to Dark Theme',
          ),
          const SizedBox(width: 10), // Add some spacing
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), // Add some padding
        child: Column(
          children: [
            // Tab Bar Container
            Container(
              width: 343,
              height: 39,
              padding: const EdgeInsets.all(6), // Padding inside the container
              decoration: BoxDecoration(
                color: tabBarBackgroundColor, // Use theme-dependent background
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: tabBarBorderColor, // Use theme-dependent border color
                  width: 0.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTabItem('Today', 0),
                  _buildTabItem('Upcoming', 1),
                  _buildTabItem('Live', 2),
                ],
              ),
            ),
            const SizedBox(height: 20), // Spacing below tab bar

            // Section Title
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0), // Space below title
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  // Dynamic Title based on selected date
                  _isSameDate(selectedDate, DateTime.now())
                      ? "Today's Games"
                      : DateFormat('MMMM d, yyyy').format(selectedDate),
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Game List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredGames.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0), // Space between cards
                    child: GameCard(game: _filteredGames[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
