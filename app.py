from flask import Flask, jsonify, request
from flask_cors import CORS
import random
import datetime

# Import the TeamPredictionModel
from ml_models.predict_winner import TeamPredictionModel

# Import other models
from models.game_model import GameModel
from models.prediction import PredictionModel
from models.game_analysis import GameAnalysis
from models.team_stats import TeamStats
from models.player_stats import PlayerStats

app = Flask(__name__)
CORS(app)

# Initialize the ML prediction model
try:
    ml_prediction_model = TeamPredictionModel(
        "ml_models/xgb_model.pkl", 
        "ml_models/scaler.pkl", 
        "ml_models/imputer.pkl", 
        "ml_models/x_columns.pkl"
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

@app.route('/api/predict-winner', methods=['POST'])
def predict_winner():
    try:
        data = request.get_json()
        team1_stats = data.get('team1_stats')
        team2_stats = data.get('team2_stats')
        
        if not team1_stats or not team2_stats:
            return jsonify({'error': 'Both team stats are required'}), 400
            
        results = ml_prediction_model.predict(team1_stats, team2_stats)
        return jsonify(results)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/games', methods=['GET'])
def get_games():
    try:
        # Get filter parameter (optional)
        category = request.args.get('category', None)  # 'today', 'upcoming', 'live', or None for all
        
        # In a real implementation, we would fetch from NBA API
        # For now, generate mock data that matches the Home Page UI
        
        # Get current date for mock data
        import datetime
        current_date = datetime.datetime.now()
        today_str = current_date.strftime('%Y-%m-%dT%H:%M:%SZ')
        # Create dates for May 6 and May 8, 2025
        may_6_date = datetime.datetime(2025, 5, 6, current_date.hour, current_date.minute)
        may_6_str = may_6_date.strftime('%Y-%m-%dT%H:%M:%SZ')
        may_8_date = datetime.datetime(2025, 5, 8, current_date.hour, current_date.minute)
        may_8_str = may_8_date.strftime('%Y-%m-%dT%H:%M:%SZ')
        
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
                'start_time': today_str,  # Today's date for Live tab
                'prediction': get_prediction_for_teams('Lakers', 'Celtics')
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
                'start_time': today_str,  # Today's date for Today tab
                'prediction': get_prediction_for_teams('Warriors', 'Nets')
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
                'start_time': may_6_str,  # May 6, 2025 for Upcoming tab
                'prediction': get_prediction_for_teams('Rockets', 'Spurs')
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
                'start_time': may_8_str,  # May 8, 2025 for Upcoming tab
                'prediction': get_prediction_for_teams('Heat', 'Knicks')
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

@app.route('/api/team-standings', methods=['GET'])
def get_team_standings():
    """Get team standings with option to filter by conference and sort by different criteria"""
    try:
        # Get filter parameters (optional)
        conference = request.args.get('conference', None)  # 'East', 'West', or None for all
        sort_by = request.args.get('sort_by', 'Win %')  # Default to Win %
        
        print(f"API received conference filter: {conference}, sort_by: {sort_by}")
        print(f"Conference parameter type: {type(conference)}")
        print(f"Conference parameter exact value: '{conference}'")
        print(f"Sort by parameter exact value: '{sort_by}'")
        print(f"Request URL: {request.url}")
        print(f"Request args: {request.args}")
        
        # Ensure conference is properly formatted
        if conference == '' or conference == 'All':
            conference = None
        print(f"Conference parameter after formatting: '{conference}'")
        print(f"Final values being sent to get_team_standings: conference={conference}, sort_by={sort_by}")
        
        # Use our team stats model to get standings with sorting
        standings = team_stats.get_team_standings(conference, sort_by)
        
        # Log the number of teams returned after filtering
        if 'standings' in standings:
            print(f"API returning {len(standings['standings'])} teams for conference: {conference}, sorted by: {sort_by}")
        
        return jsonify(standings)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/player-standings', methods=['GET'])
def get_player_standings():
    """Get player standings with option to filter by conference and sort by different stat categories"""
    try:
        # Get filter parameters (optional)
        conference = request.args.get('conference', None)  # 'East', 'West', or None for all
        sort_by = request.args.get('sort_by', 'Points')  # UI display name (Points, Rebounds, etc.)
        
        # Convert UI sort_by to API stat_category
        stat_category = 'PTS'  # Default to points
        if sort_by == 'Rebounds':
            stat_category = 'REB'
        elif sort_by == 'Assists':
            stat_category = 'AST'
        elif sort_by == 'Steals':
            stat_category = 'STL'
        elif sort_by == 'Blocks':
            stat_category = 'BLK'
        
        # Also check for direct stat_category parameter (for backward compatibility)
        direct_stat = request.args.get('stat_category', None)
        if direct_stat:
            stat_category = direct_stat
        
        print(f"API received player standings request - conference: {conference}, sort_by: {sort_by}, stat_category: {stat_category}")
        print(f"Request URL: {request.url}")
        print(f"Request args: {request.args}")
        
        # Ensure conference is properly formatted
        if conference == '' or conference == 'All':
            conference = None
        print(f"Conference parameter after formatting: '{conference}'")
        print(f"Final values being sent to get_player_standings: conference={conference}, stat_category={stat_category}")
        
        # Use our player stats model to get standings
        standings = player_stats.get_player_standings(conference, stat_category)
        
        # Log the number of players returned after filtering
        if 'standings' in standings:
            print(f"API returning {len(standings['standings'])} players for conference: {conference}, sorted by: {stat_category}")
        
        return jsonify(standings)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/team-offensive-stats', methods=['GET'])
def get_team_offensive_stats():
    """Get team offensive statistics with option to filter by conference"""
    try:
        # Get conference filter parameter (optional)
        conference = request.args.get('conference', None)  # 'East', 'West', or None for all
        
        # Use our team stats model to get offensive stats
        offensive_stats = team_stats.get_team_offensive_stats(conference)
        return jsonify(offensive_stats)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/team-defensive-stats', methods=['GET'])
def get_team_defensive_stats():
    """Get team defensive statistics with option to filter by conference"""
    try:
        # Get conference filter parameter (optional)
        conference = request.args.get('conference', None)  # 'East', 'West', or None for all
        
        # Use our team stats model to get defensive stats
        defensive_stats = team_stats.get_team_defensive_stats(conference)
        return jsonify(defensive_stats)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Helper function to get predictions for teams by name
def get_prediction_for_teams(home_team_name, away_team_name):
    # This is a simplified version - in a real app, you would fetch actual team stats
    # from a database or API based on the team names
    
    # Sample team stats based on the example in predict_winner.py
    team_stats = {
        'Lakers': {
            'W': 28, 'L': 15, 'W_PCT': 0.65, 'MIN': 240, 'FGM': 42, 'FGA': 90, 'FG_PCT': 0.47,
            'FG3M': 12, 'FG3A': 35, 'FG3_PCT': 0.34, 'FTM': 20, 'FTA': 25, 'FT_PCT': 0.80,
            'OREB': 10, 'DREB': 35, 'REB': 45, 'AST': 25, 'STL': 7, 'BLK': 5, 'TOV': 13, 'PF': 18,
            'PTS': 116, 'TEAM_ABBR': 'LAL'
        },
        'Celtics': {
            'W': 32, 'L': 12, 'W_PCT': 0.73, 'MIN': 240, 'FGM': 40, 'FGA': 88, 'FG_PCT': 0.45,
            'FG3M': 15, 'FG3A': 38, 'FG3_PCT': 0.39, 'FTM': 22, 'FTA': 28, 'FT_PCT': 0.79,
            'OREB': 9, 'DREB': 34, 'REB': 43, 'AST': 26, 'STL': 8, 'BLK': 6, 'TOV': 12, 'PF': 17,
            'PTS': 117, 'TEAM_ABBR': 'BOS'
        },
        'Warriors': {
            'W': 25, 'L': 18, 'W_PCT': 0.58, 'MIN': 240, 'FGM': 41, 'FGA': 89, 'FG_PCT': 0.46,
            'FG3M': 14, 'FG3A': 37, 'FG3_PCT': 0.38, 'FTM': 18, 'FTA': 23, 'FT_PCT': 0.78,
            'OREB': 8, 'DREB': 33, 'REB': 41, 'AST': 28, 'STL': 8, 'BLK': 4, 'TOV': 14, 'PF': 19,
            'PTS': 114, 'TEAM_ABBR': 'GSW'
        },
        'Nets': {
            'W': 20, 'L': 23, 'W_PCT': 0.47, 'MIN': 240, 'FGM': 39, 'FGA': 87, 'FG_PCT': 0.45,
            'FG3M': 12, 'FG3A': 33, 'FG3_PCT': 0.36, 'FTM': 19, 'FTA': 25, 'FT_PCT': 0.76,
            'OREB': 9, 'DREB': 32, 'REB': 41, 'AST': 24, 'STL': 7, 'BLK': 5, 'TOV': 15, 'PF': 20,
            'PTS': 109, 'TEAM_ABBR': 'BKN'
        },
        'Rockets': {
            'W': 18, 'L': 25, 'W_PCT': 0.42, 'MIN': 240, 'FGM': 38, 'FGA': 86, 'FG_PCT': 0.44,
            'FG3M': 11, 'FG3A': 32, 'FG3_PCT': 0.34, 'FTM': 20, 'FTA': 26, 'FT_PCT': 0.77,
            'OREB': 10, 'DREB': 31, 'REB': 41, 'AST': 22, 'STL': 8, 'BLK': 4, 'TOV': 16, 'PF': 21,
            'PTS': 107, 'TEAM_ABBR': 'HOU'
        },
        'Spurs': {
            'W': 16, 'L': 27, 'W_PCT': 0.37, 'MIN': 240, 'FGM': 37, 'FGA': 85, 'FG_PCT': 0.44,
            'FG3M': 10, 'FG3A': 30, 'FG3_PCT': 0.33, 'FTM': 18, 'FTA': 24, 'FT_PCT': 0.75,
            'OREB': 9, 'DREB': 30, 'REB': 39, 'AST': 23, 'STL': 7, 'BLK': 4, 'TOV': 15, 'PF': 20,
            'PTS': 102, 'TEAM_ABBR': 'SAS'
        },
        'Heat': {
            'W': 24, 'L': 19, 'W_PCT': 0.56, 'MIN': 240, 'FGM': 39, 'FGA': 86, 'FG_PCT': 0.45,
            'FG3M': 13, 'FG3A': 34, 'FG3_PCT': 0.38, 'FTM': 19, 'FTA': 24, 'FT_PCT': 0.79,
            'OREB': 8, 'DREB': 32, 'REB': 40, 'AST': 25, 'STL': 7, 'BLK': 5, 'TOV': 13, 'PF': 18,
            'PTS': 110, 'TEAM_ABBR': 'MIA'
        },
        'Knicks': {
            'W': 26, 'L': 17, 'W_PCT': 0.60, 'MIN': 240, 'FGM': 40, 'FGA': 87, 'FG_PCT': 0.46,
            'FG3M': 12, 'FG3A': 32, 'FG3_PCT': 0.38, 'FTM': 20, 'FTA': 25, 'FT_PCT': 0.80,
            'OREB': 9, 'DREB': 33, 'REB': 42, 'AST': 24, 'STL': 8, 'BLK': 5, 'TOV': 14, 'PF': 19,
            'PTS': 112, 'TEAM_ABBR': 'NYK'
        }
    }
    
    # Get team stats or use defaults if not found
    home_stats = team_stats.get(home_team_name, team_stats['Lakers'])
    away_stats = team_stats.get(away_team_name, team_stats['Celtics'])
    
    # Get prediction
    try:
        if ml_prediction_model is None:
            raise Exception("ML prediction model not loaded")
            
        results = ml_prediction_model.predict(home_stats, away_stats)
        print(f"Prediction for {home_team_name} vs {away_team_name}: {results}")
        
        return {
            'home_win_probability': float(results['team1_win_prob']),
            'away_win_probability': float(results['team2_win_prob'])
        }
    except Exception as e:
        print(f"Error predicting winner: {e}")
        # Fallback to random probabilities that sum to 1
        home_prob = round(random.uniform(0.4, 0.6), 2)
        return {
            'home_win_probability': home_prob,
            'away_win_probability': round(1 - home_prob, 2)
        }

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
