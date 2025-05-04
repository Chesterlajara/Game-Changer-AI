import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from nba_api.stats.endpoints import scoreboardv2
from nba_api.live.nba.endpoints import scoreboard as live_scoreboard

class GameModel:
    """
    Class for retrieving and processing game data
    """
    def __init__(self):
        self.games_cache = {}
        self.cache_expiry = {}
        self.cache_duration = 300  # Cache duration in seconds
    
    def get_games(self, category=None):
        """
        Get NBA games categorized as Today, Upcoming, and Live
        
        Args:
            category: Optional filter for game category ('today', 'upcoming', 'live', or None for all)
            
        Returns:
            Dictionary with game data categorized
        """
        try:
            # Check if we have cached data that's still valid
            cache_key = f"games_{category}"
            if cache_key in self.games_cache and cache_key in self.cache_expiry:
                if datetime.now() < self.cache_expiry[cache_key]:
                    print(f"Using cached game data for category: {category}")
                    return self.games_cache[cache_key]
            
            # Get today's date
            today = datetime.now()
            
            # Get live games
            live_games = self._get_live_games()
            
            # Get today's and upcoming games
            today_games = []
            upcoming_games = []
            
            # Get games for today and next 7 days
            for i in range(8):
                game_date = today + timedelta(days=i)
                date_str = game_date.strftime('%Y-%m-%d')
                
                # Get games for this date
                games = self._get_games_for_date(date_str)
                
                # Categorize games
                for game in games:
                    # Skip games that are already in live_games
                    if any(lg['game_id'] == game['game_id'] for lg in live_games):
                        continue
                        
                    # Add to appropriate category
                    if i == 0:  # Today
                        today_games.append(game)
                    else:  # Upcoming
                        upcoming_games.append(game)
            
            # Create result based on requested category
            result = {}
            if category == 'today' or category is None:
                result['today'] = today_games
            if category == 'upcoming' or category is None:
                result['upcoming'] = upcoming_games
            if category == 'live' or category is None:
                result['live'] = live_games
                
            # Cache the result
            self.games_cache[cache_key] = result
            self.cache_expiry[cache_key] = datetime.now() + timedelta(seconds=self.cache_duration)
            
            return result
            
        except Exception as e:
            print(f"Error getting games: {e}")
            # Return empty data structure with error message
            return {
                'today': [],
                'upcoming': [],
                'live': [],
                'error': f"Failed to retrieve NBA game data: {str(e)}"
            }
    
    def _get_live_games(self):
        """
        Get currently live NBA games
        
        Returns:
            List of live game dictionaries
        """
        try:
            # Get live games from NBA API
            scoreboard = live_scoreboard.ScoreBoard()
            games = scoreboard.games.get_dict()
            
            # Process each game
            live_games = []
            for game in games:
                # Extract basic game info
                game_id = game['gameId']
                home_team = game['homeTeam']
                away_team = game['awayTeam']
                
                # Create game dictionary
                game_dict = {
                    'game_id': game_id,
                    'home_team': {
                        'team_id': home_team['teamId'],
                        'team_name': home_team['teamName'],
                        'team_city': home_team['teamCity'],
                        'team_tricode': home_team['teamTricode'],
                        'wins': home_team['wins'],
                        'losses': home_team['losses'],
                        'score': home_team['score'],
                        'win_probability': 0.5  # Placeholder, would be calculated by prediction model
                    },
                    'away_team': {
                        'team_id': away_team['teamId'],
                        'team_name': away_team['teamName'],
                        'team_city': away_team['teamCity'],
                        'team_tricode': away_team['teamTricode'],
                        'wins': away_team['wins'],
                        'losses': away_team['losses'],
                        'score': away_team['score'],
                        'win_probability': 0.5  # Placeholder, would be calculated by prediction model
                    },
                    'game_status': 'LIVE',
                    'game_date': game['gameEt'].split('T')[0],
                    'game_time': game['gameEt'].split('T')[1],
                    'arena': game['arena']['arenaName'],
                    'city': game['arena']['arenaCity'],
                    'period': game['period'],
                    'game_clock': game['gameClock'],
                    'has_prediction': True
                }
                
                # Add win probabilities (simplified example)
                home_wins = int(home_team['wins'])
                home_losses = int(home_team['losses'])
                away_wins = int(away_team['wins'])
                away_losses = int(away_team['losses'])
                
                # Simple win probability based on win percentage
                if home_wins + home_losses > 0 and away_wins + away_losses > 0:
                    home_win_pct = home_wins / (home_wins + home_losses)
                    away_win_pct = away_wins / (away_wins + away_losses)
                    total = home_win_pct + away_win_pct
                    
                    if total > 0:
                        game_dict['home_team']['win_probability'] = round(home_win_pct / total, 2)
                        game_dict['away_team']['win_probability'] = round(away_win_pct / total, 2)
                
                live_games.append(game_dict)
            
            return live_games
            
        except Exception as e:
            print(f"Error getting live games: {e}")
            return []
    
    def _get_games_for_date(self, date_str):
        """
        Get NBA games for a specific date
        
        Args:
            date_str: Date string in format 'YYYY-MM-DD'
            
        Returns:
            List of game dictionaries
        """
        try:
            # Parse date string
            date_parts = date_str.split('-')
            year = int(date_parts[0])
            month = int(date_parts[1])
            day = int(date_parts[2])
            
            # Get games from NBA API
            scoreboard = scoreboardv2.ScoreboardV2(
                game_date=date_str,
                league_id='00',
                day_offset=0
            )
            games_df = scoreboard.game_header.get_data_frame()
            
            # Process each game
            games = []
            for _, row in games_df.iterrows():
                # Extract basic game info
                game_id = row['GAME_ID']
                home_team_id = row['HOME_TEAM_ID']
                away_team_id = row['VISITOR_TEAM_ID']
                
                # Get team info
                teams_df = scoreboard.teams.get_data_frame()
                home_team = teams_df[teams_df['TEAM_ID'] == home_team_id].iloc[0]
                away_team = teams_df[teams_df['TEAM_ID'] == away_team_id].iloc[0]
                
                # Create game dictionary
                game_dict = {
                    'game_id': game_id,
                    'home_team': {
                        'team_id': str(home_team_id),
                        'team_name': home_team['TEAM_NAME'],
                        'team_city': home_team['TEAM_CITY'],
                        'team_tricode': home_team['TEAM_ABBREVIATION'],
                        'wins': int(home_team['TEAM_WINS_LOSSES'].split('-')[0]),
                        'losses': int(home_team['TEAM_WINS_LOSSES'].split('-')[1]),
                        'win_probability': 0.5  # Placeholder, would be calculated by prediction model
                    },
                    'away_team': {
                        'team_id': str(away_team_id),
                        'team_name': away_team['TEAM_NAME'],
                        'team_city': away_team['TEAM_CITY'],
                        'team_tricode': away_team['TEAM_ABBREVIATION'],
                        'wins': int(away_team['TEAM_WINS_LOSSES'].split('-')[0]),
                        'losses': int(away_team['TEAM_WINS_LOSSES'].split('-')[1]),
                        'win_probability': 0.5  # Placeholder, would be calculated by prediction model
                    },
                    'game_status': row['GAME_STATUS_TEXT'],
                    'game_date': date_str,
                    'game_time': row['GAME_STATUS_TEXT'] if row['GAME_STATUS_TEXT'] != '' else '8:00 PM ET',
                    'arena': row['ARENA_NAME'],
                    'city': row['ARENA_CITY'],
                    'has_prediction': True
                }
                
                # Add win probabilities (simplified example)
                home_wins = game_dict['home_team']['wins']
                home_losses = game_dict['home_team']['losses']
                away_wins = game_dict['away_team']['wins']
                away_losses = game_dict['away_team']['losses']
                
                # Simple win probability based on win percentage
                if home_wins + home_losses > 0 and away_wins + away_losses > 0:
                    home_win_pct = home_wins / (home_wins + home_losses)
                    away_win_pct = away_wins / (away_wins + away_losses)
                    total = home_win_pct + away_win_pct
                    
                    if total > 0:
                        game_dict['home_team']['win_probability'] = round(home_win_pct / total, 2)
                        game_dict['away_team']['win_probability'] = round(away_win_pct / total, 2)
                
                games.append(game_dict)
            
            return games
            
        except Exception as e:
            print(f"Error getting games for date {date_str}: {e}")
            return []
