// NBA team abbreviations to full names mapping
class NbaTeams {
  static const Map<String, String> abbreviationToName = {
    'ATL': 'Atlanta Hawks',
    'BKN': 'Brooklyn Nets',
    'BOS': 'Boston Celtics',
    'CHA': 'Charlotte Hornets',
    'CHI': 'Chicago Bulls',
    'CLE': 'Cleveland Cavaliers',
    'DAL': 'Dallas Mavericks',
    'DEN': 'Denver Nuggets',
    'DET': 'Detroit Pistons',
    'GSW': 'Golden State Warriors',
    'HOU': 'Houston Rockets',
    'IND': 'Indiana Pacers',
    'LAC': 'Los Angeles Clippers',
    'LAL': 'Los Angeles Lakers',
    'MEM': 'Memphis Grizzlies',
    'MIA': 'Miami Heat',
    'MIL': 'Milwaukee Bucks',
    'MIN': 'Minnesota Timberwolves',
    'NOP': 'New Orleans Pelicans',
    'NYK': 'New York Knicks',
    'OKC': 'Oklahoma City Thunder',
    'ORL': 'Orlando Magic',
    'PHI': 'Philadelphia 76ers',
    'PHX': 'Phoenix Suns',
    'POR': 'Portland Trail Blazers',
    'SAC': 'Sacramento Kings',
    'SAS': 'San Antonio Spurs',
    'TOR': 'Toronto Raptors',
    'UTA': 'Utah Jazz',
    'WAS': 'Washington Wizards',
  };

  // Get a list of all team names
  static List<String> getAllTeamNames() {
    return abbreviationToName.values.toList()..sort();
  }
  
  // Create a reverse mapping for team name to abbreviation
  static final Map<String, String> _nameToAbbreviation = {
    for (var entry in abbreviationToName.entries)
      entry.value: entry.key
  };
  
  // Get team abbreviation from team name
  static String? getTeamAbbreviation(String teamName) {
    // Try to find exact match
    if (_nameToAbbreviation.containsKey(teamName)) {
      return _nameToAbbreviation[teamName];
    }
    
    // Try to find case-insensitive match
    final lowerTeamName = teamName.toLowerCase();
    for (var entry in _nameToAbbreviation.entries) {
      if (entry.key.toLowerCase() == lowerTeamName) {
        return entry.value;
      }
    }
    
    // If no match found, return null
    return null;
  }
}
