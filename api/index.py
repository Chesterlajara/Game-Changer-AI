from flask import Flask, jsonify, request
from flask_cors import CORS
import random
import datetime
import sys
import os

# Add parent directory to path to find modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import the TeamPredictionModel
from ml_models.predict_winner import TeamPredictionModel
from ml_models import player_availability, performance_factors
from ml_models.player_availability import remove_players_and_get_team_data

# Import other models
from models.game_model import GameModel
from models.prediction import PredictionModel
from models.game_analysis import GameAnalysis
from models.team_stats import TeamStats
from models.player_stats import PlayerStats

# Import NBA API packages
from nba_api.stats.endpoints import teamdashboardbygeneralsplits, leaguedashteamstats
from nba_api.stats.static import teams
import pandas as pd

# Dictionary to cache team stats to avoid repeated API calls
team_stats_cache = {}

# Load fallback data from CSV files
def load_fallback_team_data():
    try:
        csv_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data', 'team_data.csv')
        if os.path.exists(csv_path):
            print(f"Loading fallback team data from {csv_path}")
            df = pd.read_csv(csv_path)
            
            # Group by team and get the most recent data for each team
            team_data = {}
            for team_name, group in df.groupby('TEAM_NAME'):
                # Get the most recent game data for this team
                latest_data = group.sort_values('GAME_DATE', ascending=False).iloc[0]
                
                # Convert to the format our model expects
                team_data[team_name] = {
                    'W': int(latest_data['W']),
                    'L': int(latest_data['L']),
                    'W_PCT': float(latest_data['W_PCT']),
                    'MIN': float(latest_data.get('MIN', 240)),
                    'FGM': float(latest_data['FGM']),
                    'FGA': float(latest_data['FGA']),
                    'FG_PCT': float(latest_data['FG_PCT']),
                    'FG3M': float(latest_data['FG3M']),
                    'FG3A': float(latest_data['FG3A']),
                    'FG3_PCT': float(latest_data['FG3_PCT']),
                    'FTM': float(latest_data['FTM']),
                    'FTA': float(latest_data['FTA']),
                    'FT_PCT': float(latest_data['FT_PCT']),
                    'OREB': float(latest_data['OREB']),
                    'DREB': float(latest_data['DREB']),
                    'REB': float(latest_data['REB']),
                    'AST': float(latest_data['AST']),
                    'STL': float(latest_data['STL']),
                    'BLK': float(latest_data['BLK']),
                    'TOV': float(latest_data['TOV']),
                    'PF': float(latest_data['PF']),
                    'PTS': float(latest_data['PTS']),
                    'TEAM_ABBR': str(latest_data['TEAM_ABBREVIATION'])
                }
            return team_data
        else:
            print(f"Warning: Fallback team data file not found at {csv_path}")
            return {}
    except Exception as e:
        print(f"Error loading fallback team data: {e}")
        return {}

# Load fallback data on startup
fallback_team_data = load_fallback_team_data()

app = Flask(__name__)
CORS(app)

# Initialize the ML prediction model
try:
    model_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'ml_models')
    ml_prediction_model = TeamPredictionModel(
        os.path.join(model_dir, "xgb_model.pkl"), 
        os.path.join(model_dir, "scaler.pkl"), 
        os.path.join(model_dir, "imputer.pkl"), 
        os.path.join(model_dir, "x_columns.pkl")
    )
    print("ML prediction model loaded successfully")
except Exception as e:
    print(f"Error loading ML prediction model: {e}")
    ml_prediction_model = None

# Initialize other models
game_model = GameModel()
prediction_model = PredictionModel()
game_analysis = GameAnalysis()
team_stats = TeamStats()
player_stats = PlayerStats()

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        'message': 'Game Changer AI API is running',
        'endpoints': [
            '/api/games',
            '/api/game-analysis/<game_id>',
            '/api/team-standings',
            '/api/player-standings',
            '/api/predict-winner',
            '/api/predict-teams',
            '/api/get-team-stats',
            '/api/predict-with-performance-factors'
        ]
    })

# Import all the routes from the original app.py
from app import predict_winner, predict_teams, get_team_stats, predict_with_performance_factors
from app import get_games, get_player_stats, get_prediction, run_simulation
from app import get_teams, get_prediction_factors, get_game_analysis
from app import get_team_standings, get_player_standings
from app import get_team_offensive_stats, get_team_defensive_stats

# Map the routes to this app
app.route('/api/predict-winner', methods=['POST'])(predict_winner)
app.route('/api/predict-teams', methods=['POST'])(predict_teams)
app.route('/api/get-team-stats', methods=['POST'])(get_team_stats)
app.route('/api/predict-with-performance-factors', methods=['POST'])(predict_with_performance_factors)
app.route('/api/games', methods=['GET'])(get_games)
app.route('/api/player-stats/<int:player_id>', methods=['GET'])(get_player_stats)
app.route('/api/prediction/<string:game_id>', methods=['GET'])(get_prediction)
app.route('/api/simulation', methods=['POST'])(run_simulation)
app.route('/api/teams', methods=['GET'])(get_teams)
app.route('/api/prediction-factors/<string:game_id>', methods=['GET'])(get_prediction_factors)
app.route('/api/game-analysis/<string:game_id>', methods=['GET'])(get_game_analysis)
app.route('/api/team-standings', methods=['GET'])(get_team_standings)
app.route('/api/player-standings', methods=['GET'])(get_player_standings)
app.route('/api/team-offensive-stats', methods=['GET'])(get_team_offensive_stats)
app.route('/api/team-defensive-stats', methods=['GET'])(get_team_defensive_stats)

# For Vercel serverless deployment
def handler(request, context):
    return app(request['body'], request['headers'])
