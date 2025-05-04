import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerAdjustmentsCard extends StatelessWidget {
  final String? selectedTeam1;
  final String? selectedTeam2;
  final String? selectedTeamForAdjustment;
  final List<String> samplePlayers;
  final Map<String, bool> playerAdjustments;
  final ValueChanged<String?> onTeamForAdjustmentChanged;
  final Function(String, bool) onPlayerAdjustmentChanged;

  const PlayerAdjustmentsCard({
    super.key,
    required this.selectedTeam1,
    required this.selectedTeam2,
    required this.selectedTeamForAdjustment,
    required this.samplePlayers,
    required this.playerAdjustments,
    required this.onTeamForAdjustmentChanged,
    required this.onPlayerAdjustmentChanged,
  });

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
                if (selectedTeam1 != null && selectedTeam2 != null)
                  Container(
                    width: screenWidth < 600 ? 120 : 150,
                    child: DropdownButtonFormField<String>(
                      value: selectedTeamForAdjustment,
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
                          value: selectedTeam1,
                          child: Text(
                            selectedTeam1!,
                            style: GoogleFonts.poppins(
                              fontSize: getFontSize(12),
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: selectedTeam2,
                          child: Text(
                            selectedTeam2!,
                            style: GoogleFonts.poppins(
                              fontSize: getFontSize(12),
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                      onChanged: onTeamForAdjustmentChanged,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (selectedTeam1 == null || selectedTeam2 == null)
              Center(
                child: Text(
                  'No players to show',
                  style: GoogleFonts.poppins(
                    fontSize: getFontSize(12),
                    color: isDarkMode ? Colors.white54 : Colors.grey,
                  ),
                ),
              )
            else if (selectedTeamForAdjustment == null)
              Center(
                child: Text(
                  'Select a team to adjust players',
                  style: GoogleFonts.poppins(
                    fontSize: getFontSize(12),
                    color: isDarkMode ? Colors.white54 : Colors.grey,
                  ),
                ),
              )
            else ...[
                Container(
                  margin: const EdgeInsets.only(right: 70.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Active",
                      style: GoogleFonts.poppins(
                        fontSize: getFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...samplePlayers.map((player) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$player ($selectedTeamForAdjustment)',
                        style: GoogleFonts.poppins(
                          fontSize: getFontSize(12),
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.7,
                      child: Container(
                        margin: EdgeInsets.only(right: 70.0),
                        child: Switch(
                          value: playerAdjustments[player] ?? false,
                          onChanged: (value) => onPlayerAdjustmentChanged(player, value),
                          activeColor: const Color(0xFF000173),
                          thumbColor: MaterialStateProperty.all(Colors.white),
                          inactiveTrackColor: const Color(0xFFb2b2b2),
                        ),
                      ),
                    ),
                  ],
                )),
              ],
          ],
        ),
      ),
    );
  }
}
