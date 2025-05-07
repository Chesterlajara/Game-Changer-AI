import 'package:flutter/material.dart';
import 'package:game_changer_ai/screens/game_page.dart';
import 'package:game_changer_ai/screens/stats_page.dart';
import 'package:game_changer_ai/screens/experiment_page.dart';
import 'package:provider/provider.dart';
import 'package:game_changer_ai/providers/theme_provider.dart';
import 'package:game_changer_ai/providers/game_provider.dart';
import 'package:game_changer_ai/providers/team_stats_provider.dart';
import 'package:logging/logging.dart'; // Import logging
import 'package:google_fonts/google_fonts.dart';


void main() {
  // Basic logging configuration
  Logger.root.level = Level.ALL; // Log all levels
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print -> Using print here intentionally for basic console logging
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => TeamStatsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);


    return MaterialApp(
      title: 'Game Changer AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF365772)),
        useMaterial3: true,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1E1E1E)),
          actionsIconTheme: IconThemeData(color: Color(0xFF1E1E1E)),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF365772),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});


  @override
  State<MainScreen> createState() => _MainScreenState();
}




class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;


  static const List<Widget> _widgetOptions = <Widget>[
    GamePage(),
    StatsPage(),
    ExperimentPage(),
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // Access theme provider
    final isDark = themeProvider.isDarkMode;
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFF4F4F4),
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                width: MediaQuery.of(context).size.width / 3,  // Make the width 1/3 of the screen width
                decoration: BoxDecoration(
                  color: _selectedIndex == 0
                      ? (isDark ? Colors.grey[700] : const Color(0xFFe1edf6))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _selectedIndex == 0
                          ? (isDark ? Colors.white : const Color(0xFF365772))
                          : (isDark ? Colors.white : Colors.black),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Game',  // Always show the label
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: _selectedIndex == 0
                                ? (isDark ? Colors.white : const Color(0xFF365772))
                                : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                width: MediaQuery.of(context).size.width / 3,  // Make the width 1/3 of the screen width
                decoration: BoxDecoration(
                  color: _selectedIndex == 1
                      ? (isDark ? Colors.grey[700] : const Color(0xFFe1edf6))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.query_stats,
                      color: _selectedIndex == 1
                          ? (isDark ? Colors.white : const Color(0xFF365772))
                          : (isDark ? Colors.white : Colors.black),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Stats',  // Always show the label
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: _selectedIndex == 1
                                ? (isDark ? Colors.white : const Color(0xFF365772))
                                : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                width: MediaQuery.of(context).size.width / 3,  // Make the width 1/3 of the screen width
                decoration: BoxDecoration(
                  color: _selectedIndex == 2
                      ? (isDark ? Colors.grey[700] : const Color(0xFFe1edf6))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.science_outlined,
                      color: _selectedIndex == 2
                                ? (isDark ? Colors.white : const Color(0xFF365772))
                                : (isDark ? Colors.white : Colors.black),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Experiment',  // Always show the label
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: _selectedIndex == 2
                                ? (isDark ? Colors.white : const Color(0xFF365772))
                                : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
        onTap: _onItemTapped,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400),
      ),
    );


  }
}









