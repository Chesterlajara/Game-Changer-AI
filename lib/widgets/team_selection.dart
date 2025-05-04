import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamSelectionCard extends StatelessWidget {
  final List<String> sampleTeams;
  final String? selectedTeam1;
  final String? selectedTeam2;
  final ValueChanged<String?> onTeam1Changed;
  final ValueChanged<String?> onTeam2Changed;

  const TeamSelectionCard({
    super.key,
    required this.sampleTeams,
    required this.selectedTeam1,
    required this.selectedTeam2,
    required this.onTeam1Changed,
    required this.onTeam2Changed,
  });

  @override
  Widget build(BuildContext context) {
    List<String> availableTeamsForTeam1 = sampleTeams
        .where((team) => team != selectedTeam2)
        .toList();
    List<String> availableTeamsForTeam2 = sampleTeams
        .where((team) => team != selectedTeam1)
        .toList();

    bool areBothTeamsSelected = selectedTeam1 != null && selectedTeam2 != null;

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Teams',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedTeam1,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: isDarkMode ? Colors.white30 : Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: const Color(0xFF365772)),
                ),
              ),
              dropdownColor: isDarkMode ? Colors.grey[850] : const Color(0xFFF4F4F4),
              hint: Text(
                'Select Team 1',
                style: GoogleFonts.poppins(fontSize: 10, color: isDarkMode ? Colors.white : Colors.black),
              ),
              items: availableTeamsForTeam1.map((team) {
                return DropdownMenuItem(
                  value: team,
                  child: Text(
                    team,
                    style: GoogleFonts.poppins(fontSize: 10, color: isDarkMode ? Colors.white : Colors.black),
                  ),
                );
              }).toList(),
              onChanged: areBothTeamsSelected ? null : onTeam1Changed,
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedTeam2,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              hint: Text(
                'Select Team 2',
                style: GoogleFonts.poppins(fontSize: 12, color: isDarkMode ? Colors.white : Colors.black),
              ),
              items: availableTeamsForTeam2.map((team) {
                return DropdownMenuItem(
                  value: team,
                  child: Text(
                    team,
                    style: GoogleFonts.poppins(fontSize: 12, color: isDarkMode ? Colors.white : Colors.black),
                  ),
                );
              }).toList(),
              onChanged: areBothTeamsSelected ? null : onTeam2Changed, // Disable if both teams are selected
            ),
          ],
        ),
      ),
    );
  }
}
