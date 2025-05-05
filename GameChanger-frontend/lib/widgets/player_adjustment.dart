import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';
import '../data/nba_teams.dart';

class PlayerAdjustmentsCard extends StatefulWidget {
  final String? selectedTeam1;
  final String? selectedTeam2;
  final String? selectedTeamForAdjustment;
  final Map<String, bool> playerAdjustments;
  final ValueChanged<String?> onTeamForAdjustmentChanged;
  final Function(String, bool) onPlayerAdjustmentChanged;

  const PlayerAdjustmentsCard({
    super.key,
    required this.selectedTeam1,
    required this.selectedTeam2,
    required this.selectedTeamForAdjustment,
    required this.playerAdjustments,
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
                margin: const EdgeInsets.only(right: 70.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Player Stats",
                      style: GoogleFonts.poppins(
                        fontSize: getFontSize(14),
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      "Active",
                      style: GoogleFonts.poppins(
                        fontSize: getFontSize(14),
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ..._players.map((player) => Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.playerName,
                              style: GoogleFonts.poppins(
                                fontSize: getFontSize(12),
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              player.statsString,
                              style: GoogleFonts.poppins(
                                fontSize: getFontSize(10),
                                color: isDarkMode ? Colors.white70 : Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.7,
                        child: Container(
                          margin: EdgeInsets.only(right: 70.0),
                          child: Switch(
                            value: widget.playerAdjustments[player.playerName] ?? true,
                            onChanged: (value) => widget.onPlayerAdjustmentChanged(player.playerName, value),
                            activeColor: const Color(0xFF000173),
                            thumbColor: MaterialStateProperty.all(Colors.white),
                            inactiveTrackColor: const Color(0xFFb2b2b2),
                          ),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}