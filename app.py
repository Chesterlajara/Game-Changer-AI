from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import pandas as pd
import numpy as np
from nba_api.stats.endpoints import playercareerstats, leaguegamefinder, scoreboardv2
from nba_api.live.nba.endpoints import scoreboard as live_scoreboard
import datetime
from models.prediction import PredictionModel
from models.game_analysis import GameAnalysis

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter frontend

# Initialize models
prediction_model = PredictionModel()
game_analysis = GameAnalysis()

# API Routes for Flutter Frontend
@app.route('/api/games', methods=['GET'])
def get_games():
    """Get games categorized as Today, Upcoming, and Live with prediction data"""
    try:
        # Get filter parameter (optional)
        category = request.args.get('category', None)  # 'today', 'upcoming', 'live', or None for all
        
        # In a real implementation, we would fetch from NBA API
        # For now, generate mock data that matches the Home Page UI
        
        # Today's games (including live games)
        today_games = [
            {
                'id': '0022400001',
                'home_team': {
                    'id': '1610612747',
                    'name': 'Lakers',
                    'abbreviation': 'LAL',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612747/global/L/logo.svg',
                    'score': 78
                },
                'away_team': {
                    'id': '1610612738',
                    'name': 'Celtics',
                    'abbreviation': 'BOS',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612738/global/L/logo.svg',
                    'score': 65
                },
                'status': 'LIVE',
                'game_clock': '3:24',
                'period': 3,
                'start_time': '2025-05-03T19:30:00Z',
                'prediction': {
                    'home_win_probability': 0.65,
                    'away_win_probability': 0.35
                }
            },
            {
                'id': '0022400002',
                'home_team': {
                    'id': '1610612744',
                    'name': 'Warriors',
                    'abbreviation': 'GSW',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612744/global/L/logo.svg',
                    'score': 0
                },
                'away_team': {
                    'id': '1610612751',
                    'name': 'Nets',
                    'abbreviation': 'BKN',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612751/global/L/logo.svg',
                    'score': 0
                },
                'status': 'SCHEDULED',
                'game_clock': '',
                'period': 0,
                'start_time': '2025-05-03T20:00:00Z',  # 8:00 PM local time
                'prediction': {
                    'home_win_probability': 0.42,
                    'away_win_probability': 0.58
                }
            }
        ]
        
        # Upcoming games (next few days)
        upcoming_games = [
            {
                'id': '0022400003',
                'home_team': {
                    'id': '1610612745',
                    'name': 'Rockets',
                    'abbreviation': 'HOU',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612745/global/L/logo.svg',
                    'score': 0
                },
                'away_team': {
                    'id': '1610612759',
                    'name': 'Spurs',
                    'abbreviation': 'SAS',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612759/global/L/logo.svg',
                    'score': 0
                },
                'status': 'SCHEDULED',
                'game_clock': '',
                'period': 0,
                'start_time': '2025-05-04T18:00:00Z',
                'prediction': {
                    'home_win_probability': 0.53,
                    'away_win_probability': 0.47
                }
            },
            {
                'id': '0022400004',
                'home_team': {
                    'id': '1610612748',
                    'name': 'Heat',
                    'abbreviation': 'MIA',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612748/global/L/logo.svg',
                    'score': 0
                },
                'away_team': {
                    'id': '1610612752',
                    'name': 'Knicks',
                    'abbreviation': 'NYK',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612752/global/L/logo.svg',
                    'score': 0
                },
                'status': 'SCHEDULED',
                'game_clock': '',
                'period': 0,
                'start_time': '2025-05-04T19:30:00Z',
                'prediction': {
                    'home_win_probability': 0.48,
                    'away_win_probability': 0.52
                }
            }
        ]
        
        # Live games (subset of today's games)
        live_games = [game for game in today_games if game['status'] == 'LIVE']
        
        # Filter based on category parameter
        if category == 'today':
            games = today_games
        elif category == 'upcoming':
            games = upcoming_games
        elif category == 'live':
            games = live_games
        else:
            # Return all categories with their respective games
            return jsonify({
                'today': today_games,
                'upcoming': upcoming_games,
                'live': live_games
            })
            
        return jsonify({'games': games})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/player/<player_id>', methods=['GET'])
def get_player_stats(player_id):
    """Get player career stats"""
    try:
        career = playercareerstats.PlayerCareerStats(player_id=player_id)
        return jsonify(career.get_dict())
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/predictions/<game_id>', methods=['GET'])
def get_prediction(game_id):
    """Get detailed prediction for a specific game"""
    try:
        # Use our prediction model
        prediction = prediction_model.predict(game_id)
        return jsonify(prediction)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/simulation', methods=['POST'])
def run_simulation():
    """Run a custom game simulation with user-selected parameters"""
    try:
        simulation_params = request.json
        home_team = simulation_params.get('home_team')
        away_team = simulation_params.get('away_team')
        player_adjustments = simulation_params.get('player_adjustments', {})
        
        # Use our prediction model for simulation
        result = prediction_model.simulate(home_team, away_team, player_adjustments)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/teams', methods=['GET'])
def get_teams():
    """Get list of all NBA teams"""
    try:
        # Mock team data (will be replaced with actual NBA API data)
        teams = [
            {'id': '1610612737', 'name': 'Atlanta Hawks', 'abbreviation': 'ATL'},
            {'id': '1610612738', 'name': 'Boston Celtics', 'abbreviation': 'BOS'},
            {'id': '1610612739', 'name': 'Cleveland Cavaliers', 'abbreviation': 'CLE'},
            {'id': '1610612740', 'name': 'New Orleans Pelicans', 'abbreviation': 'NOP'},
            {'id': '1610612741', 'name': 'Chicago Bulls', 'abbreviation': 'CHI'},
            {'id': '1610612742', 'name': 'Dallas Mavericks', 'abbreviation': 'DAL'},
            {'id': '1610612743', 'name': 'Denver Nuggets', 'abbreviation': 'DEN'},
            {'id': '1610612744', 'name': 'Golden State Warriors', 'abbreviation': 'GSW'},
            {'id': '1610612745', 'name': 'Houston Rockets', 'abbreviation': 'HOU'},
            {'id': '1610612746', 'name': 'Los Angeles Clippers', 'abbreviation': 'LAC'},
            {'id': '1610612747', 'name': 'Los Angeles Lakers', 'abbreviation': 'LAL'}
        ]
        return jsonify({'teams': teams})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/prediction-factors/<game_id>', methods=['GET'])
def get_prediction_factors(game_id):
    """Get detailed explanation of prediction factors for transparency page"""
    try:
        # Use our prediction model to get explanation factors
        factors = prediction_model.get_explanation_factors(game_id)
        return jsonify(factors)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/game-analysis/<game_id>', methods=['GET'])
def get_game_analysis(game_id):
    """Get comprehensive game analysis for the View Analysis button"""
    try:
        # Use our game analysis model to get detailed analysis
        analysis = game_analysis.get_game_analysis(game_id)
        return jsonify(analysis)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
