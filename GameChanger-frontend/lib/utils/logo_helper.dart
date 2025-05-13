import 'package:flutter/material.dart';

/// Helper class for handling team logo loading and fallbacks - exclusively using local assets
class LogoHelper {
  /// Maps team names or NBA CDN URLs to local logo files
  static String getLocalLogoPath(String teamNameOrPath) {
    // Convert to lowercase for easier matching
    String teamName = teamNameOrPath.toLowerCase();
    
    // Complete mapping of NBA team IDs to local logo filenames
    Map<String, String> teamIdMap = {
      // Eastern Conference
      '1610612738': 'celtics',         // Boston Celtics
      '1610612751': 'nets',           // Brooklyn Nets
      '1610612752': 'knicks',         // New York Knicks
      '1610612755': 'sixers',         // Philadelphia 76ers
      '1610612761': 'raptors',        // Toronto Raptors
      '1610612741': 'chicago bulls',  // Chicago Bulls
      '1610612739': 'cavs',           // Cleveland Cavaliers
      '1610612765': 'pistons',        // Detroit Pistons
      '1610612754': 'pacers',         // Indiana Pacers
      '1610612749': 'bucks',          // Milwaukee Bucks
      '1610612737': 'hawks',          // Atlanta Hawks
      '1610612766': 'hornets',        // Charlotte Hornets
      '1610612748': 'miami heat',     // Miami Heat
      '1610612753': 'orlando magic',  // Orlando Magic
      '1610612764': 'wizards',        // Washington Wizards
      
      // Western Conference
      '1610612743': 'nuggets',        // Denver Nuggets
      '1610612750': 'timberwolves',   // Minnesota Timberwolves
      '1610612760': 'okc',        // Oklahoma City Thunder (using 'okc' as filename)
      '1610612757': 'trail blazers',  // Portland Trail Blazers
      '1610612762': 'jazz',           // Utah Jazz
      '1610612744': 'gsw',            // Golden State Warriors
      '1610612746': 'clippers',       // Los Angeles Clippers
      '1610612747': 'lakers',         // Los Angeles Lakers
      '1610612756': 'phoenix suns',           // Phoenix Suns (using 'phoenix suns' as filename)
      '1610612758': 'kings',          // Sacramento Kings
      '1610612742': 'dallas',         // Dallas Mavericks
      '1610612745': 'nba-houston-rockets-logo-2020', // Houston Rockets
      '1610612763': 'grizzlies',      // Memphis Grizzlies
      '1610612740': 'new orleans',    // New Orleans Pelicans
      '1610612759': 'spurs'           // San Antonio Spurs
    };
    
    // Try to match by team ID if URL contains NBA CDN pattern
    if (teamName.contains('cdn.nba.com')) {
      RegExp teamIdRegex = RegExp(r'nba/(\d+)/global');
      var match = teamIdRegex.firstMatch(teamName);
      
      if (match != null) {
        String teamId = match.group(1) ?? '';
        if (teamIdMap.containsKey(teamId)) {
          return teamIdMap[teamId]!;
        }
      }
    }
    
    // Map common team names, abbreviations, and nicknames to local logo filenames
    // Eastern Conference
    if (teamName.contains('celtics') || teamName.contains('boston')) return 'celtics';
    if (teamName.contains('nets') || teamName.contains('brooklyn')) return 'nets';
    if (teamName.contains('knicks') || teamName.contains('new york')) return 'knicks';
    if (teamName.contains('76ers') || teamName.contains('sixers') || teamName.contains('philadelphia')) return 'sixers';
    if (teamName.contains('raptors') || teamName.contains('toronto')) return 'raptors';
    if (teamName.contains('bulls') || teamName.contains('chicago')) return 'chicago bulls';
    if (teamName.contains('cavaliers') || teamName.contains('cavs') || teamName.contains('cleveland')) return 'cavs';
    if (teamName.contains('pistons') || teamName.contains('detroit')) return 'pistons';
    if (teamName.contains('pacers') || teamName.contains('indiana')) return 'pacers';
    if (teamName.contains('bucks') || teamName.contains('milwaukee')) return 'bucks';
    if (teamName.contains('hawks') || teamName.contains('atlanta')) return 'hawks';
    if (teamName.contains('hornets') || teamName.contains('charlotte')) return 'hornets';
    if (teamName.contains('heat') || teamName.contains('miami')) return 'miami heat';
    if (teamName.contains('magic') || teamName.contains('orlando')) return 'orlando magic';
    if (teamName.contains('wizards') || teamName.contains('washington')) return 'wizards';
    
    // Western Conference
    if (teamName.contains('nuggets') || teamName.contains('denver')) return 'nuggets';
    if (teamName.contains('timberwolves') || teamName.contains('wolves') || teamName.contains('minnesota')) return 'timberwolves';
    if (teamName.contains('thunder') || teamName.contains('okc') || teamName.contains('oklahoma')) return 'okc';
    if (teamName.contains('blazers') || teamName.contains('portland') || teamName.contains('trail')) return 'trail blazers';
    if (teamName.contains('jazz') || teamName.contains('utah')) return 'jazz';
    if (teamName.contains('warriors') || teamName.contains('golden state') || teamName.contains('gsw')) return 'gsw';
    if (teamName.contains('clippers') || (teamName.contains('la') && !teamName.contains('lakers'))) return 'clippers';
    if (teamName.contains('lakers') || teamName.contains('los angeles la') && !teamName.contains('clippers')) return 'lakers';
    if (teamName.contains('suns') || teamName.contains('phoenix')) return 'phoenix suns';
    if (teamName.contains('kings') || teamName.contains('sacramento')) return 'kings';
    if (teamName.contains('mavericks') || teamName.contains('mavs') || teamName.contains('dallas')) return 'dallas';
    if (teamName.contains('rockets') || teamName.contains('houston')) return 'nba-houston-rockets-logo-2020';
    if (teamName.contains('grizzlies') || teamName.contains('memphis')) return 'grizzlies';
    if (teamName.contains('pelicans') || teamName.contains('new orleans')) return 'new orleans';
    if (teamName.contains('spurs') || teamName.contains('san antonio')) return 'spurs';
    
    // Default fallback - just return the original string
    // We'll handle logo not found in the buildTeamLogo method
    return teamNameOrPath;
  }
  
  /// Builds a team logo widget with proper fallbacks
  static Widget buildTeamLogo(String logoPath, double size, {Color? fallbackColor}) {
    // For logging
    print('Building team logo: $logoPath');
    
    // Handle empty path
    if (logoPath.isEmpty) {
      print('Empty logo path, showing fallback icon');
      return _buildFallbackIcon(size, fallbackColor: fallbackColor);
    }
    
    // Get the local logo name
    String localLogoName = getLocalLogoPath(logoPath);
    
    // First try with the exact filename (in case it already includes .png)
    String assetPath;
    if (localLogoName.endsWith('.png')) {
      assetPath = 'assets/logos/$localLogoName';
    } else {
      assetPath = 'assets/logos/$localLogoName.png';
    }
    
    print('Using local logo: $assetPath');
    return Container(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        height: size,
        width: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading logo: $assetPath - $error');
          
          // Try the filename without extension as a fallback
          String altPath;
          if (localLogoName.endsWith('.png')) {
            // Try removing the .png extension
            altPath = 'assets/logos/${localLogoName.substring(0, localLogoName.length - 4)}';
          } else {
            // Try the plain filename without adding .png
            altPath = 'assets/logos/$localLogoName';
          }
          
          print('Trying alternate path: $altPath');
          
          return Image.asset(
            altPath,
            height: size,
            width: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              print('Error loading alternate path, using fallback with initial');
              
              // Final fallback - show team initial in a circle
              String teamInitial = logoPath.isNotEmpty ? logoPath[0].toUpperCase() : '?';
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: fallbackColor ?? Colors.blueGrey,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    teamInitial,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.5,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  /// Builds a fallback icon for when no logo is available
  static Widget _buildFallbackIcon(double size, {Color? fallbackColor}) {
    return Icon(
      Icons.sports_basketball, 
      color: fallbackColor ?? Colors.grey, 
      size: size * 0.6
    );
  }
}
