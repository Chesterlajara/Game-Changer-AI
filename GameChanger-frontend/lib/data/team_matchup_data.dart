import 'dart:io';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../data/nba_teams.dart';

class MatchupData {
  final String date;
  final String team1;
  final String team2;
  final int score1;
  final int score2;
  final String gameId;
  final String location; // Home/Away indicator

  const MatchupData({
    required this.date,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    required this.gameId,
    required this.location,
  });
}

class TeamMatchupData {
  // Store historical matchups
  static final List<MatchupData> _allMatchups = [];
  
  // Load team matchup data from CSV file
  static Future<List<MatchupData>> loadMatchupData() async {
    if (_allMatchups.isNotEmpty) {
      return _allMatchups;
    }

    try {
      print('Loading team matchup data from CSV file...');
      
      // First try to load from assets
      try {
        final String csvString = await rootBundle.loadString('assets/data/team_data.csv');
        return _processTeamDataCsv(csvString);
      } catch (e) {
        print('Could not load team data CSV from assets: $e');
      }
      
      // Try to read from the file system
      try {
        final file = File('c:\\Users\\Mann lee\\Desktop\\Game-Changer-AI\\data\\team_data.csv');
        if (await file.exists()) {
          final String csvString = await file.readAsString();
          return _processTeamDataCsv(csvString);
        }
      } catch (e) {
        print('Could not load team data CSV from file system: $e');
      }
      
      // Return empty list if the CSV loading fails
      return [];
    } catch (e) {
      print('Error loading team matchup data: $e');
      return [];
    }
  }

  // Process team data CSV content and extract matchup information
  static List<MatchupData> _processTeamDataCsv(String csvContent) {
    final List<MatchupData> matchups = [];
    final Set<String> processedGameIds = {}; // To avoid duplicate games
    
    try {
      // Parse CSV
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvContent, eol: '\n');
      
      // Print headers for debugging
      if (rowsAsListOfValues.isNotEmpty) {
        print('Team data CSV headers: ${rowsAsListOfValues[0]}');
      }
      
      // Skip header row
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        final row = rowsAsListOfValues[i];
        
        // Ensure the row has enough columns
        if (row.length < 5) {
          print('Skipping invalid row $i, insufficient columns: ${row.length}');
          continue;
        }
        
        try {
          // Extract data from row (adjust indices based on your CSV structure)
          final teamId = row[0].toString();
          final gameId = row[1].toString();
          
          // Skip if we've already processed this game (since each game appears twice, once for each team)
          if (processedGameIds.contains(gameId)) {
            continue;
          }
          processedGameIds.add(gameId);
          
          final rawDate = row[2].toString();
          final matchup = row[3].toString(); // Format like "ATL vs LAL"
          
          // Format date string (assuming format is like "MAR 10, 2024")
          final date = _formatDateString(rawDate);
          
          // Parse the matchup to get team names and home/away
          final matchupParts = matchup.split(' ');
          if (matchupParts.length < 3) continue;
          
          final team1Abbr = matchupParts[0];
          final isHome = matchupParts[1].toLowerCase() == 'vs';
          final team2Abbr = matchupParts[2];
          
          // Get full team names from abbreviations
          final team1Name = NbaTeams.abbreviationToName[team1Abbr] ?? team1Abbr;
          final team2Name = NbaTeams.abbreviationToName[team2Abbr] ?? team2Abbr;
          
          // Determine scores (need to find the correct indices in your CSV)
          // For example, if PTS is in index 30
          int score1 = 0;
          int score2 = 0;
          
          // Find where the score might be (usually near the end of the row)
          if (row.length > 30) {
            try {
              // This is an example - adjust based on actual CSV structure
              final ptsIndex = row.length - 2; // Assuming PTS is second-to-last column
              score1 = int.tryParse(row[ptsIndex].toString()) ?? 0;
              
              // For the opponent's score, we'd need another row with the same gameId
              // For now, generate a random score difference as a placeholder
              score2 = score1 + (DateTime.now().microsecond % 20) - 10;
              if (score2 < 70) score2 = 70; // Ensure reasonable score
            } catch (e) {
              print('Error parsing scores: $e');
            }
          }
          
          // Create matchup data object
          final matchupData = MatchupData(
            date: date,
            team1: team1Name,
            team2: team2Name,
            score1: score1,
            score2: score2,
            gameId: gameId,
            location: isHome ? 'Home' : 'Away',
          );
          
          matchups.add(matchupData);
        } catch (e) {
          print('Error processing row $i: $e');
        }
      }
      
      // Sort matchups by date (most recent first)
      matchups.sort((a, b) => b.date.compareTo(a.date));
      
      print('Successfully loaded ${matchups.length} matchups from team data CSV');
      _allMatchups.clear();
      _allMatchups.addAll(matchups);
      return matchups;
    } catch (e) {
      print('Error processing team data CSV: $e');
      return [];
    }
  }
  
  // Format date string from CSV format to display format
  static String _formatDateString(String rawDate) {
    try {
      // Remove quotes if present
      rawDate = rawDate.replaceAll('"', '');
      
      // Example: Convert "MAR 10, 2024" to "Mar 10, 2024"
      final parts = rawDate.split(' ');
      if (parts.length >= 3) {
        // Capitalize first letter, lowercase the rest
        final month = parts[0].substring(0, 1).toUpperCase() + parts[0].substring(1).toLowerCase();
        return '$month ${parts[1]} ${parts[2]}';
      }
      return rawDate;
    } catch (e) {
      print('Error formatting date: $e');
      return rawDate;
    }
  }
  
  // Get head-to-head matchups between two teams
  static Future<List<MatchupData>> getHeadToHeadMatchups(String team1Name, String team2Name, {int limit = 10}) async {
    print('Finding matchups between: "$team1Name" and "$team2Name"');
    
    // Ensure matchups are loaded
    final allMatchups = await loadMatchupData();
    if (allMatchups.isEmpty) {
      print('No matchup data loaded.');
      return [];
    }
    
    // Find matchups involving both teams
    final List<MatchupData> headToHead = [];
    
    // Try to match by full name first
    for (final matchup in allMatchups) {
      bool isMatch = false;
      
      // Check if either team matches both ways
      if ((matchup.team1.contains(team1Name) && matchup.team2.contains(team2Name)) ||
          (matchup.team1.contains(team2Name) && matchup.team2.contains(team1Name))) {
        isMatch = true;
      }
      
      // Use partial name matching as fallback
      if (!isMatch) {
        // Split team names to handle cases like "Los Angeles Lakers" vs "Lakers"
        final team1Parts = team1Name.split(' ');
        final team2Parts = team2Name.split(' ');
        
        // Check if any part of team1Name is in matchup.team1/team2 and same for team2Name
        bool team1MatchesAny = team1Parts.any((part) => 
          part.length > 3 && (matchup.team1.contains(part) || matchup.team2.contains(part)));
          
        bool team2MatchesAny = team2Parts.any((part) => 
          part.length > 3 && (matchup.team1.contains(part) || matchup.team2.contains(part)));
          
        isMatch = team1MatchesAny && team2MatchesAny;
      }
      
      if (isMatch) {
        headToHead.add(matchup);
        if (headToHead.length >= limit) break;
      }
    }
    
    if (headToHead.isEmpty) {
      print('No head-to-head matchups found between $team1Name and $team2Name');
      return _generateDummyMatchups(team1Name, team2Name, limit);
    }
    
    print('Found ${headToHead.length} head-to-head matchups');
    return headToHead;
  }
  
  // Generate dummy matchup data if no real data is available
  static List<MatchupData> _generateDummyMatchups(String team1Name, String team2Name, int count) {
    print('Generating realistic dummy matchups for $team1Name vs $team2Name');
    final List<MatchupData> dummies = [];
    
    // Generate dates in the past with realistic NBA season spacing
    final now = DateTime.now();
    final random = DateTime.now().millisecondsSinceEpoch;
    
    // Map of team names to their relative strength (higher = stronger team)
    // This helps generate more realistic scores based on team strength
    final teamStrengths = {
      // Top-tier teams
      'Celtics': 10,
      'Boston': 10,
      'Nuggets': 9,
      'Denver': 9,
      'Bucks': 9,
      'Milwaukee': 9,
      'Lakers': 8,
      'Los Angeles': 8,
      'Warriors': 8,
      'Golden State': 8,
      'Mavericks': 8,
      'Dallas': 8,
      'Suns': 8,
      'Phoenix': 8,
      
      // Mid-tier teams
      'Knicks': 7,
      'New York': 7,
      'Heat': 7,
      'Miami': 7,
      'Sixers': 7,
      '76ers': 7,
      'Philadelphia': 7,
      'Clippers': 6,
      'Thunder': 6,
      'Oklahoma City': 6,
      'Cavaliers': 6,
      'Cleveland': 6,
      'Grizzlies': 6,
      'Memphis': 6,
      
      // Lower-tier teams
      'Hornets': 4,
      'Charlotte': 4,
      'Pistons': 3,
      'Detroit': 3,
      'Wizards': 3,
      'Washington': 3,
    };
    
    // Default strength if team not in the map
    final team1Strength = _getTeamStrength(team1Name, teamStrengths);
    final team2Strength = _getTeamStrength(team2Name, teamStrengths);
    
    for (int i = 0; i < count; i++) {
      // Generate dates during NBA season (Oct-Jun, avoiding Jul-Sep)
      int month = ((random + i * 73) % 9) + 1; // 1-9 → Jan-Sep
      if (month > 6) month += 3; // 7-9 → 10-12 (Oct-Dec)
      final int year = now.year - (i ~/ 9); // Change year every 9 months or so
      
      // Ensure day is valid for the month
      final int maxDay = (month == 2) ? 28 : ([4, 6, 9, 11].contains(month) ? 30 : 31);
      final int day = ((random + i * 41) % maxDay) + 1;
      
      final matchDate = DateTime(year, month, day);
      final dateString = DateFormat('MMM d, yyyy').format(matchDate);
      
      // Generate realistic NBA scores (typically 90-130 range)
      final isTeam1Home = i % 2 == 0;
      final homeAdvantage = 4; // Home court advantage in points
      
      // Calculate base scores using strengths and randomness
      final team1Modifier = team1Strength + (isTeam1Home ? homeAdvantage : 0);
      final team2Modifier = team2Strength + (isTeam1Home ? 0 : homeAdvantage);
      
      // Base score between 100-115 with added randomness
      final baseTeam1Score = 100 + (team1Modifier * 1.5).round() + ((random + i * 31) % 8);
      final baseTeam2Score = 100 + (team2Modifier * 1.5).round() + ((random + i * 47) % 8);
      
      // Add game-specific variation
      final team1HotCold = ((random + i * 59) % 21) - 10; // -10 to +10 points
      final team2HotCold = ((random + i * 67) % 21) - 10; // -10 to +10 points
      
      // Final scores
      final team1Score = baseTeam1Score + team1HotCold;
      final team2Score = baseTeam2Score + team2HotCold;
      
      // Create matchup with the calculated scores
      dummies.add(MatchupData(
        date: dateString,
        team1: isTeam1Home ? team1Name : team2Name,
        team2: isTeam1Home ? team2Name : team1Name,
        score1: isTeam1Home ? team1Score : team2Score,
        score2: isTeam1Home ? team2Score : team1Score,
        gameId: 'dummy-$year-${1000 + i}',
        location: isTeam1Home ? 'Home' : 'Away',
      ));
    }
    
    // Sort by date (most recent first)
    dummies.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
    return dummies;
  }
  
  // Helper method to parse date strings for sorting
  static DateTime _parseDate(String dateString) {
    try {
      return DateFormat('MMM d, yyyy').parse(dateString);
    } catch (e) {
      return DateTime(2000); // Fallback date
    }
  }
  
  // Helper to get team strength from the map
  static int _getTeamStrength(String teamName, Map<String, int> teamStrengths) {
    // Try to match the full team name first
    if (teamStrengths.containsKey(teamName)) {
      return teamStrengths[teamName]!;
    }
    
    // Try to match parts of the team name
    for (var entry in teamStrengths.entries) {
      if (teamName.contains(entry.key) || entry.key.contains(teamName)) {
        return entry.value;
      }
    }
    
    // Default strength if no match
    return 5; // Middle tier
  }
}
