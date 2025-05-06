import 'package:flutter/material.dart';

/// Helper class for handling team logo loading and fallbacks
class LogoHelper {
  /// Maps team names or NBA CDN URLs to local logo files
  static String getLocalLogoPath(String teamNameOrPath) {
    // Convert to lowercase for easier matching
    String teamName = teamNameOrPath.toLowerCase();
    
    // Extract team name from NBA CDN URLs
    if (teamName.contains('cdn.nba.com')) {
      // Extract team ID from the URL path
      RegExp teamIdRegex = RegExp(r'nba/(\d+)/global');
      var match = teamIdRegex.firstMatch(teamName);
      
      if (match != null) {
        String teamId = match.group(1) ?? '';
        // Map NBA team IDs to team names
        Map<String, String> teamIdMap = {
          '1610612747': 'okc', // Thunder
          '1610612742': 'dallas', // Mavericks
          '1610612744': 'gsw', // Warriors
          '1610612751': 'nets', // Nets
          '1610612745': 'nba-houston-rockets-logo-2020', // Rockets
          '1610612759': 'spurs', // Spurs
          '1610612748': 'miami heat', // Heat
          '1610612752': 'knicks', // Knicks
          // Add more mappings as needed
        };
        
        if (teamIdMap.containsKey(teamId)) {
          return teamIdMap[teamId]!;
        }
      }
    }
    
    // Process common team names or abbreviations
    if (teamName.contains('warriors')) return 'gsw';
    if (teamName.contains('lakers')) return 'lakers';
    if (teamName.contains('heat')) return 'miami heat';
    if (teamName.contains('celtics')) return 'celtics';
    if (teamName.contains('mav')) return 'dallas';
    if (teamName.contains('thunder') || teamName.contains('okc')) return 'okc';
    if (teamName.contains('net')) return 'nets';
    if (teamName.contains('spur')) return 'spurs';
    if (teamName.contains('knick')) return 'knicks';
    if (teamName.contains('rocket')) return 'nba-houston-rockets-logo-2020';
    if (teamName.contains('jazz')) return 'jazz';
    if (teamName.contains('buck')) return 'bucks';
    if (teamName.contains('cav')) return 'cavs';
    if (teamName.contains('bull')) return 'chicago bulls';
    if (teamName.contains('clippers')) return 'clippers';
    if (teamName.contains('grizzl')) return 'grizzlies';
    if (teamName.contains('hawk')) return 'hawks';
    if (teamName.contains('hornet')) return 'hornets';
    if (teamName.contains('king')) return 'kings';
    if (teamName.contains('nugget')) return 'nuggets';
    if (teamName.contains('magic')) return 'orlando magic';
    if (teamName.contains('pacer')) return 'pacers';
    if (teamName.contains('suns') || teamName.contains('phoenix')) return 'phoenix suns';
    if (teamName.contains('piston')) return 'pistons';
    if (teamName.contains('raptor')) return 'raptors';
    if (teamName.contains('sixers') || teamName.contains('76ers')) return 'sixers';
    if (teamName.contains('wolves') || teamName.contains('timberwolves')) return 'timberwolves';
    if (teamName.contains('blazers')) return 'trail blazers';
    if (teamName.contains('wizard')) return 'wizards';
    if (teamName.contains('pelican') || teamName.contains('new orleans')) return 'new orleans';
    
    // Default fallback - just return what was passed
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
    String assetPath = 'assets/logos/$localLogoName.png';
    
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
          
          // Try without .png extension
          String altPath = 'assets/logos/$localLogoName';
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
