import 'package:flutter/material.dart';

class LeagueLeadersSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> leaders;
  final String statLabel;
  final bool isTeam;
  
  const LeagueLeadersSection({
    Key? key,
    required this.title,
    required this.leaders,
    required this.statLabel,
    this.isTeam = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              leaders.length > 5 ? 5 : leaders.length,
              (index) => _buildLeaderItem(index, leaders[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderItem(int index, Map<String, dynamic> leader) {
    final String name = isTeam 
        ? leader['team_name'] ?? 'Unknown Team'
        : leader['player_name'] ?? 'Unknown Player';
    
    final String teamAbbr = isTeam 
        ? ''
        : leader['team_abbreviation'] ?? '';
    
    final dynamic statValue = leader['stat_value'] ?? 0.0;
    final String formattedValue = statValue is double
        ? statValue.toStringAsFixed(1)
        : statValue.toString();
    
    final String logoUrl = leader['logo_url'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Rank
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getRankColor(index),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Logo/Avatar
          if (logoUrl.isNotEmpty)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(logoUrl),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
              child: Icon(
                isTeam ? Icons.sports_basketball : Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          const SizedBox(width: 12),
          
          // Name and team
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (teamAbbr.isNotEmpty)
                  Text(
                    teamAbbr,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Stat value
          Text(
            '$formattedValue $statLabel',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber.shade700; // Gold
      case 1:
        return Colors.blueGrey.shade400; // Silver
      case 2:
        return Colors.brown.shade400; // Bronze
      default:
        return Colors.grey.shade600;
    }
  }
}
