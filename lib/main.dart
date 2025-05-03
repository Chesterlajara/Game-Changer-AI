import 'package:flutter/material.dart';
import 'package:game_changer_ai/screens/game_page.dart';
import 'package:game_changer_ai/screens/stats_page.dart'; 
import 'package:game_changer_ai/screens/experiment_page.dart'; 
import 'package:provider/provider.dart'; 
import 'package:game_changer_ai/providers/theme_provider.dart'; 
import 'package:logging/logging.dart'; // Import logging

void main() {
  // Basic logging configuration
  Logger.root.level = Level.ALL; // Log all levels
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print -> Using print here intentionally for basic console logging
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
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
          seedColor: Colors.purple,
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
        backgroundColor: isDark ? const Color(0xFF2D3748) : null, // Use tab bar dark color
        type: BottomNavigationBarType.fixed, // Ensures background color is applied
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
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary, 
        unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600], // Optional: Adjust unselected item color too
        onTap: _onItemTapped, 
      ),
    );
  }
}
