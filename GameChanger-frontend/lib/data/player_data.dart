import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class PlayerData {
  final String playerId;
  final String playerName;
  final String teamId;
  final String teamAbbreviation;
  final String minutes;
  final double points;
  final double rebounds;
  final double assists;
  final double steals;
  final double blocks;
  final double fieldGoalPct;
  final double threePointPct;

  // Format player stats for display
  String get statsString => '${points.toStringAsFixed(1)} PPG | ${rebounds.toStringAsFixed(1)} REB | ${assists.toStringAsFixed(1)} AST';

  const PlayerData({
    required this.playerId,
    required this.playerName,
    required this.teamId,
    required this.teamAbbreviation,
    required this.minutes,
    required this.points,
    required this.rebounds,
    required this.assists,
    required this.steals,
    required this.blocks,
    required this.fieldGoalPct,
    required this.threePointPct,
  });

  // Store player data by team abbreviation
  static final Map<String, List<PlayerData>> _playersByTeam = {};

  // Load player data from CSV file
  static Future<Map<String, List<PlayerData>>> loadPlayerData() async {
    if (_playersByTeam.isNotEmpty) {
      return _playersByTeam;
    }

    try {
      print('Loading player data from CSV file...');
      
      // First try to load from CSV file
      final csvData = await _loadPlayerDataFromCsv();
      if (csvData.isNotEmpty) {
        _playersByTeam.addAll(csvData);
        return csvData;
      }
      
      // Fallback to hardcoded data if CSV loading fails
      print('Falling back to hardcoded player data...');
      final hardcodedPlayers = _loadHardcodedPlayers();
      _playersByTeam.addAll(hardcodedPlayers);
      return hardcodedPlayers;
    } catch (e) {
      print('Error loading player data: $e');
      // Fallback to hardcoded data if there's an error
      final hardcodedPlayers = _loadHardcodedPlayers();
      _playersByTeam.addAll(hardcodedPlayers);
      return hardcodedPlayers;
    }
  }
  
  // Load player data from CSV file
  static Future<Map<String, List<PlayerData>>> _loadPlayerDataFromCsv() async {
    try {
      final Map<String, List<PlayerData>> playersByTeam = {};
      
      // Try to read from the assets first
      try {
        final String csvString = await rootBundle.loadString('assets/data/updated_player_data.csv');
        return _processCsvContent(csvString);
      } catch (e) {
        print('Could not load CSV from assets: $e');
      }
      
      // Try to read from the file system
      try {
        final file = File('c:\\Users\\Mann lee\\Desktop\\Game-Changer-AI\\data\\updated_player_data.csv');
        if (await file.exists()) {
          final String csvString = await file.readAsString();
          return _processCsvContent(csvString);
        }
      } catch (e) {
        print('Could not load CSV from file system: $e');
      }
      
      return {};
    } catch (e) {
      print('Error loading player data from CSV: $e');
      return {};
    }
  }
  
  // Process CSV content and convert to PlayerData objects
  static Map<String, List<PlayerData>> _processCsvContent(String csvContent) {
    final Map<String, List<PlayerData>> playersByTeam = {};
    
    try {
      // Parse CSV
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvContent, eol: '\n');
      
      // Skip header row
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        final row = rowsAsListOfValues[i];
        if (row.length < 19) continue; // Skip invalid rows
        
        final String teamAbbreviation = row[4].toString();
        final String playerId = row[1].toString();
        final String playerName = row[2].toString();
        final String teamId = row[3].toString();
        final String minutes = row[5].toString();
        final double points = double.tryParse(row[18].toString()) ?? 0.0;
        final double rebounds = double.tryParse(row[17].toString()) ?? 0.0;
        final double assists = double.tryParse(row[13].toString()) ?? 0.0;
        final double steals = double.tryParse(row[14].toString()) ?? 0.0;
        final double blocks = double.tryParse(row[15].toString()) ?? 0.0;
        final double fieldGoalPct = double.tryParse(row[8].toString()) ?? 0.0;
        final double threePointPct = double.tryParse(row[11].toString()) ?? 0.0;
        
        final player = PlayerData(
          playerId: playerId,
          playerName: playerName,
          teamId: teamId,
          teamAbbreviation: teamAbbreviation,
          minutes: minutes,
          points: points,
          rebounds: rebounds,
          assists: assists,
          steals: steals,
          blocks: blocks,
          fieldGoalPct: fieldGoalPct,
          threePointPct: threePointPct,
        );
        
        // Add player to their team's list
        if (!playersByTeam.containsKey(teamAbbreviation)) {
          playersByTeam[teamAbbreviation] = [];
        }
        
        // Check if player is already in the list (avoid duplicates)
        bool playerExists = playersByTeam[teamAbbreviation]!.any((p) => p.playerId == playerId);
        if (!playerExists) {
          playersByTeam[teamAbbreviation]!.add(player);
        }
      }
      
      print('Successfully loaded ${playersByTeam.length} teams from CSV');
      return playersByTeam;
    } catch (e) {
      print('Error processing CSV content: $e');
      return {};
    }
  }

  static Future<List<PlayerData>> getPlayersForTeam(String teamAbbreviation) async {
    if (_playersByTeam.isEmpty) {
      // Load the data asynchronously if it hasn't been loaded yet
      await loadPlayerData();
    }
    
    return _playersByTeam[teamAbbreviation] ?? [];
  }
  
  // Hardcoded player data for each team
  static Map<String, List<PlayerData>> _loadHardcodedPlayers() {
    print('Using hardcoded player data based on updated_player_data.csv');
    final Map<String, List<PlayerData>> playersByTeam = {};
    
    // Lakers players
    playersByTeam['LAL'] = [
      const PlayerData(
        playerId: '1627752',
        playerName: 'Taurean Prince',
        teamId: '1610612747',
        teamAbbreviation: 'LAL',
        minutes: '29:53',
        points: 18.0,
        rebounds: 3.0,
        assists: 1.0,
        steals: 0.0,
        blocks: 1.0,
        fieldGoalPct: 0.75,
        threePointPct: 0.667,
      ),
      const PlayerData(
        playerId: '2544',
        playerName: 'LeBron James',
        teamId: '1610612747',
        teamAbbreviation: 'LAL',
        minutes: '29:01',
        points: 21.0,
        rebounds: 8.0,
        assists: 5.0,
        steals: 1.0,
        blocks: 0.0,
        fieldGoalPct: 0.625,
        threePointPct: 0.25,
      ),
      const PlayerData(
        playerId: '203076',
        playerName: 'Anthony Davis',
        teamId: '1610612747',
        teamAbbreviation: 'LAL',
        minutes: '34:09',
        points: 17.0,
        rebounds: 8.0,
        assists: 4.0,
        steals: 0.0,
        blocks: 2.0,
        fieldGoalPct: 0.353,
        threePointPct: 0.5,
      ),
      const PlayerData(
        playerId: '1630559',
        playerName: 'Austin Reaves',
        teamId: '1610612747',
        teamAbbreviation: 'LAL',
        minutes: '31:20',
        points: 14.0,
        rebounds: 8.0,
        assists: 4.0,
        steals: 2.0,
        blocks: 0.0,
        fieldGoalPct: 0.364,
        threePointPct: 0.5,
      ),
      const PlayerData(
        playerId: '1626156',
        playerName: 'D\'Angelo Russell',
        teamId: '1610612747',
        teamAbbreviation: 'LAL',
        minutes: '36:11',
        points: 11.0,
        rebounds: 4.0,
        assists: 7.0,
        steals: 1.0,
        blocks: 0.0,
        fieldGoalPct: 0.333,
        threePointPct: 0.4,
      ),
      const PlayerData(
        playerId: '1629060',
        playerName: 'Rui Hachimura',
        teamId: '1610612747',
        teamAbbreviation: 'LAL',
        minutes: '14:38',
        points: 6.0,
        rebounds: 3.0,
        assists: 0.0,
        steals: 0.0,
        blocks: 0.0,
        fieldGoalPct: 0.3,
        threePointPct: 0.0,
      ),
      const PlayerData(
        playerId: '1629216',
        playerName: 'Gabe Vincent',
        teamId: '1610612747',
        teamAbbreviation: 'LAL',
        minutes: '22:18',
        points: 6.0,
        rebounds: 1.0,
        assists: 2.0,
        steals: 1.0,
        blocks: 0.0,
        fieldGoalPct: 0.375,
        threePointPct: 0.0,
      ),
    ];
    
    // Nuggets players
    playersByTeam['DEN'] = [
      const PlayerData(
        playerId: '203999',
        playerName: 'Nikola Jokić',
        teamId: '1610612743',
        teamAbbreviation: 'DEN',
        minutes: '36:15',
        points: 29.0,
        rebounds: 13.0,
        assists: 11.0,
        steals: 1.0,
        blocks: 1.0,
        fieldGoalPct: 0.545,
        threePointPct: 0.6,
      ),
      const PlayerData(
        playerId: '1627750',
        playerName: 'Jamal Murray',
        teamId: '1610612743',
        teamAbbreviation: 'DEN',
        minutes: '34:14',
        points: 21.0,
        rebounds: 2.0,
        assists: 6.0,
        steals: 0.0,
        blocks: 1.0,
        fieldGoalPct: 0.615,
        threePointPct: 0.6,
      ),
      const PlayerData(
        playerId: '203484',
        playerName: 'Kentavious Caldwell-Pope',
        teamId: '1610612743',
        teamAbbreviation: 'DEN',
        minutes: '36:14',
        points: 20.0,
        rebounds: 2.0,
        assists: 1.0,
        steals: 3.0,
        blocks: 1.0,
        fieldGoalPct: 0.667,
        threePointPct: 0.667,
      ),
      const PlayerData(
        playerId: '203932',
        playerName: 'Aaron Gordon',
        teamId: '1610612743',
        teamAbbreviation: 'DEN',
        minutes: '34:58',
        points: 15.0,
        rebounds: 7.0,
        assists: 5.0,
        steals: 2.0,
        blocks: 1.0,
        fieldGoalPct: 0.636,
        threePointPct: 0.5,
      ),
      const PlayerData(
        playerId: '1629008',
        playerName: 'Michael Porter Jr.',
        teamId: '1610612743',
        teamAbbreviation: 'DEN',
        minutes: '30:07',
        points: 12.0,
        rebounds: 12.0,
        assists: 2.0,
        steals: 2.0,
        blocks: 0.0,
        fieldGoalPct: 0.385,
        threePointPct: 0.222,
      ),
      const PlayerData(
        playerId: '202704',
        playerName: 'Reggie Jackson',
        teamId: '1610612743',
        teamAbbreviation: 'DEN',
        minutes: '24:04',
        points: 8.0,
        rebounds: 3.0,
        assists: 1.0,
        steals: 1.0,
        blocks: 0.0,
        fieldGoalPct: 0.375,
        threePointPct: 0.4,
      ),
      const PlayerData(
        playerId: '1631212',
        playerName: 'Peyton Watson',
        teamId: '1610612743',
        teamAbbreviation: 'DEN',
        minutes: '10:51',
        points: 3.0,
        rebounds: 0.0,
        assists: 0.0,
        steals: 0.0,
        blocks: 1.0,
        fieldGoalPct: 0.333,
        threePointPct: 0.333,
      ),
    ];
    
    // Celtics players
    playersByTeam['BOS'] = [
      const PlayerData(
        playerId: '1628369',
        playerName: 'Jayson Tatum',
        teamId: '1610612738',
        teamAbbreviation: 'BOS',
        minutes: '36:24',
        points: 26.9,
        rebounds: 8.1,
        assists: 4.9,
        steals: 1.0,
        blocks: 0.7,
        fieldGoalPct: 0.471,
        threePointPct: 0.371,
      ),
      const PlayerData(
        playerId: '1627759',
        playerName: 'Jaylen Brown',
        teamId: '1610612738',
        teamAbbreviation: 'BOS',
        minutes: '33:57',
        points: 23.0,
        rebounds: 5.5,
        assists: 3.5,
        steals: 1.2,
        blocks: 0.5,
        fieldGoalPct: 0.499,
        threePointPct: 0.354,
      ),
      const PlayerData(
        playerId: '202689',
        playerName: 'Kristaps Porzingis',
        teamId: '1610612738',
        teamAbbreviation: 'BOS',
        minutes: '29:42',
        points: 20.1,
        rebounds: 7.2,
        assists: 2.0,
        steals: 0.7,
        blocks: 1.9,
        fieldGoalPct: 0.518,
        threePointPct: 0.374,
      ),
      const PlayerData(
        playerId: '1629684',
        playerName: 'Derrick White',
        teamId: '1610612738',
        teamAbbreviation: 'BOS',
        minutes: '32:18',
        points: 15.2,
        rebounds: 4.0,
        assists: 5.2,
        steals: 0.8,
        blocks: 1.2,
        fieldGoalPct: 0.461,
        threePointPct: 0.396,
      ),
      const PlayerData(
        playerId: '1628464',
        playerName: 'Jrue Holiday',
        teamId: '1610612738',
        teamAbbreviation: 'BOS',
        minutes: '31:46',
        points: 12.5,
        rebounds: 5.4,
        assists: 4.8,
        steals: 0.9,
        blocks: 0.7,
        fieldGoalPct: 0.481,
        threePointPct: 0.424,
      ),
    ];
    
    // Warriors players
    playersByTeam['GSW'] = [
      const PlayerData(
        playerId: '201939',
        playerName: 'Stephen Curry',
        teamId: '1610612744',
        teamAbbreviation: 'GSW',
        minutes: '33:42',
        points: 26.8,
        rebounds: 4.2,
        assists: 5.1,
        steals: 0.9,
        blocks: 0.4,
        fieldGoalPct: 0.455,
        threePointPct: 0.409,
      ),
      const PlayerData(
        playerId: '203110',
        playerName: 'Draymond Green',
        teamId: '1610612744',
        teamAbbreviation: 'GSW',
        minutes: '28:36',
        points: 8.6,
        rebounds: 7.2,
        assists: 6.0,
        steals: 1.0,
        blocks: 0.8,
        fieldGoalPct: 0.527,
        threePointPct: 0.389,
      ),
      const PlayerData(
        playerId: '1627780',
        playerName: 'Andrew Wiggins',
        teamId: '1610612744',
        teamAbbreviation: 'GSW',
        minutes: '29:18',
        points: 13.2,
        rebounds: 4.5,
        assists: 1.7,
        steals: 0.6,
        blocks: 0.5,
        fieldGoalPct: 0.452,
        threePointPct: 0.356,
      ),
      const PlayerData(
        playerId: '1630228',
        playerName: 'Jonathan Kuminga',
        teamId: '1610612744',
        teamAbbreviation: 'GSW',
        minutes: '26:32',
        points: 16.1,
        rebounds: 4.8,
        assists: 2.2,
        steals: 0.6,
        blocks: 0.5,
        fieldGoalPct: 0.529,
        threePointPct: 0.321,
      ),
      const PlayerData(
        playerId: '1627814',
        playerName: 'Buddy Hield',
        teamId: '1610612744',
        teamAbbreviation: 'GSW',
        minutes: '25:14',
        points: 12.1,
        rebounds: 3.2,
        assists: 2.8,
        steals: 0.8,
        blocks: 0.2,
        fieldGoalPct: 0.436,
        threePointPct: 0.385,
      ),
    ];
    
    // Bucks players
    playersByTeam['MIL'] = [
      const PlayerData(
        playerId: '203507',
        playerName: 'Giannis Antetokounmpo',
        teamId: '1610612749',
        teamAbbreviation: 'MIL',
        minutes: '35:28',
        points: 30.4,
        rebounds: 11.5,
        assists: 6.5,
        steals: 1.2,
        blocks: 1.1,
        fieldGoalPct: 0.612,
        threePointPct: 0.274,
      ),
      const PlayerData(
        playerId: '203114',
        playerName: 'Damian Lillard',
        teamId: '1610612749',
        teamAbbreviation: 'MIL',
        minutes: '34:46',
        points: 24.3,
        rebounds: 4.4,
        assists: 7.0,
        steals: 1.0,
        blocks: 0.3,
        fieldGoalPct: 0.424,
        threePointPct: 0.351,
      ),
      const PlayerData(
        playerId: '1626192',
        playerName: 'Bobby Portis',
        teamId: '1610612749',
        teamAbbreviation: 'MIL',
        minutes: '26:18',
        points: 13.8,
        rebounds: 7.4,
        assists: 1.2,
        steals: 0.5,
        blocks: 0.2,
        fieldGoalPct: 0.513,
        threePointPct: 0.385,
      ),
      const PlayerData(
        playerId: '1628978',
        playerName: 'Khris Middleton',
        teamId: '1610612749',
        teamAbbreviation: 'MIL',
        minutes: '31:12',
        points: 15.1,
        rebounds: 4.7,
        assists: 5.3,
        steals: 0.8,
        blocks: 0.3,
        fieldGoalPct: 0.492,
        threePointPct: 0.381,
      ),
      const PlayerData(
        playerId: '1629652',
        playerName: 'Taurean Prince',
        teamId: '1610612749',
        teamAbbreviation: 'MIL',
        minutes: '24:36',
        points: 8.9,
        rebounds: 3.1,
        assists: 1.5,
        steals: 0.6,
        blocks: 0.2,
        fieldGoalPct: 0.442,
        threePointPct: 0.394,
      ),
    ];
    
    // 76ers players
    playersByTeam['PHI'] = [
      const PlayerData(
        playerId: '203954',
        playerName: 'Joel Embiid',
        teamId: '1610612755',
        teamAbbreviation: 'PHI',
        minutes: '33:58',
        points: 34.7,
        rebounds: 11.0,
        assists: 5.6,
        steals: 1.2,
        blocks: 1.7,
        fieldGoalPct: 0.529,
        threePointPct: 0.377,
      ),
      const PlayerData(
        playerId: '1627732',
        playerName: 'Tyrese Maxey',
        teamId: '1610612755',
        teamAbbreviation: 'PHI',
        minutes: '37:24',
        points: 25.9,
        rebounds: 3.7,
        assists: 6.2,
        steals: 1.0,
        blocks: 0.5,
        fieldGoalPct: 0.450,
        threePointPct: 0.373,
      ),
      const PlayerData(
        playerId: '1629684',
        playerName: 'Tobias Harris',
        teamId: '1610612755',
        teamAbbreviation: 'PHI',
        minutes: '32:42',
        points: 17.2,
        rebounds: 6.5,
        assists: 3.1,
        steals: 0.7,
        blocks: 0.6,
        fieldGoalPct: 0.493,
        threePointPct: 0.359,
      ),
      const PlayerData(
        playerId: '1629013',
        playerName: 'Kelly Oubre Jr.',
        teamId: '1610612755',
        teamAbbreviation: 'PHI',
        minutes: '29:18',
        points: 15.4,
        rebounds: 5.0,
        assists: 1.5,
        steals: 1.1,
        blocks: 0.5,
        fieldGoalPct: 0.441,
        threePointPct: 0.336,
      ),
      const PlayerData(
        playerId: '1630178',
        playerName: 'Paul Reed',
        teamId: '1610612755',
        teamAbbreviation: 'PHI',
        minutes: '18:24',
        points: 6.0,
        rebounds: 5.2,
        assists: 1.1,
        steals: 0.8,
        blocks: 0.6,
        fieldGoalPct: 0.585,
        threePointPct: 0.250,
      ),
    ];
    
    // Knicks players
    playersByTeam['NYK'] = [
      const PlayerData(
        playerId: '1628373',
        playerName: 'OG Anunoby',
        teamId: '1610612752',
        teamAbbreviation: 'NYK',
        minutes: '35:12',
        points: 14.1,
        rebounds: 4.3,
        assists: 1.7,
        steals: 1.3,
        blocks: 0.7,
        fieldGoalPct: 0.487,
        threePointPct: 0.381,
      ),
      const PlayerData(
        playerId: '1629628',
        playerName: 'Jalen Brunson',
        teamId: '1610612752',
        teamAbbreviation: 'NYK',
        minutes: '35:48',
        points: 28.7,
        rebounds: 3.6,
        assists: 6.7,
        steals: 0.9,
        blocks: 0.2,
        fieldGoalPct: 0.480,
        threePointPct: 0.401,
      ),
      const PlayerData(
        playerId: '1628995',
        playerName: 'Josh Hart',
        teamId: '1610612752',
        teamAbbreviation: 'NYK',
        minutes: '33:18',
        points: 9.4,
        rebounds: 8.3,
        assists: 4.1,
        steals: 0.9,
        blocks: 0.3,
        fieldGoalPct: 0.438,
        threePointPct: 0.309,
      ),
      const PlayerData(
        playerId: '1629634',
        playerName: 'Donte DiVincenzo',
        teamId: '1610612752',
        teamAbbreviation: 'NYK',
        minutes: '29:24',
        points: 15.5,
        rebounds: 3.7,
        assists: 2.7,
        steals: 1.2,
        blocks: 0.2,
        fieldGoalPct: 0.445,
        threePointPct: 0.403,
      ),
      const PlayerData(
        playerId: '1626169',
        playerName: 'Isaiah Hartenstein',
        teamId: '1610612752',
        teamAbbreviation: 'NYK',
        minutes: '26:42',
        points: 7.8,
        rebounds: 8.3,
        assists: 2.5,
        steals: 1.2,
        blocks: 1.1,
        fieldGoalPct: 0.645,
        threePointPct: 0.000,
      ),
    ];
    
    // Heat players
    playersByTeam['MIA'] = [
      const PlayerData(
        playerId: '1628389',
        playerName: 'Bam Adebayo',
        teamId: '1610612748',
        teamAbbreviation: 'MIA',
        minutes: '34:36',
        points: 19.3,
        rebounds: 10.4,
        assists: 3.9,
        steals: 1.1,
        blocks: 0.9,
        fieldGoalPct: 0.524,
        threePointPct: 0.400,
      ),
      const PlayerData(
        playerId: '202710',
        playerName: 'Jimmy Butler',
        teamId: '1610612748',
        teamAbbreviation: 'MIA',
        minutes: '33:48',
        points: 20.8,
        rebounds: 5.3,
        assists: 5.0,
        steals: 1.3,
        blocks: 0.3,
        fieldGoalPct: 0.501,
        threePointPct: 0.414,
      ),
      const PlayerData(
        playerId: '1629216',
        playerName: 'Tyler Herro',
        teamId: '1610612748',
        teamAbbreviation: 'MIA',
        minutes: '32:54',
        points: 20.8,
        rebounds: 5.3,
        assists: 4.5,
        steals: 0.8,
        blocks: 0.2,
        fieldGoalPct: 0.440,
        threePointPct: 0.390,
      ),
      const PlayerData(
        playerId: '1629639',
        playerName: 'Terry Rozier',
        teamId: '1610612748',
        teamAbbreviation: 'MIA',
        minutes: '31:12',
        points: 16.4,
        rebounds: 4.5,
        assists: 4.6,
        steals: 0.9,
        blocks: 0.3,
        fieldGoalPct: 0.441,
        threePointPct: 0.361,
      ),
      const PlayerData(
        playerId: '1629130',
        playerName: 'Duncan Robinson',
        teamId: '1610612748',
        teamAbbreviation: 'MIA',
        minutes: '25:18',
        points: 10.5,
        rebounds: 2.5,
        assists: 2.8,
        steals: 0.5,
        blocks: 0.2,
        fieldGoalPct: 0.439,
        threePointPct: 0.388,
      ),
    ];
    
    // Portland Trail Blazers players (from game 0022300074)
    playersByTeam['POR'] = [
      const PlayerData(
        playerId: '1629680',
        playerName: 'Matisse Thybulle',
        teamId: '1610612757',
        teamAbbreviation: 'POR',
        minutes: '20:05',
        points: 8.0,
        rebounds: 1.0,
        assists: 1.0,
        steals: 1.0,
        blocks: 0.0,
        fieldGoalPct: 0.429,
        threePointPct: 0.333,
      ),
      const PlayerData(
        playerId: '203924',
        playerName: 'Jerami Grant',
        teamId: '1610612757',
        teamAbbreviation: 'POR',
        minutes: '29:57',
        points: 13.0,
        rebounds: 3.0,
        assists: 1.0,
        steals: 0.0,
        blocks: 1.0,
        fieldGoalPct: 0.417,
        threePointPct: 0.0,
      ),
      const PlayerData(
        playerId: '1629028',
        playerName: 'Deandre Ayton',
        teamId: '1610612757',
        teamAbbreviation: 'POR',
        minutes: '23:05',
        points: 4.0,
        rebounds: 12.0,
        assists: 1.0,
        steals: 3.0,
        blocks: 1.0,
        fieldGoalPct: 0.5,
        threePointPct: 0.0,
      ),
      const PlayerData(
        playerId: '1629014',
        playerName: 'Anfernee Simons',
        teamId: '1610612757',
        teamAbbreviation: 'POR',
        minutes: '27:22',
        points: 18.0,
        rebounds: 2.0,
        assists: 4.0,
        steals: 2.0,
        blocks: 0.0,
        fieldGoalPct: 0.429,
        threePointPct: 0.333,
      ),
      const PlayerData(
        playerId: '1630703',
        playerName: 'Scoot Henderson',
        teamId: '1610612757',
        teamAbbreviation: 'POR',
        minutes: '35:50',
        points: 11.0,
        rebounds: 3.0,
        assists: 4.0,
        steals: 0.0,
        blocks: 0.0,
        fieldGoalPct: 0.455,
        threePointPct: 0.0,
      ),
      const PlayerData(
        playerId: '1629057',
        playerName: 'Robert Williams III',
        teamId: '1610612757',
        teamAbbreviation: 'POR',
        minutes: '23:13',
        points: 10.0,
        rebounds: 7.0,
        assists: 0.0,
        steals: 3.0,
        blocks: 1.0,
        fieldGoalPct: 0.714,
        threePointPct: 0.0,
      ),
      const PlayerData(
        playerId: '1631101',
        playerName: 'Shaedon Sharpe',
        teamId: '1610612757',
        teamAbbreviation: 'POR',
        minutes: '28:29',
        points: 14.0,
        rebounds: 6.0,
        assists: 3.0,
        steals: 1.0,
        blocks: 0.0,
        fieldGoalPct: 0.429,
        threePointPct: 0.167,
      ),
      const PlayerData(
        playerId: '1641739',
        playerName: 'Toumani Camara',
        teamId: '1610612757',
        teamAbbreviation: 'POR',
        minutes: '15:51',
        points: 7.0,
        rebounds: 2.0,
        assists: 1.0,
        steals: 0.0,
        blocks: 1.0,
        fieldGoalPct: 0.4,
        threePointPct: 1.0,
      ),
      const PlayerData(
        playerId: '1627763',
        playerName: 'Malcolm Brogdon',
        teamId: '1610612757',
        teamAbbreviation: 'POR',
        minutes: '22:39',
        points: 20.0,
        rebounds: 2.0,
        assists: 5.0,
        steals: 0.0,
        blocks: 0.0,
        fieldGoalPct: 0.5,
        threePointPct: 0.6,
      ),
    ];
    
    // LA Clippers players (from game 0022300074)
    playersByTeam['LAC'] = [
      const PlayerData(
        playerId: '203496',
        playerName: 'Robert Covington',
        teamId: '1610612746',
        teamAbbreviation: 'LAC',
        minutes: '23:10',
        points: 5.0,
        rebounds: 4.0,
        assists: 2.0,
        steals: 3.0,
        blocks: 1.0,
        fieldGoalPct: 0.4,
        threePointPct: 0.25,
      ),
      const PlayerData(
        playerId: '202695',
        playerName: 'Kawhi Leonard',
        teamId: '1610612746',
        teamAbbreviation: 'LAC',
        minutes: '28:43',
        points: 23.0,
        rebounds: 5.0,
        assists: 6.0,
        steals: 1.0,
        blocks: 1.0,
        fieldGoalPct: 0.529,
        threePointPct: 1.0,
      ),
      const PlayerData(
        playerId: '1627826',
        playerName: 'Ivica Zubac',
        teamId: '1610612746',
        teamAbbreviation: 'LAC',
        minutes: '25:36',
        points: 20.0,
        rebounds: 12.0,
        assists: 0.0,
        steals: 0.0,
        blocks: 4.0,
        fieldGoalPct: 0.8,
        threePointPct: 0.0,
      ),
      const PlayerData(
        playerId: '202331',
        playerName: 'Paul George',
        teamId: '1610612746',
        teamAbbreviation: 'LAC',
        minutes: '31:38',
        points: 27.0,
        rebounds: 3.0,
        assists: 6.0,
        steals: 3.0,
        blocks: 0.0,
        fieldGoalPct: 0.647,
        threePointPct: 0.571,
      ),
      const PlayerData(
        playerId: '201566',
        playerName: 'Russell Westbrook',
        teamId: '1610612746',
        teamAbbreviation: 'LAC',
        minutes: '28:48',
        points: 11.0,
        rebounds: 5.0,
        assists: 13.0,
        steals: 0.0,
        blocks: 0.0,
        fieldGoalPct: 0.625,
        threePointPct: 0.5,
      ),
      const PlayerData(
        playerId: '1626181',
        playerName: 'Norman Powell',
        teamId: '1610612746',
        teamAbbreviation: 'LAC',
        minutes: '22:54',
        points: 8.0,
        rebounds: 3.0,
        assists: 1.0,
        steals: 0.0,
        blocks: 0.0,
        fieldGoalPct: 0.333,
        threePointPct: 0.4,
      ),
    ];
    
    return playersByTeam;
  }
}
