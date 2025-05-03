import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:game_changer_ai/providers/team_stats_provider.dart';
import 'package:game_changer_ai/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Teams'; // Teams or Players
  String _selectedConference = 'All'; // All, Eastern, Western
  String _selectedSortBy = 'Win %'; // Win %, Points, etc.
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch team stats when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeamStatsProvider>(context, listen: false).fetchTeamStats();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Statistics',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Filters Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Teams/Players Filter
                    _buildDropdownFilter(
                      value: _selectedFilter,
                      items: const ['Teams', 'Players'],
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
                        });
                      },
                    ),
                    
                    // Conference Filter
                    _buildDropdownFilter(
                      value: _selectedConference,
                      items: const ['All', 'Eastern', 'Western'],
                      onChanged: (value) {
                        setState(() {
                          _selectedConference = value!;
                        });
                      },
                    ),
                    
                    // Sort By Filter
                    _buildDropdownFilter(
                      value: _selectedSortBy,
                      items: const ['Win %', 'Points', 'Rebounds', 'Assists'],
                      onChanged: (value) {
                        setState(() {
                          _selectedSortBy = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tab Bar
              TabBar(
                controller: _tabController,
                labelColor: textColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.purple,
                tabs: const [
                  Tab(text: 'Standings'),
                  Tab(text: 'Offense'),
                  Tab(text: 'Defense'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Consumer<TeamStatsProvider>(
        builder: (context, statsProvider, child) {
          if (statsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (statsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading team stats: ${statsProvider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => statsProvider.fetchTeamStats(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              // Standings Tab
              _buildStandingsTab(statsProvider, textColor),
              
              // Offense Tab
              Center(child: Text('Offense Tab', style: TextStyle(color: textColor))),
              
              // Defense Tab
              Center(child: Text('Defense Tab', style: TextStyle(color: textColor))),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildDropdownFilter({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: value,
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 24,
        elevation: 16,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        underline: Container(height: 0),
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildStandingsTab(TeamStatsProvider statsProvider, Color textColor) {
    // This would normally use statsProvider.teamStats to build the standings table
    // For now, we'll show a placeholder with sample data
    
    final teams = [
      {'rank': 1, 'name': 'Celtics', 'wins': 64, 'losses': 18, 'pct': 0.780, 'streak': 'W4'},
      {'rank': 2, 'name': 'Bucks', 'wins': 58, 'losses': 24, 'pct': 0.707, 'streak': 'W2'},
      {'rank': 3, 'name': '76ers', 'wins': 54, 'losses': 28, 'pct': 0.659, 'streak': 'L1'},
    ];
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                Expanded(child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                SizedBox(width: 40, child: Text('W', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                SizedBox(width: 40, child: Text('L', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                SizedBox(width: 60, child: Text('Win %', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                SizedBox(width: 60, child: Text('Streak', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
              ],
            ),
          ),
          
          // Team Rows
          Expanded(
            child: ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Text('${team['rank']}', style: TextStyle(color: textColor))),
                      Expanded(child: Text('${team['name']}', style: TextStyle(fontWeight: FontWeight.w500, color: textColor))),
                      SizedBox(width: 40, child: Text('${team['wins']}', style: TextStyle(color: textColor))),
                      SizedBox(width: 40, child: Text('${team['losses']}', style: TextStyle(color: textColor))),
                      SizedBox(width: 60, child: Text('${team['pct']}', style: TextStyle(color: textColor))),
                      SizedBox(width: 60, child: Text('${team['streak']}', style: TextStyle(color: textColor))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
