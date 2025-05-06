import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';
import '../data/nba_teams.dart';

class PlayerAdjustmentsCard extends StatefulWidget {
  final String? selectedTeam1;
  final String? selectedTeam2;
  final String? selectedTeamForAdjustment;
  final Map<String, bool> playerAdjustments;
  final Map<String, double> playerImpactFactors;
  final ValueChanged<String?> onTeamForAdjustmentChanged;
  final Function(String, bool) onPlayerAdjustmentChanged;

  const PlayerAdjustmentsCard({
    super.key,
    required this.selectedTeam1,
    required this.selectedTeam2,
    required this.selectedTeamForAdjustment,
    required this.playerAdjustments,
    required this.playerImpactFactors,
    required this.onTeamForAdjustmentChanged,
    required this.onPlayerAdjustmentChanged,
  });

  @override
  State<PlayerAdjustmentsCard> createState() => _PlayerAdjustmentsCardState();
}

class _PlayerAdjustmentsCardState extends State<PlayerAdjustmentsCard> {
  List<PlayerData> _players = [];
  bool _isLoading = false;
  String? _error;

  @override
  void didUpdateWidget(PlayerAdjustmentsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the selected team for adjustment changed, load the players for that team
    if (widget.selectedTeamForAdjustment != oldWidget.selectedTeamForAdjustment &&
        widget.selectedTeamForAdjustment != null) {
      _loadPlayersForTeam(widget.selectedTeamForAdjustment!);
    }
  }

  Future<void> _loadPlayersForTeam(String teamName) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the team abbreviation from the team name
      final teamAbbreviation = NbaTeams.getTeamAbbreviation(teamName);
      if (teamAbbreviation == null) {
        setState(() {
          _isLoading = false;
          _error = 'Team abbreviation not found for $teamName';
          _players = [];
        });
        return;
      }

      // Load players for the team
      final players = await PlayerData.getPlayersForTeam(teamAbbreviation);

      // Initialize player adjustments for new players
      for (var player in players) {
        if (!widget.playerAdjustments.containsKey(player.playerName)) {
          widget.playerAdjustments[player.playerName] = true; // Default to active
        }
      }

      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading players: $e';
        _players = [];
      });
    }
  }

  // Get color for factor based on player impact and active status
  Color _getFactorColor(PlayerData player, bool isDarkMode) {
    // Get the impact factor - use the player's computed factor if not in the map
    double factor = widget.playerImpactFactors[player.playerName] ?? _calculatePlayerImpactFactor(player);
    bool isActive = widget.playerAdjustments[player.playerName] ?? true;
    
    // Check if player is active or inactive
    if (!isActive) {
      // Inactive player - use red shade
      return Color(0xFFEE6B6B); // Lighter red
    }
    
    // Color based on impact factor value for active players
    if (factor >= 0.15) {
      // High impact - star player
      return Color(0xFF7FD858); // Green
    } else if (factor >= 0.08) {
      // Medium-high impact
      return Color(0xFFADE985); // Light green
    } else if (factor >= 0.04) {
      // Medium impact
      return Color(0xFFE9DC85); // Yellow
    } else {
      // Low impact
      return isDarkMode ? Colors.grey[800]! : Colors.grey[200]!; // Default grey
    }
  }
  
  // Calculate a player's impact factor based on stats if not provided by API
  double _calculatePlayerImpactFactor(PlayerData player) {
    // Use the same formula as the backend
    double rawImpact = (0.4 * player.points + 0.2 * player.rebounds + 
                        0.2 * player.assists + 0.1 * player.steals + 
                        0.1 * player.blocks) / 100.0;
    
    // Clamp between 0.01 and 0.20 as the backend does
    return double.parse((rawImpact.clamp(0.01, 0.20)).toStringAsFixed(3));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    double getFontSize(double baseSize) {
      if (screenWidth < 600) {
        return baseSize * 0.9;
      } else if (screenWidth < 1200) {
        return baseSize;
      } else {
        return baseSize * 1.1;
      }
    }

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? Colors.grey[850] : const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Adjust corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Player Adjustments',
                    style: GoogleFonts.poppins(
                      fontSize: getFontSize(15),
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.selectedTeam1 != null && widget.selectedTeam2 != null)
                  Container(
                    width: screenWidth < 600 ? 120 : 150,
                    child: DropdownButtonFormField<String>(
                      value: widget.selectedTeamForAdjustment,
                      hint: Text(
                        'Select Team',
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(12),
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDarkMode ? Colors.white30 : Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: const Color(0xFF365772)),
                        ),
                      ),
                      dropdownColor: isDarkMode ? Colors.grey[850] : const Color(0xFFF4F4F4),
                      items: [
                        DropdownMenuItem(
                          value: widget.selectedTeam1,
                          child: Text(
                            widget.selectedTeam1!,
                            style: GoogleFonts.poppins(
                              fontSize: getFontSize(12),
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: widget.selectedTeam2,
                          child: Text(
                            widget.selectedTeam2!,
                            style: GoogleFonts.poppins(
                              fontSize: getFontSize(12),
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                      onChanged: widget.onTeamForAdjustmentChanged,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.selectedTeam1 == null || widget.selectedTeam2 == null)
              Center(
                child: Text(
                  'No players to show',
                  style: GoogleFonts.poppins(
                    fontSize: getFontSize(12),
                    color: isDarkMode ? Colors.white54 : Colors.grey,
                  ),
                ),
              )
            else if (widget.selectedTeamForAdjustment == null)
              Center(
                child: Text(
                  'Select a team to adjust players',
                  style: GoogleFonts.poppins(
                    fontSize: getFontSize(12),
                    color: isDarkMode ? Colors.white54 : Colors.grey,
                  ),
                ),
              )
            else if (_isLoading) ...[
              Center(
                child: CircularProgressIndicator(),
              ),
            ] else if (_error != null) ...[
              Center(
                child: Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    fontSize: getFontSize(12),
                    color: isDarkMode ? Colors.red[300] : Colors.red,
                  ),
                ),
              ),
            ] else if (_players.isEmpty) ...[
              Center(
                child: Text(
                  'No players found for ${widget.selectedTeamForAdjustment}',
                  style: GoogleFonts.poppins(
                    fontSize: getFontSize(12),
                    color: isDarkMode ? Colors.white54 : Colors.grey,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Name',
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(14),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Points',
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(14),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Rebounds',
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(12),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Assists',
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(14),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Factor',
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(14),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Active',
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(14),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ..._players.map((player) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? Colors.white12 : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        player.playerName,
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(13),
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        player.points.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(13),
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        player.rebounds.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(13),
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        player.assists.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(13),
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: _getFactorColor(player, isDarkMode),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          // Display impact factor if available, or calculate it
                          widget.playerImpactFactors.containsKey(player.playerName)
                              ? (widget.playerImpactFactors[player.playerName]! * 100).toStringAsFixed(1) + '%'
                              : (_calculatePlayerImpactFactor(player) * 100).toStringAsFixed(1) + '%',
                          style: GoogleFonts.poppins(
                            fontSize: getFontSize(13),
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: widget.playerAdjustments[player.playerName] ?? true,
                            onChanged: (value) => widget.onPlayerAdjustmentChanged(player.playerName, value),
                            activeColor: const Color(0xFF000173),
                            thumbColor: MaterialStateProperty.all(Colors.white),
                            inactiveTrackColor: const Color(0xFFb2b2b2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}