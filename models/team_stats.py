import numpy as np
import pandas as pd
from nba_api.stats.endpoints import leaguestandings, teamestimatedmetrics

class TeamStats:
    """
    Class for retrieving and processing team statistics
    """
    def __init__(self):
        pass
    
    def get_team_standings(self, conference=None):
        """
        Get current NBA team standings with option to filter by conference
        
        Args:
            conference: Optional filter for conference ('East', 'West', or None for all)
            
        Returns:
            Dictionary with team standings data
        """
        try:
            # In a real implementation, we would fetch from NBA API
            # For now, return mock data that matches the Statistics page UI
            
            # Eastern Conference teams
            eastern_teams = [
                {
                    'rank': 1,
                    'team_id': '1610612738',
                    'team_name': 'Celtics',
                    'team_abbreviation': 'BOS',
                    'conference': 'East',
                    'division': 'Atlantic',
                    'wins': 58,
                    'losses': 24,
                    'win_pct': 0.707,
                    'streak': 3,
                    'streak_type': 'W',
                    'home_record': '32-9',
                    'road_record': '26-15',
                    'last_ten': '8-2',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612738/global/L/logo.svg'
                },
                {
                    'rank': 2,
                    'team_id': '1610612749',
                    'team_name': 'Bucks',
                    'team_abbreviation': 'MIL',
                    'conference': 'East',
                    'division': 'Central',
                    'wins': 56,
                    'losses': 26,
                    'win_pct': 0.683,
                    'streak': 5,
                    'streak_type': 'W',
                    'home_record': '31-10',
                    'road_record': '25-16',
                    'last_ten': '9-1',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612749/global/L/logo.svg'
                },
                {
                    'rank': 3,
                    'team_id': '1610612755',
                    'team_name': '76ers',
                    'team_abbreviation': 'PHI',
                    'conference': 'East',
                    'division': 'Atlantic',
                    'wins': 54,
                    'losses': 28,
                    'win_pct': 0.659,
                    'streak': -2,
                    'streak_type': 'L',
                    'home_record': '30-11',
                    'road_record': '24-17',
                    'last_ten': '5-5',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612755/global/L/logo.svg'
                },
                {
                    'rank': 4,
                    'team_id': '1610612752',
                    'team_name': 'Knicks',
                    'team_abbreviation': 'NYK',
                    'conference': 'East',
                    'division': 'Atlantic',
                    'wins': 50,
                    'losses': 32,
                    'win_pct': 0.610,
                    'streak': 4,
                    'streak_type': 'W',
                    'home_record': '28-13',
                    'road_record': '22-19',
                    'last_ten': '7-3',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612752/global/L/logo.svg'
                },
                {
                    'rank': 5,
                    'team_id': '1610612739',
                    'team_name': 'Cavaliers',
                    'team_abbreviation': 'CLE',
                    'conference': 'East',
                    'division': 'Central',
                    'wins': 48,
                    'losses': 34,
                    'win_pct': 0.585,
                    'streak': 1,
                    'streak_type': 'W',
                    'home_record': '29-12',
                    'road_record': '19-22',
                    'last_ten': '6-4',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612739/global/L/logo.svg'
                }
            ]
            
            # Western Conference teams
            western_teams = [
                {
                    'rank': 1,
                    'team_id': '1610612743',
                    'team_name': 'Nuggets',
                    'team_abbreviation': 'DEN',
                    'conference': 'West',
                    'division': 'Northwest',
                    'wins': 57,
                    'losses': 25,
                    'win_pct': 0.695,
                    'streak': 2,
                    'streak_type': 'W',
                    'home_record': '33-8',
                    'road_record': '24-17',
                    'last_ten': '7-3',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612743/global/L/logo.svg'
                },
                {
                    'rank': 2,
                    'team_id': '1610612744',
                    'team_name': 'Warriors',
                    'team_abbreviation': 'GSW',
                    'conference': 'West',
                    'division': 'Pacific',
                    'wins': 54,
                    'losses': 28,
                    'win_pct': 0.659,
                    'streak': 6,
                    'streak_type': 'W',
                    'home_record': '33-8',
                    'road_record': '21-20',
                    'last_ten': '8-2',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612744/global/L/logo.svg'
                },
                {
                    'rank': 3,
                    'team_id': '1610612756',
                    'team_name': 'Suns',
                    'team_abbreviation': 'PHX',
                    'conference': 'West',
                    'division': 'Pacific',
                    'wins': 52,
                    'losses': 30,
                    'win_pct': 0.634,
                    'streak': 3,
                    'streak_type': 'W',
                    'home_record': '31-10',
                    'road_record': '21-20',
                    'last_ten': '7-3',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612756/global/L/logo.svg'
                },
                {
                    'rank': 4,
                    'team_id': '1610612747',
                    'team_name': 'Lakers',
                    'team_abbreviation': 'LAL',
                    'conference': 'West',
                    'division': 'Pacific',
                    'wins': 48,
                    'losses': 34,
                    'win_pct': 0.585,
                    'streak': 2,
                    'streak_type': 'W',
                    'home_record': '28-13',
                    'road_record': '20-21',
                    'last_ten': '6-4',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612747/global/L/logo.svg'
                },
                {
                    'rank': 5,
                    'team_id': '1610612759',
                    'team_name': 'Spurs',
                    'team_abbreviation': 'SAS',
                    'conference': 'West',
                    'division': 'Southwest',
                    'wins': 45,
                    'losses': 37,
                    'win_pct': 0.549,
                    'streak': -1,
                    'streak_type': 'L',
                    'home_record': '27-14',
                    'road_record': '18-23',
                    'last_ten': '5-5',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612759/global/L/logo.svg'
                }
            ]
            
            # Filter by conference if specified
            if conference == 'East':
                teams = eastern_teams
            elif conference == 'West':
                teams = western_teams
            else:
                # Combine and sort by overall rank
                teams = eastern_teams + western_teams
                teams.sort(key=lambda x: (x['win_pct']), reverse=True)
                
                # Reassign ranks based on overall standing
                for i, team in enumerate(teams):
                    team['rank'] = i + 1
            
            return {
                'standings': teams,
                'season': '2024-25',
                'standings_date': '2025-05-03'
            }
        except Exception as e:
            print(f"Error getting team standings: {e}")
            return None
    
    def get_team_offensive_stats(self, conference=None):
        """
        Get offensive statistics for NBA teams
        
        Args:
            conference: Optional filter for conference ('East', 'West', or None for all)
            
        Returns:
            Dictionary with team offensive stats
        """
        try:
            # In a real implementation, we would fetch from NBA API
            # For now, return mock data
            
            # Get team standings first to have the base team data
            standings_data = self.get_team_standings(conference)
            teams = standings_data['standings']
            
            # Add offensive stats to each team
            for team in teams:
                team['offensive_stats'] = {
                    'points_per_game': round(np.random.normal(110, 5), 1),
                    'field_goal_pct': round(np.random.normal(0.46, 0.02), 3),
                    'three_point_pct': round(np.random.normal(0.36, 0.02), 3),
                    'free_throw_pct': round(np.random.normal(0.77, 0.03), 3),
                    'assists_per_game': round(np.random.normal(24, 2), 1),
                    'offensive_rebounds': round(np.random.normal(10, 1.5), 1),
                    'offensive_rating': round(np.random.normal(110, 5), 1),
                    'pace': round(np.random.normal(98, 3), 1)
                }
            
            # Sort by points per game
            teams.sort(key=lambda x: x['offensive_stats']['points_per_game'], reverse=True)
            
            # Reassign ranks based on offensive stats
            for i, team in enumerate(teams):
                team['offensive_rank'] = i + 1
            
            return {
                'offensive_stats': teams,
                'season': '2024-25',
                'stats_date': '2025-05-03'
            }
        except Exception as e:
            print(f"Error getting offensive stats: {e}")
            return None
    
    def get_team_defensive_stats(self, conference=None):
        """
        Get defensive statistics for NBA teams
        
        Args:
            conference: Optional filter for conference ('East', 'West', or None for all)
            
        Returns:
            Dictionary with team defensive stats
        """
        try:
            # In a real implementation, we would fetch from NBA API
            # For now, return mock data
            
            # Get team standings first to have the base team data
            standings_data = self.get_team_standings(conference)
            teams = standings_data['standings']
            
            # Add defensive stats to each team
            for team in teams:
                team['defensive_stats'] = {
                    'opponent_points_per_game': round(np.random.normal(108, 5), 1),
                    'blocks_per_game': round(np.random.normal(5, 1), 1),
                    'steals_per_game': round(np.random.normal(8, 1), 1),
                    'opponent_field_goal_pct': round(np.random.normal(0.45, 0.02), 3),
                    'opponent_three_point_pct': round(np.random.normal(0.35, 0.02), 3),
                    'defensive_rebounds': round(np.random.normal(33, 2), 1),
                    'defensive_rating': round(np.random.normal(110, 5), 1)
                }
            
            # Sort by opponent points per game (lower is better)
            teams.sort(key=lambda x: x['defensive_stats']['opponent_points_per_game'])
            
            # Reassign ranks based on defensive stats
            for i, team in enumerate(teams):
                team['defensive_rank'] = i + 1
            
            return {
                'defensive_stats': teams,
                'season': '2024-25',
                'stats_date': '2025-05-03'
            }
        except Exception as e:
            print(f"Error getting defensive stats: {e}")
            return None
