import numpy as np
import pandas as pd
from datetime import datetime, timedelta

class GameAnalysis:
    """
    Class for generating detailed game analysis and prediction explanations
    """
    def __init__(self):
        pass
    
    def get_game_analysis(self, game_id):
        """
        Generate comprehensive analysis for a specific game
        
        Args:
            game_id: NBA game ID
            
        Returns:
            Dictionary with detailed analysis
        """
        try:
            # In a real implementation, we would:
            # 1. Fetch detailed game data
            # 2. Get team and player stats
            # 3. Run prediction models
            # 4. Generate visualizations
            
            # For now, return mock analysis data
            analysis = {
                'game_id': game_id,
                'summary': {
                    'title': 'Lakers vs Celtics Prediction Analysis',
                    'description': 'Our AI model predicts a Lakers victory with 65% confidence based on recent performance, home court advantage, and key player matchups.',
                    'key_insight': 'LeBron James\' recent triple-double streak is a major factor in this prediction.'
                },
                'prediction': {
                    'home_win_probability': 0.65,
                    'away_win_probability': 0.35,
                    'predicted_score': {
                        'home': 112,
                        'away': 104
                    },
                    'confidence_level': 'High'
                },
                'key_factors': [
                    {
                        'name': 'Home Court Advantage',
                        'impact': 0.12,
                        'description': 'Lakers have won 80% of their home games this season.'
                    },
                    {
                        'name': 'Recent Team Performance',
                        'impact': 0.18,
                        'description': 'Lakers are on a 5-game winning streak, while Celtics have lost 3 of their last 5.'
                    },
                    {
                        'name': 'Star Player Impact',
                        'impact': 0.25,
                        'description': 'LeBron James and Anthony Davis have both been performing above their season averages.'
                    },
                    {
                        'name': 'Head-to-Head History',
                        'impact': 0.08,
                        'description': 'Lakers have won 3 of the last 5 matchups against the Celtics.'
                    }
                ],
                'player_matchups': [
                    {
                        'position': 'Point Guard',
                        'home_player': {
                            'name': 'D\'Angelo Russell',
                            'impact_score': 7.2,
                            'key_stat': '8.5 assists per game'
                        },
                        'away_player': {
                            'name': 'Jrue Holiday',
                            'impact_score': 7.8,
                            'key_stat': '1.8 steals per game'
                        },
                        'advantage': 'Celtics',
                        'advantage_factor': 0.6
                    },
                    {
                        'position': 'Small Forward',
                        'home_player': {
                            'name': 'LeBron James',
                            'impact_score': 9.5,
                            'key_stat': '28.7 points per game'
                        },
                        'away_player': {
                            'name': 'Jayson Tatum',
                            'impact_score': 9.2,
                            'key_stat': '26.9 points per game'
                        },
                        'advantage': 'Lakers',
                        'advantage_factor': 0.3
                    }
                ],
                'team_comparison': {
                    'offense': {
                        'home': 114.2,  # Points per game
                        'away': 116.8
                    },
                    'defense': {
                        'home': 108.5,  # Points allowed per game
                        'away': 110.2
                    },
                    'rebounding': {
                        'home': 45.8,
                        'away': 44.2
                    },
                    'assists': {
                        'home': 26.4,
                        'away': 24.8
                    },
                    'turnovers': {
                        'home': 13.2,
                        'away': 12.8
                    }
                },
                'historical_matchups': {
                    'last_five_games': [
                        {
                            'date': '2025-01-15',
                            'home_team': 'Lakers',
                            'away_team': 'Celtics',
                            'home_score': 108,
                            'away_score': 102,
                            'winner': 'Lakers'
                        },
                        {
                            'date': '2024-11-30',
                            'home_team': 'Celtics',
                            'away_team': 'Lakers',
                            'home_score': 115,
                            'away_score': 110,
                            'winner': 'Celtics'
                        },
                        {
                            'date': '2024-03-20',
                            'home_team': 'Lakers',
                            'away_team': 'Celtics',
                            'home_score': 121,
                            'away_score': 118,
                            'winner': 'Lakers'
                        }
                    ],
                    'all_time': {
                        'total_games': 365,
                        'lakers_wins': 162,
                        'celtics_wins': 203
                    }
                },
                'visualization_data': {
                    'win_probability_chart': [
                        {'date': '2025-04-28', 'probability': 0.52},
                        {'date': '2025-04-29', 'probability': 0.55},
                        {'date': '2025-04-30', 'probability': 0.58},
                        {'date': '2025-05-01', 'probability': 0.61},
                        {'date': '2025-05-02', 'probability': 0.63},
                        {'date': '2025-05-03', 'probability': 0.65}
                    ],
                    'key_stats_radar': {
                        'categories': ['Scoring', 'Defense', 'Rebounding', 'Assists', 'Turnovers'],
                        'home_values': [8.5, 7.8, 8.2, 9.0, 7.5],
                        'away_values': [9.0, 8.2, 7.5, 8.0, 8.0]
                    },
                    'factor_impact_chart': [
                        {'factor': 'Star Player Impact', 'value': 0.25},
                        {'factor': 'Recent Team Performance', 'value': 0.18},
                        {'factor': 'Home Court Advantage', 'value': 0.12},
                        {'factor': 'Head-to-Head History', 'value': 0.08},
                        {'factor': 'Rest Days', 'value': 0.05}
                    ]
                }
            }
            
            return analysis
        except Exception as e:
            print(f"Error generating game analysis: {e}")
            return None
