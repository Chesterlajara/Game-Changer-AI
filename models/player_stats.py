import numpy as np
import pandas as pd
from nba_api.stats.endpoints import leagueleaders, commonteamroster, leaguestandings
from datetime import datetime

class PlayerStats:
    """
    Class for retrieving and processing player statistics
    """
    def __init__(self):
        self.team_stats = None
        
    def get_player_standings(self, conference=None, stat_category="PTS"):
        """
        Get current NBA player standings with option to filter by conference
        
        Args:
            conference: Optional filter for conference ('East', 'West', or None for all)
            stat_category: Statistic to sort by (PTS, AST, REB, etc.)
            
        Returns:
            Dictionary with player standings data
        """
        try:
            print(f"Fetching player standings with conference filter: {conference}, stat category: {stat_category}")
            
            # Get team data to map players to conferences
            print("Fetching team data for conference mapping...")
            standings = leaguestandings.LeagueStandings()
            teams_data = standings.get_data_frames()[0]
            
            # Create a mapping of team ID to conference
            team_to_conference = {}
            for _, row in teams_data.iterrows():
                team_to_conference[row['TeamID']] = row['Conference']
            
            print(f"Created mapping of {len(team_to_conference)} teams to conferences")
            
            # Get player stats from NBA API
            print("Fetching player data from NBA API...")
            leaders = leagueleaders.LeagueLeaders(
                season="2023-24",  # Use current season
                stat_category_abbreviation=stat_category,
                per_mode48="PerGame"
            )
            players_data = leaders.get_data_frames()[0]
            print(f"Successfully retrieved {len(players_data)} players from NBA API")
            
            # Process each player in the standings
            players = []
            for _, row in players_data.iterrows():
                # Get player's team conference
                team_id = row['TEAM_ID'] if 'TEAM_ID' in row else None
                player_conference = team_to_conference.get(team_id, "Unknown")
                
                # Create player dictionary with all required fields
                player = {
                    'rank': int(row['RANK']) if 'RANK' in row else 0,
                    'player_id': str(row['PLAYER_ID']) if 'PLAYER_ID' in row else '0',
                    'player_name': row['PLAYER'] if 'PLAYER' in row else 'Unknown Player',
                    'team_id': str(team_id) if team_id else '0',
                    'team_abbreviation': row['TEAM'] if 'TEAM' in row else 'UNK',
                    'conference': player_conference,
                    'games_played': int(row['GP']) if 'GP' in row else 0,
                    'minutes_per_game': float(row['MIN']) if 'MIN' in row else 0.0,
                    'points_per_game': float(row['PTS']) if 'PTS' in row else 0.0,
                    'rebounds_per_game': float(row['REB']) if 'REB' in row else 0.0,
                    'assists_per_game': float(row['AST']) if 'AST' in row else 0.0,
                    'steals_per_game': float(row['STL']) if 'STL' in row else 0.0,
                    'blocks_per_game': float(row['BLK']) if 'BLK' in row else 0.0,
                    'field_goal_pct': float(row['FG_PCT']) if 'FG_PCT' in row else 0.0,
                    'three_point_pct': float(row['FG3_PCT']) if 'FG3_PCT' in row else 0.0,
                    'free_throw_pct': float(row['FT_PCT']) if 'FT_PCT' in row else 0.0,
                    'efficiency': float(row['EFF']) if 'EFF' in row else 0.0,
                    'player_image_url': f"https://cdn.nba.com/headshots/nba/latest/1040x760/{row['PLAYER_ID']}.png" if 'PLAYER_ID' in row else ''
                }
                players.append(player)
            
            # Filter by conference if specified
            if conference == 'East':
                print(f"Filtering for Eastern Conference players...")
                players = [player for player in players if player['conference'] == 'East']
                print(f"After filtering, found {len(players)} Eastern Conference players")
            elif conference == 'West':
                print(f"Filtering for Western Conference players...")
                players = [player for player in players if player['conference'] == 'West']
                print(f"After filtering, found {len(players)} Western Conference players")
            
            # Get current date for standings
            standings_date = datetime.now().strftime('%Y-%m-%d')
            
            print(f"Returning {len(players)} players for {conference if conference else 'All'} conference")
            
            return {
                'standings': players,
                'season': '2023-24',
                'standings_date': standings_date,
                'stat_category': stat_category
            }
        except Exception as e:
            print(f"Error getting player standings: {e}")
            # Return empty data structure with error message
            return {
                'standings': [],
                'season': '2023-24',
                'standings_date': datetime.now().strftime('%Y-%m-%d'),
                'error': f"Failed to retrieve NBA player data: {str(e)}"
            }
