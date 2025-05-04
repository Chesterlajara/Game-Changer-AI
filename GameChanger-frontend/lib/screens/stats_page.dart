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
  
  // Sort options for teams
  final List<String> _teamSortOptions = ['Win %', 'Point Differential', 'Home Record', 'Away Record'];
  
  // Sort options for players
  final List<String> _playerSortOptions = ['Points', 'Rebounds', 'Assists', 'Steals', 'Blocks'];
  
  // Get current sort options based on selected filter
  List<String> get _currentSortOptions => _selectedFilter == 'Teams' ? _teamSortOptions : _playerSortOptions;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch stats when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStatsWithFilters();
    });
  }
  
  // Fetch stats with the selected filters
  void _fetchStatsWithFilters({bool forceRefresh = false}) {
    // Convert UI filter names to API parameter values
    String conference;
    if (_selectedConference == 'Eastern') {
      conference = 'East';
      print('StatsPage: Selected Eastern Conference, sending East to API');
    } else if (_selectedConference == 'Western') {
      conference = 'West';
      print('StatsPage: Selected Western Conference, sending West to API');
    } else {
      conference = '';
      print('StatsPage: Selected All Conferences, sending empty string to API');
    }
    
    // Convert sort by to stat category for player stats
    String statCategory = 'PTS'; // Default to points
    
    // Handle player sort options
    if (_selectedFilter == 'Players') {
      switch (_selectedSortBy) {
        case 'Points':
          statCategory = 'PTS';
          break;
        case 'Rebounds':
          statCategory = 'REB';
          break;
        case 'Assists':
          statCategory = 'AST';
          break;
        case 'Steals':
          statCategory = 'STL';
          break;
        case 'Blocks':
          statCategory = 'BLK';
          break;
        default:
          statCategory = 'PTS';
      }
    }
    
    // For teams, we'll use the sort option to determine how to sort the data
    // This would be handled on the frontend since we're not implementing
    // all these sort options in the backend yet
    String teamSortOption = '';
    if (_selectedFilter == 'Teams') {
      teamSortOption = _selectedSortBy;
    }
    
    // Fetch stats based on selected filter (Teams or Players)
    if (_selectedFilter == 'Teams') {
      print('StatsPage: Fetching team stats with conference: "$conference", sort by: "$_selectedSortBy", forceRefresh: $forceRefresh');
      Provider.of<TeamStatsProvider>(context, listen: false).fetchTeamStats(
        conference: conference,
        sortBy: _selectedSortBy,
        forceRefresh: forceRefresh
      );
    } else {
      print('StatsPage: Fetching player stats with conference: "$conference", sort by: "$_selectedSortBy", forceRefresh: $forceRefresh');
      Provider.of<TeamStatsProvider>(context, listen: false).fetchPlayerStats(
        conference: conference,
        sortBy: _selectedSortBy,
        forceRefresh: forceRefresh
      );
    }
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
                          // Reset sort option to the first option in the new list
                          _selectedSortBy = _currentSortOptions.first;
                          // Fetch stats with the new filter
                          _fetchStatsWithFilters();
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
                          // Fetch stats with the new conference filter
                          _fetchStatsWithFilters();
                        });
                      },
                    ),
                    
                    // Sort By Filter
                    _buildDropdownFilter(
                      value: _selectedSortBy,
                      items: _currentSortOptions,
                      onChanged: (value) {
                        setState(() {
                          _selectedSortBy = value!;
                          // Fetch stats with the new sort option for both Teams and Players
                          // Force refresh to ensure we get fresh data with the new sorting
                          _fetchStatsWithFilters(forceRefresh: true);
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
    // Use real data from the provider
    final bool showingPlayers = statsProvider.showingPlayers;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Conference filter info
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              statsProvider.currentConference == 'All' 
                ? (showingPlayers ? 'All Players' : 'All Teams')
                : '${statsProvider.currentConference} Conference ${showingPlayers ? 'Players' : 'Teams'}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          
          // Season info
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Season: ${statsProvider.season}',
                  style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
                ),
                if (statsProvider.standingsDate.isNotEmpty)
                  Text(
                    'Updated: ${statsProvider.standingsDate}',
                    style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
                  ),
              ],
            ),
          ),
          
          // Table Header - Different headers for Teams vs Players
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: showingPlayers
              ? Row(
                  children: [
                    SizedBox(width: 40, child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                    Expanded(child: Text('Player', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                    SizedBox(width: 60, child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                    SizedBox(width: 50, child: Text(statsProvider.currentStatCategory, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                    SizedBox(width: 50, child: Text('GP', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: 40, child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                    Expanded(child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                    SizedBox(width: 40, child: Text('W', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                    SizedBox(width: 40, child: Text('L', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                    // Dynamic column based on selected sort option
                    SizedBox(width: 80, child: Text(_selectedSortBy, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                    SizedBox(width: 60, child: Text('Streak', style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                  ],
                ),
          ),
          
          // Loading indicator or error message
          if (statsProvider.isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (statsProvider.error != null)
            Expanded(
              child: Center(
                child: Text(
                  'Error: ${statsProvider.error}',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (statsProvider.showingPlayers && statsProvider.players.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No player data available',
                  style: TextStyle(color: textColor),
                ),
              ),
            )
          else if (!statsProvider.showingPlayers && statsProvider.teams.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No team data available',
                  style: TextStyle(color: textColor),
                ),
              ),
            )
          // Team or Player Rows
          else
            Expanded(
              child: Column(
                children: [
                  // Count info
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      statsProvider.showingPlayers
                        ? 'Showing ${statsProvider.players.length} players'
                        : 'Showing ${statsProvider.teams.length} teams',
                      style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
                    ),
                  ),
                  // Scrollable list of teams or players
                  Expanded(
                    child: statsProvider.showingPlayers
                      ? _buildPlayersList(statsProvider, textColor)
                      : _buildTeamsList(statsProvider, textColor),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  // Helper method to build the teams list
  Widget _buildTeamsList(TeamStatsProvider statsProvider, Color textColor) {
    return ListView.builder(
      itemCount: statsProvider.teams.length,
      itemBuilder: (context, index) {
        final team = statsProvider.teams[index];
        // Format streak display
        String streakDisplay = '';
        if (team['streak_type'] != null && team['streak'] != null) {
          streakDisplay = '${team['streak_type']}${team['streak']}';
        }
        
        // Get the value to display based on the selected sort option
        String sortValueDisplay = '';
        switch (_selectedSortBy) {
          case 'Win %':
            sortValueDisplay = team['win_pct'].toStringAsFixed(3);
            break;
          case 'Point Differential':
            // Format point differential with sign and 1 decimal place
            double pointDiff = team['point_diff'] ?? 0.0;
            String sign = pointDiff > 0 ? '+' : '';
            sortValueDisplay = '$sign${pointDiff.toStringAsFixed(1)}';
            break;
          case 'Home Record':
            sortValueDisplay = team['home_record'] ?? 'N/A';
            break;
          case 'Away Record':
            sortValueDisplay = team['road_record'] ?? 'N/A';
            break;
          default:
            sortValueDisplay = team['win_pct'].toStringAsFixed(3);
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              SizedBox(width: 40, child: Text('${team['rank']}', style: TextStyle(color: textColor))),
              Expanded(child: Text('${team['team_name']}', style: TextStyle(fontWeight: FontWeight.w500, color: textColor))),
              SizedBox(width: 40, child: Text('${team['wins']}', style: TextStyle(color: textColor))),
              SizedBox(width: 40, child: Text('${team['losses']}', style: TextStyle(color: textColor))),
              SizedBox(width: 80, child: Text(sortValueDisplay, style: TextStyle(color: textColor))),
              SizedBox(width: 60, child: Text(streakDisplay, style: TextStyle(color: textColor))),
            ],
          ),
        );
      },
    );
  }
  
  // Helper method to build the players list
  Widget _buildPlayersList(TeamStatsProvider statsProvider, Color textColor) {
    return ListView.builder(
      itemCount: statsProvider.players.length,
      itemBuilder: (context, index) {
        final player = statsProvider.players[index];
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              SizedBox(width: 40, child: Text('${player['rank']}', style: TextStyle(color: textColor))),
              Expanded(child: Text('${player['player_name']}', style: TextStyle(fontWeight: FontWeight.w500, color: textColor))),
              SizedBox(width: 60, child: Text('${player['team_abbreviation'] ?? ''}', style: TextStyle(color: textColor))),
              SizedBox(width: 50, child: Text('${player['stat_value']?.toStringAsFixed(1) ?? '0.0'}', style: TextStyle(color: textColor))),
              SizedBox(width: 50, child: Text('${player['games_played'] ?? '0'}', style: TextStyle(color: textColor))),
            ],
          ),
        );
      },
    );
  }
}
