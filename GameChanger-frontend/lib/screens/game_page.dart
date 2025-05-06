import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:game_changer_ai/providers/theme_provider.dart';
import 'package:game_changer_ai/providers/game_provider.dart';
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
  int _currentIndex = 0; // For bottom navigation


  @override
  void initState() {
    super.initState();
    // Fetch games when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false).fetchGames();
    });
  }


  // Helper to compare dates ignoring time
  bool _isSameDate(DateTime date1, DateTime date2) {
    final result = date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
   
    _log.info('Comparing dates: $date1 vs $date2 = $result');
   
    return result;
  }


  // Filtered list based on selected date AND tab
  List<Game> _getFilteredGames(List<Game> allGames) {
    // Log all games for debugging
    _log.info('All games count: ${allGames.length}');
   
    // Get current date for comparison
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
   
    // For Today and Live tabs, filter by selected date
    // For Upcoming tab, show all future games regardless of selected date
    List<Game> filteredGames;
   
    switch (_selectedTabIndex) {
      case 0: // Today Tab - Show 'Live' or 'Today' status games for the selected date
        // Filter by selected date first
        List<Game> gamesOnSelectedDate = allGames.where((game) => _isSameDate(game.gameDate, selectedDate)).toList();
        filteredGames = gamesOnSelectedDate.where((game) => game.status == GameStatus.today || game.status == GameStatus.live).toList();
        _log.info('Today tab games: ${filteredGames.length}');
        break;
       
      case 1: // Upcoming Tab - Show ALL future games grouped by date
        // Get all games with future dates (after today)
        final DateTime gameDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
       
        // If calendar is used, filter by that date
        if (gameDay.isAfter(today)) {
          // User selected a future date, so filter by that date
          filteredGames = allGames.where((game) =>
            _isSameDate(game.gameDate, selectedDate) &&
            game.status == GameStatus.upcoming
          ).toList();
        } else {
          // Show all upcoming games
          filteredGames = allGames.where((game) =>
            game.status == GameStatus.upcoming
          ).toList();
         
          // Sort by date
          filteredGames.sort((a, b) => a.gameDate.compareTo(b.gameDate));
        }
       
        _log.info('Upcoming tab games: ${filteredGames.length}');
        break;
       
      case 2: // Live Tab - Show only 'Live' status games for the current date
        // For Live games, only show games that are both live AND scheduled for today
        final now = DateTime.now();
        final currentDate = DateTime(now.year, now.month, now.day);
        filteredGames = allGames.where((game) =>
          game.status == GameStatus.live &&
          _isSameDate(game.gameDate, currentDate)
        ).toList();
        _log.info('Live tab games: ${filteredGames.length}');
        break;
       
      default:
        filteredGames = [];
    }
   
    return filteredGames;
  }


  void _selectDate(BuildContext context) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: selectedDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
    builder: (BuildContext context, Widget? child) {
  return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: const Color(0xFF365772),      
        onPrimary: Colors.white,               
        surface: Colors.white,               
        surfaceTint: Colors.transparent,      
        onSurface: Colors.black,               
      ),
      dialogBackgroundColor: Colors.white,     
      textTheme: GoogleFonts.poppinsTextTheme(
        Theme.of(context).textTheme,
      ),
    ),
    child: child!,
  );
},
  );
  if (picked != null && picked != selectedDate) {
    setState(() {
      selectedDate = picked;
    });
  }
}




  // Reset date filter to today's date
  void _resetDateFilter() {
    setState(() {
      selectedDate = DateTime.now();
      _log.info('Date filter reset to current date: $selectedDate');
    });
  }


  // Helper method to build individual tabs
  Widget _buildTabItem(String title, int index) {
    bool isActive = _selectedTabIndex == index;
    // Access ThemeProvider for colors
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDark = themeProvider.isDarkMode;


    final Color activeBgColor = isDark ? Colors.grey[700]! : Colors.white;
    final Color inactiveBgColor = Colors.transparent;
    final Color activeTextColor = isDark ? Colors.white : Colors.black;
    final Color inactiveTextColor = isDark ? Colors.grey[400]! : const Color(0xFF4B5563);


    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;


          // Reset date to today when Today tab is clicked
          if (index == 0) { // Today tab
            selectedDate = DateTime.now();
            _log.info('Today tab clicked, resetting date to: $selectedDate');
          }
        });
      },
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: Container(
                height: 40,
                width: MediaQuery.of(context).size.width / 3,
                decoration: BoxDecoration(
                  color: isActive
                  ? (isDark ? Colors.grey[800] : Color(0xFF365772))
                  : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          // Text container
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              title,
              style: GoogleFonts.poppins( 
            color: isActive ? Colors.white : Colors.black, 
            fontWeight: FontWeight.w700,
          ),
            ),
          ),
        ],
      ),
    );
  }


  // Helper method to get month name
  String _getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }


  // Helper to get tab title
  String _getTabTitle() {
    switch (_selectedTabIndex) {
      case 0:
        return "Today's Games";
      case 1:
        return "Upcoming Games";
      case 2:
        return "Live Games";
      default:
        return "Games";
    }
  }


  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Determine icon color based on the provider's theme state
    final iconColor = themeProvider.isDarkMode ? Colors.white : const Color(0xFF1E1E1E);
    final bool isDark = themeProvider.isDarkMode;
    final Color textColor = isDark ? Colors.white : Colors.black; 


    // Define tab bar colors based on theme
    final Color tabBarBackgroundColor = isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9);
    final Color tabBarBorderColor = isDark ? Colors.grey[600]!.withOpacity(0.5) : const Color(0xFF374151).withOpacity(0.30);


    return Scaffold(
       backgroundColor: themeProvider.isDarkMode ? Colors.black : const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? Colors.black : const Color(0xFFF4F4F4),
        elevation: 0, 
        title: Text(
          'Game Changer AI',
          style: GoogleFonts.poppins(
            color: const Color(0xFF365772), 
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
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), 
        child: Column(
          children: [
            // Tab Bar Container
            Container(
              width: 343,
              height: 39,
              decoration: BoxDecoration(
                color: tabBarBackgroundColor, 
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: tabBarBorderColor, 
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
            const SizedBox(height: 20),


            // Section Title with Refresh Button for Upcoming tab
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0), // Space below title
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    // Dynamic Title based on selected tab
                    _getTabTitle(),
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Show refresh button only in Upcoming tab
                  if (_selectedTabIndex == 1) // 1 is the index for Upcoming tab
                    IconButton(
                      icon: Icon(Icons.refresh, color: textColor),
                      tooltip: 'Show all upcoming games',
                      onPressed: _resetDateFilter,
                    ),
                ],
              ),
            ),


            // Game List
            Expanded(
              child: Consumer<GameProvider>(
                builder: (context, gameProvider, child) {
                  if (gameProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                 
                  if (gameProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error loading games: ${gameProvider.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => gameProvider.fetchGames(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                 
                  final filteredGames = _getFilteredGames(gameProvider.games);
                 
                  if (filteredGames.isEmpty) {
                    return Center(
                      child: Text(
                        'No games available for this selection',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }
                 
                  // For Upcoming tab, group games by date
                  if (_selectedTabIndex == 1) {
                    // Group games by date
                    Map<String, List<Game>> gamesByDate = {};
                   
                    for (var game in filteredGames) {
                      // Format date as key (e.g., "May 4, 2025")
                      String dateKey = "${_getMonthName(game.gameDate.month)} ${game.gameDate.day}, ${game.gameDate.year}";
                     
                      if (!gamesByDate.containsKey(dateKey)) {
                        gamesByDate[dateKey] = [];
                      }
                     
                      gamesByDate[dateKey]!.add(game);
                    }
                   
                    // Convert to list of widgets
                    List<Widget> dateGroups = [];
                   
                    gamesByDate.forEach((date, games) {
                      // Add date header
                      dateGroups.add(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16.0, 0, 8.0),
                          child: Text(
                            date,
                            style: GoogleFonts.poppins(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      );
                     
                      // Add games for this date
                      for (var game in games) {
                        dateGroups.add(GameCard(game: game));
                      }
                    });
                   
                    return RefreshIndicator(
                      onRefresh: () => gameProvider.fetchGames(),
                      child: ListView(
                        children: dateGroups,
                      ),
                    );
                  } else {
                    // Regular list for Today and Live tabs
                    return RefreshIndicator(
                      onRefresh: () => gameProvider.fetchGames(),
                      child: ListView.builder(
                        itemCount: filteredGames.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0), // Space between cards
                            child: GameCard(game: filteredGames[index]),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      // Bottom navigation is handled by MainScreen
    );
  }
}


