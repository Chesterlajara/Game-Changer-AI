import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from nba_api.stats.endpoints import leaguegamefinder, teamgamelog, playergamelog
import datetime

class PredictionModel:
    """
    Machine learning model for predicting NBA game outcomes
    """
    def __init__(self):
        self.model = None
        self.features = [
            'home_team_win_pct', 'away_team_win_pct',
            'home_team_points_avg', 'away_team_points_avg',
            'home_team_rebounds_avg', 'away_team_rebounds_avg',
            'home_team_assists_avg', 'away_team_assists_avg',
            'home_court_advantage'
        ]
        self._initialize_model()
    
    def _initialize_model(self):
        """Initialize a basic random forest model"""
        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
        # In a real implementation, we would load a pre-trained model here
        # For now, we'll use mock predictions
    
    def _get_team_stats(self, team_id, last_n_games=10):
        """Get recent team statistics"""
        try:
            # This would fetch real data from NBA API
            # For now, return mock data
            return {
                'win_pct': np.random.uniform(0.3, 0.7),
                'points_avg': np.random.uniform(95, 115),
                'rebounds_avg': np.random.uniform(35, 50),
                'assists_avg': np.random.uniform(20, 30)
            }
        except Exception as e:
            print(f"Error getting team stats: {e}")
            return None
    
    def predict(self, game_id):
        """
        Predict the outcome of a specific game
        
        Args:
            game_id: NBA game ID
            
        Returns:
            Dictionary with prediction details
        """
        try:
            # In a real implementation, we would:
            # 1. Fetch team IDs from the game_id
            # 2. Get recent stats for both teams
            # 3. Create feature vector
            # 4. Run prediction with trained model
            
            # For now, return mock prediction
            home_win_prob = np.random.uniform(0.4, 0.6)
            
            # Generate explanation factors
            factors = [
                {'name': 'Home Court Advantage', 'impact': round(np.random.uniform(0.05, 0.15), 2)},
                {'name': 'Recent Team Performance', 'impact': round(np.random.uniform(0.05, 0.2), 2)},
                {'name': 'Star Player Impact', 'impact': round(np.random.uniform(0.1, 0.25), 2)},
                {'name': 'Head-to-Head History', 'impact': round(np.random.uniform(0.03, 0.1), 2)}
            ]
            
            return {
                'game_id': game_id,
                'home_win_probability': round(home_win_prob, 2),
                'away_win_probability': round(1 - home_win_prob, 2),
                'factors': factors
            }
        except Exception as e:
            print(f"Error making prediction: {e}")
            return None
    
    def simulate(self, home_team, away_team, player_adjustments=None):
        """
        Run a custom game simulation
        
        Args:
            home_team: Home team ID
            away_team: Away team ID
            player_adjustments: Dict of player adjustments
            
        Returns:
            Dictionary with simulation results
        """
        try:
            # Get team stats
            home_stats = self._get_team_stats(home_team)
            away_stats = self._get_team_stats(away_team)
            
            # Apply home court advantage
            home_advantage = 0.1
            
            # Calculate base win probability
            home_strength = home_stats['win_pct'] * (1 + home_advantage)
            away_strength = away_stats['win_pct']
            
            # Calculate win probability
            total_strength = home_strength + away_strength
            home_win_prob = home_strength / total_strength
            
            # Apply player adjustments if provided
            if player_adjustments:
                # This would adjust the probability based on player availability
                # For now, just add some random noise
                home_win_prob += np.random.uniform(-0.05, 0.05)
                home_win_prob = max(0.1, min(0.9, home_win_prob))
            
            # Generate predicted score
            home_score = int(home_stats['points_avg'] + np.random.normal(0, 5))
            away_score = int(away_stats['points_avg'] + np.random.normal(0, 5))
            
            # Ensure score aligns with win probability
            if (home_score > away_score and home_win_prob < 0.5) or (home_score < away_score and home_win_prob > 0.5):
                if home_win_prob > 0.5:
                    home_score, away_score = max(home_score, away_score + 1), min(away_score, home_score - 1)
                else:
                    home_score, away_score = min(home_score, away_score - 1), max(away_score, home_score + 1)
            
            # Generate key factors
            key_factors = [
                {'player_name': f"{home_team} Star Player", 'team': home_team, 'impact': round(np.random.uniform(0.1, 0.3), 2)},
                {'player_name': f"{away_team} Star Player", 'team': away_team, 'impact': round(np.random.uniform(0.1, 0.3), 2)}
            ]
            
            return {
                'home_team': home_team,
                'away_team': away_team,
                'home_win_probability': round(home_win_prob, 2),
                'away_win_probability': round(1 - home_win_prob, 2),
                'predicted_score': {
                    'home': home_score,
                    'away': away_score
                },
                'key_factors': key_factors
            }
        except Exception as e:
            print(f"Error in simulation: {e}")
            return None
    
    def get_explanation_factors(self, game_id):
        """
        Get detailed explanation of prediction factors
        
        Args:
            game_id: NBA game ID
            
        Returns:
            Dictionary with explanation factors
        """
        try:
            # In a real implementation, we would extract feature importances
            # from the trained model and map them to human-readable explanations
            
            # For now, return mock explanation factors
            factors = [
                {
                    'name': 'Home Court Advantage',
                    'impact': round(np.random.uniform(0.05, 0.15), 2),
                    'description': 'Teams typically perform better when playing at their home arena.'
                },
                {
                    'name': 'Recent Team Performance',
                    'impact': round(np.random.uniform(0.05, 0.2), 2),
                    'description': 'How well the team has performed in recent games.'
                },
                {
                    'name': 'Star Player Impact',
                    'impact': round(np.random.uniform(0.1, 0.25), 2),
                    'description': 'The influence of key players on game outcomes.'
                },
                {
                    'name': 'Head-to-Head History',
                    'impact': round(np.random.uniform(0.03, 0.1), 2),
                    'description': 'Historical performance when these teams have played each other.'
                },
                {
                    'name': 'Injuries',
                    'impact': round(np.random.uniform(0.05, 0.15), 2),
                    'description': 'The effect of injured players on team performance.'
                },
                {
                    'name': 'Rest Days',
                    'impact': round(np.random.uniform(0.03, 0.08), 2),
                    'description': 'Number of days since the last game for each team.'
                }
            ]
            
            # Sort by impact
            factors.sort(key=lambda x: x['impact'], reverse=True)
            
            return {
                'game_id': game_id,
                'factors': factors,
                'methodology': 'This prediction is based on historical team performance, player statistics, and situational factors like home court advantage.'
            }
        except Exception as e:
            print(f"Error getting explanation factors: {e}")
            return None
