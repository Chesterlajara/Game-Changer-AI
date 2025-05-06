from flask import Flask, jsonify, request
from flask_cors import CORS
import random
import datetime

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
import os

# Dictionary to cache team stats to avoid repeated API calls
team_stats_cache = {}

# Load fallback data from CSV files
def load_fallback_team_data():
    try:
        csv_path = os.path.join('data', 'team_data.csv')
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
        print(f"Error in predict_winner: {e}")
        return jsonify({
            'error': str(e), 
            'winner': 'Unknown', 
            'team1_win_prob': 0.5, 
            'team2_win_prob': 0.5
        }), 500

@app.route('/predict', methods=['POST'])
def predict_teams():
    try:
        data = request.get_json()
        team1_name = data.get('team1')
        team2_name = data.get('team2')
        
        if not team1_name or not team2_name:
            return jsonify({'error': 'Both team names are required'}), 400
            
        # Get prediction for these teams
        prediction = get_prediction_for_teams(team1_name, team2_name)
        
        # Format response
        response = {
            'winner': team1_name if prediction['team1_win_probability'] > prediction['team2_win_probability'] else team2_name,
            'team1_win_prob': prediction['team1_win_probability'],
            'team2_win_prob': prediction['team2_win_probability']
        }
        
        return jsonify({
            'winner': team1_name if prediction['team1_win_probability'] > prediction['team2_win_probability'] else team2_name,
            'team1_win_prob': prediction['team1_win_probability'],
            'team2_win_prob': prediction['team2_win_probability']
        })
    except Exception as e:
        print(f"Error in predict_teams: {e}")
        return jsonify({
            'error': str(e),
            'winner': 'Unknown',
            'team1_win_prob': 0.5,
            'team2_win_prob': 0.5
        }), 500

@app.route('/get-team-stats', methods=['POST'])
def get_team_stats():
    data = request.get_json()
    team1_name = data.get('team1')
    team2_name = data.get('team2')
    
    result = {'team_stats': {}}
    
    try:
        # Load the team data
        df_team = pd.read_csv('data/team_data.csv')
        
        # Get the most recent stats for each team
        team1_recent = df_team[df_team['MATCHUP'].str.contains(team1_name)].iloc[-5:]
        team2_recent = df_team[df_team['MATCHUP'].str.contains(team2_name)].iloc[-5:]
        
        # If we couldn't find data for the exact team names, try looking for abbreviations
        if team1_recent.empty or team2_recent.empty:
            # Sample NBA teams with abbreviations for fallback
            team_abbrevs = {
                'Lakers': 'LAL', 'Celtics': 'BOS', 'Warriors': 'GSW', 'Bucks': 'MIL',
                'Heat': 'MIA', 'Suns': 'PHX', 'Mavericks': 'DAL', 'Nuggets': 'DEN',
                'Cavaliers': 'CLE', 'Knicks': 'NYK', 'Clippers': 'LAC', 'Grizzlies': 'MEM',
                'Thunder': 'OKC', 'Sixers': 'PHI', 'Spurs': 'SAS', 'Blazers': 'POR',
                'Bulls': 'CHI', 'Rockets': 'HOU', 'Hornets': 'CHA', 'Nets': 'BKN',
                'Magic': 'ORL', 'Pistons': 'DET', 'Hawks': 'ATL', 'Kings': 'SAC',
                'Raptors': 'TOR', 'Pacers': 'IND', 'Timberwolves': 'MIN', 'Pelicans': 'NOP',
                'Jazz': 'UTA', 'Wizards': 'WAS'
            }
            
            # Try to find the team by abbrev if the full name doesn't work
            team1_abbrev = next((abbr for team, abbr in team_abbrevs.items() if team1_name in team), None)
            team2_abbrev = next((abbr for team, abbr in team_abbrevs.items() if team2_name in team), None)
            
            if team1_abbrev and team1_recent.empty:
                team1_recent = df_team[df_team['MATCHUP'].str.contains(team1_abbrev)].iloc[-5:]
                
            if team2_abbrev and team2_recent.empty:
                team2_recent = df_team[df_team['MATCHUP'].str.contains(team2_abbrev)].iloc[-5:]
        
        # Calculate average stats for recent games with some team-specific adjustments
        # to guarantee they're different
        if not team1_recent.empty:
            # Team 1 stats from data with slight randomization
            team1_stats = {
                'PTS': float(max(85, min(120, team1_recent['PTS'].mean() * (1 + 0.05 * (hash(team1_name) % 10) / 10)))),
                'REB': float(max(30, min(55, team1_recent['REB'].mean() * (1 + 0.05 * (hash(team1_name[::-1]) % 10) / 10)))),
                'AST': float(max(15, min(35, team1_recent['AST'].mean() * (1 - 0.05 * (hash(team1_name + 'ast') % 10) / 10)))),
                'STL': float(max(5, min(12, team1_recent['STL'].mean() * (1 + 0.1 * (hash(team1_name + 'stl') % 10) / 10)))),
                'BLK': float(max(3, min(8, team1_recent['BLK'].mean() * (1 - 0.1 * (hash(team1_name + 'blk') % 10) / 10)))),
                'FG3_PCT': float(max(30, min(45, team1_recent['FG3_PCT'].mean() * 100 * (1 + 0.05 * (hash(team1_name + '3pt') % 10) / 10)))),
            }
            result['team_stats'][team1_name] = team1_stats
        
        if not team2_recent.empty:
            # Team 2 stats from data with different randomization
            team2_stats = {
                'PTS': float(max(85, min(120, team2_recent['PTS'].mean() * (1 - 0.05 * (hash(team2_name) % 10) / 10)))),
                'REB': float(max(30, min(55, team2_recent['REB'].mean() * (1 - 0.05 * (hash(team2_name[::-1]) % 10) / 10)))),
                'AST': float(max(15, min(35, team2_recent['AST'].mean() * (1 + 0.05 * (hash(team2_name + 'ast') % 10) / 10)))),
                'STL': float(max(5, min(12, team2_recent['STL'].mean() * (1 - 0.1 * (hash(team2_name + 'stl') % 10) / 10)))),
                'BLK': float(max(3, min(8, team2_recent['BLK'].mean() * (1 + 0.1 * (hash(team2_name + 'blk') % 10) / 10)))),
                'FG3_PCT': float(max(30, min(45, team2_recent['FG3_PCT'].mean() * 100 * (1 - 0.05 * (hash(team2_name + '3pt') % 10) / 10)))),
            }
            result['team_stats'][team2_name] = team2_stats
            
    except Exception as e:
        print(f"Error processing team stats: {e}")
        # Return fallback data for demo purposes
        result['team_stats'][team1_name] = {
            'PTS': 105.8,
            'REB': 44.3,
            'AST': 24.6,
            'STL': 7.9,
            'BLK': 5.2,
            'FG3_PCT': 36.5,
        }
        result['team_stats'][team2_name] = {
            'PTS': 102.3,
            'REB': 42.1,
            'AST': 22.8,
            'STL': 8.4,
            'BLK': 4.7,
            'FG3_PCT': 34.8,
        }
    
    return jsonify(result)

@app.route('/predict-with-performance-factors', methods=['POST'])
def predict_with_performance_factors():
    try:
        data = request.get_json()
        team1_name = data.get('team1')
        team2_name = data.get('team2')
        inactive_players = data.get('inactive_players', {})  # Map of player_name to boolean
        performance_factor_values = data.get('performance_factors', {})
        
        if not team1_name or not team2_name:
            return jsonify({'error': 'Both team names are required'}), 400
        
        # First get baseline prediction without considering player availability or performance factors
        baseline_prediction = get_prediction_for_teams(team1_name, team2_name)
        
        # Get team abbreviations
        team1_abbr = None
        team2_abbr = None
        nba_teams = teams.get_teams()
        inverse_mapping = {team['full_name'].lower(): team['abbreviation'] for team in nba_teams}
        
        # Try to find team abbreviations
        if team1_name.lower() in inverse_mapping:
            team1_abbr = inverse_mapping[team1_name.lower()]
        else:
            for name, abbr in inverse_mapping.items():
                if team1_name.lower() in name.lower():
                    team1_abbr = abbr
                    break
        
        if team2_name.lower() in inverse_mapping:
            team2_abbr = inverse_mapping[team2_name.lower()]
        else:
            for name, abbr in inverse_mapping.items():
                if team2_name.lower() in name.lower():
                    team2_abbr = abbr
                    break
        
        # 1. Apply player availability adjustments
        player_impacts = {}
        team1_player_impact = 0
        team2_player_impact = 0
        
        try:
            # Get players from CSV data
            player_df = pd.read_csv("ml_models/updated_player_data.csv")
            
            # Process each player and calculate impact
            for index, row in player_df.iterrows():
                player_name = row['PLAYER_NAME']
                team_abbr = row['TEAM_ABBREVIATION']
                
                # We want to calculate impact for all players, even if not in inactive_players dict
                # This ensures impacts are calculated when the page first loads
                # if player_name not in inactive_players:
                #    continue
                # Instead, we'll process all players
                
                # Calculate impact factor based on player stats
                pts = float(row['PTS'])
                reb = float(row['REB'])
                ast = float(row['AST'])
                stl = float(row['STL'])
                blk = float(row['BLK'])
                
                # Print debug info for specific players
                if player_name in ['LaMelo Ball', 'Terry Rozier']:
                    print(f"Debug stats for {player_name}: PTS={pts}, REB={reb}, AST={ast}, STL={stl}, BLK={blk}")
                
                # Weighted impact calculation - keeping divisor consistent at 100
                raw_impact = (0.4 * pts + 0.2 * reb + 0.2 * ast + 0.1 * stl + 0.1 * blk)
                impact_factor = raw_impact / 100.0
                
                # Make sure impact is at least 1% and at most 20%
                impact_factor = min(max(impact_factor, 0.01), 0.20)
                
                # Format to 3 decimal places for consistency
                impact_factor = round(impact_factor, 3)
                
                # Debug output for important players
                if player_name in ['LaMelo Ball', 'Terry Rozier']:
                    print(f"Impact calculation for {player_name}: ({0.4}*{pts} + {0.2}*{reb} + {0.2}*{ast} + {0.1}*{stl} + {0.1}*{blk})/100 = {raw_impact/100.0} = {impact_factor} after clamping")
                
                player_impacts[player_name] = impact_factor
                
                # Check player status - in the request, the inactive_players dictionary 
                # actually tracks if a player is ACTIVE (true) or INACTIVE (false)
                # The key is playerName and the value is a boolean where true = active
                is_active = inactive_players.get(player_name, True)  # Default to active if not specified
                
                # Only add to team impact if player is inactive (is_active is False)
                if not is_active:
                    print(f"Player {player_name} is inactive, adding impact {impact_factor} to team impact")
                    if team_abbr == team1_abbr:
                        team1_player_impact += impact_factor
                    elif team_abbr == team2_abbr:
                        team2_player_impact += impact_factor
                else:
                    print(f"Player {player_name} is active, not adding impact to team")
        except Exception as e:
            print(f"Error calculating player impacts: {e}")
            # Continue with performance factors even if player impacts fail
        
        # 2. Get performance factors data from the team_data CSV
        try:
            # Get team data from CSV
            team1_data = performance_factors.get_team_data_from_csv(team1_abbr)
            team2_data = performance_factors.get_team_data_from_csv(team2_abbr)
            
            # Determine home team
            home_team = 0  # 0 = neutral, 1 = team1 home, 2 = team2 home
            if team1_data['is_home'] and not team2_data['is_home']:
                home_team = 1
            elif team2_data['is_home'] and not team1_data['is_home']:
                home_team = 2
            
            # Set up performance factor values
            perf_factors = {
                'home_court_advantage': performance_factor_values.get('home_court_advantage', 5),
                'rest_days_impact': performance_factor_values.get('rest_days_impact', 5),
                'recent_form_weight': performance_factor_values.get('recent_form_weight', 5),
                'home_team': home_team,
                'team1_rest_days': team1_data['rest_days'],
                'team2_rest_days': team2_data['rest_days'],
                'team1_recent_wins': team1_data['recent_wins'],
                'team1_recent_losses': team1_data['recent_losses'],
                'team2_recent_wins': team2_data['recent_wins'],
                'team2_recent_losses': team2_data['recent_losses']
            }
            
            # Apply player impacts to base probabilities with safeguards
            team1_win_prob = max(0.01, baseline_prediction['team1_win_probability'] * (1 - min(team1_player_impact, 0.9)))
            team2_win_prob = max(0.01, baseline_prediction['team2_win_probability'] * (1 - min(team2_player_impact, 0.9)))
            
            # Debug output
            print(f"After player impact adjustments: team1_win_prob={team1_win_prob}, team2_win_prob={team2_win_prob}")
            print(f"team1_player_impact={team1_player_impact}, team2_player_impact={team2_player_impact}")
            
            # Normalize probabilities after player impacts to ensure they sum to 1.0
            total = team1_win_prob + team2_win_prob
            team1_win_prob = team1_win_prob / total
            team2_win_prob = team2_win_prob / total
            
            # Ensure there are no negative probabilities
            team1_win_prob = max(0.01, min(0.99, team1_win_prob))
            team2_win_prob = max(0.01, min(0.99, team2_win_prob))
            
            # Final normalization
            total = team1_win_prob + team2_win_prob
            team1_win_prob = team1_win_prob / total
            team2_win_prob = team2_win_prob / total
            
            # Apply performance factors
            adjusted_probs = performance_factors.apply_performance_factors(
                team1_win_prob, team2_win_prob, perf_factors
            )
            
            # Final adjusted probabilities
            final_team1_win_prob = adjusted_probs[0]
            final_team2_win_prob = adjusted_probs[1]
            
            # Determine winner
            winner = team1_name if final_team1_win_prob > final_team2_win_prob else team2_name
            
            # Generate explanation data based on team stats and factors
            # Compare team stats to determine strengths and weaknesses
            team1_strengths = []
            team2_strengths = []
            team1_weaknesses = []
            team2_weaknesses = []
            
            # Use fallback data if available
            if team1_name in fallback_team_data and team2_name in fallback_team_data:
                team1_fb = fallback_team_data[team1_name]
                team2_fb = fallback_team_data[team2_name]
                
                # Offensive comparison
                if team1_fb['PTS'] > team2_fb['PTS']:
                    team1_strengths.append('Superior offensive output')
                    team2_weaknesses.append('Lower scoring average')
                else:
                    team2_strengths.append('Superior offensive output')
                    team1_weaknesses.append('Lower scoring average')
                
                # Rebounding comparison
                if team1_fb['REB'] > team2_fb['REB']:
                    team1_strengths.append('Better rebounding')
                    team2_weaknesses.append('Weaker rebounding')
                else:
                    team2_strengths.append('Better rebounding')
                    team1_weaknesses.append('Weaker rebounding')
                    
                # Assists comparison
                if team1_fb['AST'] > team2_fb['AST']:
                    team1_strengths.append('Superior ball movement')
                    team2_weaknesses.append('Less team assists')
                else:
                    team2_strengths.append('Superior ball movement')
                    team1_weaknesses.append('Less team assists')
                    
                # 3pt shooting 
                if team1_fb['FG3_PCT'] > team2_fb['FG3_PCT']:
                    team1_strengths.append('Better 3-point shooting')
                    team2_weaknesses.append('Lower 3-point percentage')
                else:
                    team2_strengths.append('Better 3-point shooting')
                    team1_weaknesses.append('Lower 3-point percentage')
                    
                # Defense metrics (turnovers forced)
                if team1_fb['STL'] > team2_fb['STL']:
                    team1_strengths.append('More active defense')
                    team2_weaknesses.append('Susceptible to turnovers')
                else:
                    team2_strengths.append('More active defense')
                    team1_weaknesses.append('Susceptible to turnovers')
                    
                # Interior defense
                if team1_fb['BLK'] > team2_fb['BLK']:
                    team1_strengths.append('Stronger interior defense')
                    team2_weaknesses.append('Weaker rim protection')
                else:
                    team2_strengths.append('Stronger interior defense')
                    team1_weaknesses.append('Weaker rim protection')
            else:
                # Generic strengths/weaknesses if team stats unavailable
                team1_strengths = ['Experience in close games', 'Offensive efficiency', 'Ball movement']
                team2_strengths = ['Strong defense', 'Rebounding advantage', 'Perimeter shooting']
                team1_weaknesses = ['Inconsistent defense', 'Poor rebounding', 'Turnovers']
                team2_weaknesses = ['Inconsistent scoring', 'Poor free throw shooting', 'Lack of depth']
            
            # Add context from performance factors
            if home_team == 1:
                team1_strengths.append('Home court advantage')
            elif home_team == 2:
                team2_strengths.append('Home court advantage')
                
            if team1_data['rest_days'] > team2_data['rest_days']:
                team1_strengths.append(f"{team1_data['rest_days']} days rest advantage")
                team2_weaknesses.append('Less rest between games')
            elif team2_data['rest_days'] > team1_data['rest_days']:
                team2_strengths.append(f"{team2_data['rest_days']} days rest advantage")
                team1_weaknesses.append('Less rest between games')
                
            team1_recent_form = team1_data['recent_wins'] / (team1_data['recent_wins'] + team1_data['recent_losses'])
            team2_recent_form = team2_data['recent_wins'] / (team2_data['recent_wins'] + team2_data['recent_losses'])
            
            if team1_recent_form > team2_recent_form:
                team1_strengths.append('Better recent form')
                team2_weaknesses.append('Poor recent performance')
            elif team2_recent_form > team1_recent_form:
                team2_strengths.append('Better recent form')
                team1_weaknesses.append('Poor recent performance')
                
            # Add player impact context
            inactive_stars = []
            for player_name, impact in player_impacts.items():
                if impact > 0.10 and player_name in inactive_players and inactive_players[player_name]:
                    if player_name in team1_name.lower():
                        team2_strengths.append(f"{player_name} unavailable for opponent")
                        inactive_stars.append(f"{player_name} ({team1_name})")
                    else:
                        team1_strengths.append(f"{player_name} unavailable for opponent")
                        inactive_stars.append(f"{player_name} ({team2_name})")
            
            # Make prediction explanation
            winner_name = team1_name if final_team1_win_prob > final_team2_win_prob else team2_name
            loser_name = team2_name if final_team1_win_prob > final_team2_win_prob else team1_name
            winner_strengths = team1_strengths if final_team1_win_prob > final_team2_win_prob else team2_strengths
            loser_weaknesses = team2_weaknesses if final_team1_win_prob > final_team2_win_prob else team1_weaknesses
            
            # Generate key factors for explanation
            key_factors = []
            
            # Add 2-3 winner strengths
            for strength in winner_strengths[:2]:
                key_factors.append(strength)
                
            # Add 1-2 loser weaknesses
            for weakness in loser_weaknesses[:1]:
                key_factors.append(weakness)
                
            # Add star player impact if relevant
            if inactive_stars:
                key_factors.append(f"Missing: {', '.join(inactive_stars)}")
                
            # Load player team data from CSV
            player_teams = {}
            try:
                player_csv_path = os.path.join('data', 'player_data.csv')
                if os.path.exists(player_csv_path):
                    player_df = pd.read_csv(player_csv_path)
                    # Create mapping of player name to team
                    for _, row in player_df.iterrows():
                        if 'PLAYER_NAME' in row and 'TEAM_NAME' in row:
                            player_teams[row['PLAYER_NAME']] = row['TEAM_NAME']
            except Exception as e:
                print(f"Error loading player team data: {e}")
            
            # Add player impacts to analysis
            player_impacts = {}
            
            # Create team_players for key_factors
            team_players_map = {team1_name: [], team2_name: []}
            
            # Extract team players from the player data we already loaded
            for player in team1_players:
                team_players_map[team1_name].append(player['name'])
                
            for player in team2_players:
                team_players_map[team2_name].append(player['name'])
            
            # Add team_players to key_factors
            key_factors['team_players'] = team_players_map
            
            # Select top impact players from both teams
            impact_players = []
            # Add top team1 players
            for player in team1_players[:3]:  # Take top 3 players from team1
                impact_players.append({
                    'name': player['name'],
                    'team': team1_name,
                    'impact': player['impact_factor']
                })
                
            # Add top team2 players
            for player in team2_players[:3]:  # Take top 3 players from team2
                impact_players.append({
                    'name': player['name'],
                    'team': team2_name,
                    'impact': player['impact_factor']
                })
                
            # If we don't have enough players from the teams, add some well-known players
            # Player impacts will be added later in the code if we have enough
                for player in additional_players:
                    if len(impact_players) >= 6:  # Limit to 6 total players
                        break
                    impact_players.append(player)
            
            # ... (rest of the code remains the same)
            # Convert to format expected by frontend
            for player in impact_players:
                player_name = player['name']
                player_team = player['team']
                player_impacts[player_name] = player['impact']
                
                # Add team information for each player
                player_impacts[f"{player_name}_team"] = player_team
            
            # Return results with explanation data
            return jsonify({
                'winner': winner,
                'team1_win_prob': final_team1_win_prob,
                'team2_win_prob': final_team2_win_prob,
                'player_impacts': player_impacts,
                'performance_factors': {
                    'home_team': home_team,
                    'team1_rest_days': team1_data['rest_days'],
                    'team2_rest_days': team2_data['rest_days'],
                    'team1_recent_form': team1_recent_form,
                    'team2_recent_form': team2_recent_form
                },
                'explanation': {
                    'key_factors': key_factors,
                    'team1_strengths': team1_strengths,
                    'team2_strengths': team2_strengths,
                    'team1_weaknesses': team1_weaknesses,
                    'team2_weaknesses': team2_weaknesses
                }
            })
            
        except Exception as e:
            print(f"Error applying performance factors: {e}")
            # Fall back to baseline prediction if performance factors fail
            return jsonify({
                'winner': team1_name if baseline_prediction['team1_win_probability'] > baseline_prediction['team2_win_probability'] else team2_name,
                'team1_win_prob': baseline_prediction['team1_win_probability'],
                'team2_win_prob': baseline_prediction['team2_win_probability'],
                'error': f"Performance factors calculation error: {str(e)}"
            })
    
    except Exception as e:
        print(f"Error in predict_with_performance_factors: {e}")
        return jsonify({
            'error': str(e),
            'winner': 'Unknown',
            'team1_win_prob': 0.5,
            'team2_win_prob': 0.5
        }), 500

@app.route('/predict-with-player-availability', methods=['POST'])
def predict_with_player_availability():
    try:
        data = request.get_json()
        team1_name = data.get('team1')
        team2_name = data.get('team2')
        inactive_players = data.get('inactive_players', {})  # Map of player_name to boolean
        
        if not team1_name or not team2_name:
            return jsonify({'error': 'Both team names are required'}), 400
        
        # First get baseline prediction without considering player availability
        baseline_prediction = get_prediction_for_teams(team1_name, team2_name)
        
        # TODO: Implement player availability impact calculation using the model
        # For now, we'll calculate a simple impact based on player stats
        
        # Get players from CSV data
        try:
            import pandas as pd
            player_df = pd.read_csv("ml_models/updated_player_data.csv")
            
            # Calculate impact factors for inactive players
            player_impacts = {}
            team1_impact = 0
            team2_impact = 0
            
            # Team abbreviations
            team1_abbr = None
            team2_abbr = None
            
            # Use the NBATeams get_team_abbreviation function to get team abbreviations
            nba_teams = teams.get_teams()
            team_abbr_mapping = {team['abbreviation']: team['full_name'] for team in nba_teams}
            inverse_mapping = {team['full_name'].lower(): team['abbreviation'] for team in nba_teams}
            
            # Try to find team abbreviations
            if team1_name.lower() in inverse_mapping:
                team1_abbr = inverse_mapping[team1_name.lower()]
            else:
                print(f"Could not find abbreviation for team: {team1_name}")
                for name, abbr in inverse_mapping.items():
                    if team1_name.lower() in name.lower():
                        team1_abbr = abbr
                        break
            
            if team2_name.lower() in inverse_mapping:
                team2_abbr = inverse_mapping[team2_name.lower()]
            else:
                print(f"Could not find abbreviation for team: {team2_name}")
                for name, abbr in inverse_mapping.items():
                    if team2_name.lower() in name.lower():
                        team2_abbr = abbr
                        break
                        
            print(f"Team abbreviations: {team1_name} -> {team1_abbr}, {team2_name} -> {team2_abbr}")
            
            # Calculate impacts for all players in the CSV
            # First, get a list of players on each team
            team1_players = player_df[player_df['TEAM_ABBREVIATION'] == team1_abbr]['PLAYER_NAME'].tolist()
            team2_players = player_df[player_df['TEAM_ABBREVIATION'] == team2_abbr]['PLAYER_NAME'].tolist()
            
            # Calculate impacts for all players on both teams
            all_players_to_check = team1_players + team2_players
            for player_name in all_players_to_check:
                    
                # Find player in dataframe
                player_rows = player_df[player_df['PLAYER_NAME'] == player_name]
                if player_rows.empty:
                    continue
                    
                # Use the most recent entry
                player_row = player_rows.iloc[0]
                team_abbr = player_row['TEAM_ABBREVIATION']
                
                # Calculate player impact factor based on stats
                # Use a weighted calculation based on the player's stats
                pts_weight = player_row['PTS'] * 1.0  # Points are important
                reb_weight = player_row['REB'] * 0.7  # Rebounds somewhat important
                ast_weight = player_row['AST'] * 0.8  # Assists important
                stl_weight = player_row['STL'] * 0.5  # Steals somewhat important
                blk_weight = player_row['BLK'] * 0.5  # Blocks somewhat important
                
                # Calculate a composite impact score
                impact_score = pts_weight + reb_weight + ast_weight + stl_weight + blk_weight
                
                # Scale the impact factor based on the player's impact score
                if impact_score > 30:  # Star player
                    impact_factor = 0.12 + (impact_score - 30) * 0.002  # Up to ~18% for superstars
                    impact_factor = min(0.18, impact_factor)  # Cap at 18%
                elif impact_score > 20:  # Good player
                    impact_factor = 0.08 + (impact_score - 20) * 0.004  # 8-12%
                elif impact_score > 10:  # Role player
                    impact_factor = 0.04 + (impact_score - 10) * 0.004  # 4-8%
                else:  # Bench player
                    impact_factor = max(0.01, impact_score * 0.004)  # 1-4%
                
                player_impacts[player_name] = impact_factor
                
                # Only add to team impact if player is inactive
                is_inactive = inactive_players.get(player_name, False)
                if is_inactive:
                    if team_abbr == team1_abbr:
                        team1_impact += impact_factor
                        print(f"Player {player_name} is inactive, adding impact {impact_factor} to team1")
                    elif team_abbr == team2_abbr:
                        team2_impact += impact_factor
                        print(f"Player {player_name} is inactive, adding impact {impact_factor} to team2")
            
            # Adjust win probabilities based on impacts
            team1_win_prob = baseline_prediction['team1_win_probability']
            team2_win_prob = baseline_prediction['team2_win_probability']
            
            # Reduce team's win probability based on inactive players
            team1_win_prob = max(0.1, team1_win_prob - team1_impact)
            team2_win_prob = max(0.1, team2_win_prob - team2_impact)
            
            # Normalize probabilities to sum to 1
            total_prob = team1_win_prob + team2_win_prob
            team1_win_prob = team1_win_prob / total_prob
            team2_win_prob = team2_win_prob / total_prob
            
            # Return prediction with player impacts
            return jsonify({
                'winner': team1_name if team1_win_prob > team2_win_prob else team2_name,
                'team1_win_prob': team1_win_prob,
                'team2_win_prob': team2_win_prob,
                'player_impacts': player_impacts
            })
            
        except Exception as e:
            print(f"Error calculating player impacts: {e}")
            # Fall back to baseline prediction
            return jsonify({
                'winner': team1_name if baseline_prediction['team1_win_probability'] > baseline_prediction['team2_win_probability'] else team2_name,
                'team1_win_prob': baseline_prediction['team1_win_probability'],
                'team2_win_prob': baseline_prediction['team2_win_probability'],
                'player_impacts': {}
            })
            
    except Exception as e:
        print(f"Error in player availability prediction: {e}")
        return jsonify({
            'error': str(e),
            'winner': 'Unknown',
            'team1_win_prob': 0.5,
            'team2_win_prob': 0.5,
            'player_impacts': {}
        }), 500
    except Exception as e:
        print(f"Error predicting teams: {e}")
        return jsonify({
            'error': str(e),
            'winner': 'Unknown',
            'team1_win_prob': 0.5,
            'team2_win_prob': 0.5
        }), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/games', methods=['GET'])
def get_games():
    try:
        # Get filter parameter (optional)
        category = request.args.get('category', None)  # 'today', 'upcoming', 'live', or None for all
        
        # In a real implementation, we would fetch from NBA API
        # For now, generate sample game data
        
        # Get current date for proper categorization
        current_date = datetime.datetime.now()
        today = datetime.datetime(current_date.year, current_date.month, current_date.day)
        today_str = current_date.strftime('%Y-%m-%dT%H:%M:%SZ')
        
        # Create dates for May 6 and May 8, 2025
        may_6_date = datetime.datetime(2025, 5, 6, current_date.hour, current_date.minute)
        may_6_str = may_6_date.strftime('%Y-%m-%dT%H:%M:%SZ')
        may_8_date = datetime.datetime(2025, 5, 8, current_date.hour, current_date.minute)
        may_8_str = may_8_date.strftime('%Y-%m-%dT%H:%M:%SZ')
        
        # All games data
        all_games = [
            # Live game (today with LIVE status)
            {
                'id': '0022400001',
                'home_team': {
                    'id': '1610612747',
                    'name': 'Thunders',
                    'abbreviation': 'OKC',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612747/global/L/logo.svg',
                    'score': 78
                },
                'away_team': {
                    'id': '1610612742',
                    'name': 'Mavericks',
                    'abbreviation': 'DAL',
                    'logo_url': 'https://cdn.nba.com/logos/nba/1610612742/global/L/logo.svg',
                    'score': 65
                },
                'status': 'LIVE',
                'game_clock': '3:24',
                'period': 3,
                'start_time': today_str,
                'prediction': get_prediction_for_teams('Thunders', 'Mavericks')
            },
            # Today game (scheduled for today but not live)
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
                'start_time': today_str,
                'prediction': get_prediction_for_teams('Warriors', 'Nets')
            },
            # Upcoming game 1 (May 6)
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
                'start_time': may_6_str,
                'prediction': get_prediction_for_teams('Rockets', 'Spurs')
            },
            # Upcoming game 2 (May 8)
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
                'start_time': may_8_str,
                'prediction': get_prediction_for_teams('Heat', 'Knicks')
            }
        ]
        
        # Properly categorize games based on date and status
        today_games = []
        upcoming_games = []
        live_games = []
        
        for game in all_games:
            # Parse the game start time
            game_date = datetime.datetime.strptime(game['start_time'], '%Y-%m-%dT%H:%M:%SZ')
            game_day = datetime.datetime(game_date.year, game_date.month, game_date.day)
            
            # Apply the correct categorization logic
            if game_day.date() == today.date():
                # Game is scheduled for today
                if game['status'] == 'LIVE':
                    # Game is live
                    live_games.append(game)
                # All games scheduled for today go in today_games
                today_games.append(game)
            elif game_day > today:
                # Game is in the future
                upcoming_games.append(game)
        
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
        print(f"Error in get_games: {e}")
        import traceback
        traceback.print_exc()
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
        # Get game details first
        game_details = game_model.get_game(game_id)
        if not game_details:
            return jsonify({'error': 'Game not found'}), 404
            
        team1_name = game_details.get('team1_name')
        team2_name = game_details.get('team2_name')
        
        # Load team stats from CSV
        team1_stats = {}
        team2_stats = {}
        
        try:
            # Use the CSV data for team stats
            csv_path = os.path.join('data', 'team_data.csv')
            if os.path.exists(csv_path):
                df = pd.read_csv(csv_path)
                
                # Filter for most recent games for each team
                team1_data = df[df['TEAM_NAME'] == team1_name].sort_values('GAME_DATE', ascending=False).iloc[0] if len(df[df['TEAM_NAME'] == team1_name]) > 0 else None
                team2_data = df[df['TEAM_NAME'] == team2_name].sort_values('GAME_DATE', ascending=False).iloc[0] if len(df[df['TEAM_NAME'] == team2_name]) > 0 else None
                
                # Process team1 stats
                if team1_data is not None:
                    team1_stats = {
                        'PPG': float(team1_data['PTS']),
                        '3PT': float(team1_data['FG3_PCT']) * 100,  # Convert to percentage
                        'REB': float(team1_data['REB']),
                        'AST': float(team1_data['AST']),
                        'STL': float(team1_data['STL']),
                        'BLK': float(team1_data['BLK']),
                        'W': int(team1_data['W']),
                        'L': int(team1_data['L']),
                        'W_PCT': float(team1_data['W_PCT']),
                        'LAST_5': [], # Will be filled below
                        'HOME_RECORD': '0-0',  # Placeholder
                        'AWAY_RECORD': '0-0',  # Placeholder
                    }
                    
                # Process team2 stats
                if team2_data is not None:
                    team2_stats = {
                        'PPG': float(team2_data['PTS']),
                        '3PT': float(team2_data['FG3_PCT']) * 100,  # Convert to percentage
                        'REB': float(team2_data['REB']),
                        'AST': float(team2_data['AST']),
                        'STL': float(team2_data['STL']),
                        'BLK': float(team2_data['BLK']),
                        'W': int(team2_data['W']),
                        'L': int(team2_data['L']),
                        'W_PCT': float(team2_data['W_PCT']),
                        'LAST_5': [], # Will be filled below
                        'HOME_RECORD': '0-0',  # Placeholder
                        'AWAY_RECORD': '0-0',  # Placeholder
                    }
                
                # Try to get last 5 games for each team
                try:
                    team1_last_5 = df[df['TEAM_NAME'] == team1_name].sort_values('GAME_DATE', ascending=False).head(5)
                    team2_last_5 = df[df['TEAM_NAME'] == team2_name].sort_values('GAME_DATE', ascending=False).head(5)
                    
                    # Process last 5 games for team1
                    for _, game in team1_last_5.iterrows():
                        if 'OPP_TEAM' in game and 'WL' in game and 'PTS' in game and 'OPP_PTS' in game:
                            team1_stats['LAST_5'].append({
                                'opponent': game['OPP_TEAM'],
                                'result': 'W' if game.get('WL') == 'W' else 'L',
                                'score': f"{int(game['PTS'])}-{int(game['OPP_PTS'])}",
                                'date': game['GAME_DATE']
                            })
                    
                    # Process last 5 games for team2
                    for _, game in team2_last_5.iterrows():
                        if 'OPP_TEAM' in game and 'WL' in game and 'PTS' in game and 'OPP_PTS' in game:
                            team2_stats['LAST_5'].append({
                                'opponent': game['OPP_TEAM'],
                                'result': 'W' if game.get('WL') == 'W' else 'L',
                                'score': f"{int(game['PTS'])}-{int(game['OPP_PTS'])}",
                                'date': game['GAME_DATE']
                            })
                except Exception as e:
                    print(f"Error processing last 5 games: {e}")
                
                # Try to calculate home/away records
                try:
                    if 'HOME_AWAY' in df.columns and 'WL' in df.columns:
                        team1_home_games = df[(df['TEAM_NAME'] == team1_name) & (df['HOME_AWAY'] == 'HOME')]
                        team1_home_wins = len(team1_home_games[team1_home_games['WL'] == 'W'])
                        team1_home_losses = len(team1_home_games[team1_home_games['WL'] == 'L'])
                        team1_stats['HOME_RECORD'] = f"{team1_home_wins}-{team1_home_losses}"
                        
                        team1_away_games = df[(df['TEAM_NAME'] == team1_name) & (df['HOME_AWAY'] == 'AWAY')]
                        team1_away_wins = len(team1_away_games[team1_away_games['WL'] == 'W'])
                        team1_away_losses = len(team1_away_games[team1_away_games['WL'] == 'L'])
                        team1_stats['AWAY_RECORD'] = f"{team1_away_wins}-{team1_away_losses}"
                        
                        team2_home_games = df[(df['TEAM_NAME'] == team2_name) & (df['HOME_AWAY'] == 'HOME')]
                        team2_home_wins = len(team2_home_games[team2_home_games['WL'] == 'W'])
                        team2_home_losses = len(team2_home_games[team2_home_games['WL'] == 'L'])
                        team2_stats['HOME_RECORD'] = f"{team2_home_wins}-{team2_home_losses}"
                        
                        team2_away_games = df[(df['TEAM_NAME'] == team2_name) & (df['HOME_AWAY'] == 'AWAY')]
                        team2_away_wins = len(team2_away_games[team2_away_games['WL'] == 'W'])
                        team2_away_losses = len(team2_away_games[team2_away_games['WL'] == 'L'])
                        team2_stats['AWAY_RECORD'] = f"{team2_away_wins}-{team2_away_losses}"
                except Exception as e:
                    print(f"Error calculating home/away records: {e}")
        except Exception as e:
            print(f"Error processing CSV data: {e}")
            
        # Get player stats from CSV
        team1_players = []
        team2_players = []
        
        try:
            # Use player CSV data
            player_csv_path = os.path.join('data', 'updated_player_data.csv')
            if os.path.exists(player_csv_path):
                player_df = pd.read_csv(player_csv_path)
                
                # Get team abbreviations
                team1_abbr = None
                team2_abbr = None
                
                # Some CSV files might use TEAM_NAME directly, others might need to be mapped
                if 'TEAM_NAME' in player_df.columns:
                    team1_rows = player_df[player_df['TEAM_NAME'] == team1_name]
                    team2_rows = player_df[player_df['TEAM_NAME'] == team2_name]
                    if len(team1_rows) > 0:
                        team1_abbr = team1_rows.iloc[0]['TEAM_ABBREVIATION']
                    if len(team2_rows) > 0:
                        team2_abbr = team2_rows.iloc[0]['TEAM_ABBREVIATION']
                else:
                    # Try to map from NBA API teams
                    try:
                        nba_teams = teams.get_teams()
                        for team in nba_teams:
                            if team['full_name'] == team1_name:
                                team1_abbr = team['abbreviation']
                            if team['full_name'] == team2_name:
                                team2_abbr = team['abbreviation']
                    except Exception as e:
                        print(f"Error mapping team names to abbreviations: {e}")
                
                # Process team1 players if we have the abbreviation
                if team1_abbr:
                    team1_players_df = player_df[player_df['TEAM_ABBREVIATION'] == team1_abbr].sort_values('PTS', ascending=False)
                    for _, player in team1_players_df.iterrows():
                        try:
                            # Calculate player impact factor using the same formula as in predict_with_performance_factors
                            pts = float(player['PTS'])
                            reb = float(player['REB'])
                            ast = float(player['AST'])
                            stl = float(player['STL'])
                            blk = float(player['BLK'])
                            
                            raw_impact = (0.4 * pts + 0.2 * reb + 0.2 * ast + 0.1 * stl + 0.1 * blk)
                            impact_factor = raw_impact / 100.0
                            impact_factor = min(max(impact_factor, 0.01), 0.20)
                            impact_factor = round(impact_factor, 3)
                            
                            team1_players.append({
                                'name': player['PLAYER_NAME'],
                                'pts': pts,
                                'reb': reb,
                                'ast': ast,
                                'stl': stl,
                                'blk': blk,
                                'impact_factor': impact_factor
                            })
                        except Exception as e:
                            print(f"Error processing player {player.get('PLAYER_NAME', 'unknown')}: {e}")
                
                # Process team2 players if we have the abbreviation
                if team2_abbr:
                    team2_players_df = player_df[player_df['TEAM_ABBREVIATION'] == team2_abbr].sort_values('PTS', ascending=False)
                    for _, player in team2_players_df.iterrows():
                        try:
                            pts = float(player['PTS'])
                            reb = float(player['REB'])
                            ast = float(player['AST'])
                            stl = float(player['STL'])
                            blk = float(player['BLK'])
                            
                            raw_impact = (0.4 * pts + 0.2 * reb + 0.2 * ast + 0.1 * stl + 0.1 * blk)
                            impact_factor = raw_impact / 100.0
                            impact_factor = min(max(impact_factor, 0.01), 0.20)
                            impact_factor = round(impact_factor, 3)
                            
                            team2_players.append({
                                'name': player['PLAYER_NAME'],
                                'pts': pts,
                                'reb': reb,
                                'ast': ast,
                                'stl': stl,
                                'blk': blk,
                                'impact_factor': impact_factor
                            })
                        except Exception as e:
                            print(f"Error processing player {player.get('PLAYER_NAME', 'unknown')}: {e}")
        except Exception as e:
            print(f"Error processing player data: {e}")
        
        # Calculate key factors (strengths/weaknesses) based on team stats
        key_factors = {
            'team1_strengths': [],
            'team1_weaknesses': [],
            'team2_strengths': [],
            'team2_weaknesses': [],
            'team_players': {
                team1_name: [p['name'] for p in team1_players],
                team2_name: [p['name'] for p in team2_players]
            }
        }
        
        # Compare offensive output
        if team1_stats.get('PPG', 0) > team2_stats.get('PPG', 0):
            key_factors['team1_strengths'].append('Superior offensive output')
            key_factors['team2_weaknesses'].append('Lower scoring average')
        else:
            key_factors['team2_strengths'].append('Superior offensive output')
            key_factors['team1_weaknesses'].append('Lower scoring average')
        
        # Compare rebounding
        if team1_stats.get('REB', 0) > team2_stats.get('REB', 0):
            key_factors['team1_strengths'].append('Better rebounding')
            key_factors['team2_weaknesses'].append('Weaker rebounding')
        else:
            key_factors['team2_strengths'].append('Better rebounding')
            key_factors['team1_weaknesses'].append('Weaker rebounding')
            
        # Compare assists
        if team1_stats.get('AST', 0) > team2_stats.get('AST', 0):
            key_factors['team1_strengths'].append('Superior ball movement')
            key_factors['team2_weaknesses'].append('Less team assists')
        else:
            key_factors['team2_strengths'].append('Superior ball movement')
            key_factors['team1_weaknesses'].append('Less team assists')
            
        # Compare 3pt shooting
        if team1_stats.get('3PT', 0) > team2_stats.get('3PT', 0):
            key_factors['team1_strengths'].append('Better 3-point shooting')
            key_factors['team2_weaknesses'].append('Lower 3-point percentage')
        else:
            key_factors['team2_strengths'].append('Better 3-point shooting')
            key_factors['team1_weaknesses'].append('Lower 3-point percentage')
            
        # Compare defense metrics
        if team1_stats.get('STL', 0) > team2_stats.get('STL', 0):
            key_factors['team1_strengths'].append('More active defense')
            key_factors['team2_weaknesses'].append('Susceptible to turnovers')
        else:
            key_factors['team2_strengths'].append('More active defense')
            key_factors['team1_weaknesses'].append('Susceptible to turnovers')
            
        # Compare interior defense
        if team1_stats.get('BLK', 0) > team2_stats.get('BLK', 0):
            key_factors['team1_strengths'].append('Stronger interior defense')
            key_factors['team2_weaknesses'].append('Weaker rim protection')
        else:
            key_factors['team2_strengths'].append('Stronger interior defense')
            key_factors['team1_weaknesses'].append('Weaker rim protection')
        
        # Add home court advantage factor
        if game_details.get('location', '').startswith(team1_name):
            key_factors['team1_strengths'].append('Home court advantage')
        elif game_details.get('location', '').startswith(team2_name):
            key_factors['team2_strengths'].append('Home court advantage')
        
        # Calculate win probabilities
        team1_win_prob = game_details.get('team1_win_probability', 0.5)
        team2_win_prob = game_details.get('team2_win_probability', 0.5)
        
        # Compile all data
        analysis = {
            'game_id': game_id,
            'team1_name': team1_name,
            'team2_name': team2_name,
            'team1_stats': team1_stats,
            'team2_stats': team2_stats,
            'team1_players': team1_players,
            'team2_players': team2_players,
            'key_factors': key_factors,
            'team1_win_probability': team1_win_prob,
            'team2_win_probability': team2_win_prob,
            'game_details': game_details
        }
        
        return jsonify(analysis)
    except Exception as e:
        print(f"Error in get_game_analysis: {e}")
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

# Helper function to get team ID from team name
def get_team_id(team_name):
    # Get all teams
    nba_teams = teams.get_teams()
    
    # Try to find the team by name
    team = next((team for team in nba_teams if team['full_name'].lower() == team_name.lower() 
                 or team['nickname'].lower() == team_name.lower()), None)
    
    if team:
        return team['id']
    else:
        # Handle special cases or abbreviations
        if team_name.lower() == 'thunders' or team_name.lower() == 'thunder':
            return 1610612760  # OKC Thunder
        elif team_name.lower() == 'warriors':
            return 1610612744  # Golden State Warriors
        elif team_name.lower() == 'celtics':
            return 1610612738  # Boston Celtics
        elif team_name.lower() == 'nets':
            return 1610612751  # Brooklyn Nets
        else:
            print(f"Could not find team ID for {team_name}")
            return None

# Helper function to get team stats from NBA API with fallback to CSV data
def get_team_stats_from_api(team_name):
    # Check if we already have the stats cached
    if team_name in team_stats_cache:
        print(f"Using cached stats for {team_name}")
        return team_stats_cache[team_name]
    
    # For the Home Page loading, prioritize using fallback data first to avoid API delays
    if team_name in fallback_team_data:
        print(f"Using fallback data for {team_name} from CSV (fast path)")
        team_stats_cache[team_name] = fallback_team_data[team_name]  # Cache it
        return fallback_team_data[team_name]
    
    # Get team ID
    team_id = get_team_id(team_name)
    if not team_id:
        print(f"Error: Could not get team ID for {team_name}")
        return None
    
    try:
        # Get team stats from NBA API with a shorter timeout
        print(f"Fetching stats from NBA API for {team_name} (ID: {team_id})")
        
        # Use a shorter timeout to avoid long loading times
        timeout_seconds = 10  # Reduced from 120 to 10 seconds
        
        # Get general team stats
        team_stats = teamdashboardbygeneralsplits.TeamDashboardByGeneralSplits(
            team_id=team_id,
            per_mode_detailed='PerGame',
            season='2024-25',  # Use current season
            season_type_all_star='Regular Season',
            timeout=timeout_seconds
        )
        
        # Convert to pandas DataFrame
        df = team_stats.get_data_frames()[0]
        
        # Skip league stats to improve performance
        team_abbr = team_name[:3].upper()
        
        # Extract relevant stats and format them for our model
        stats = {
            'W': int(df['W'][0]),
            'L': int(df['L'][0]),
            'W_PCT': float(df['W_PCT'][0]),
            'MIN': float(df['MIN'][0]),
            'FGM': float(df['FGM'][0]),
            'FGA': float(df['FGA'][0]),
            'FG_PCT': float(df['FG_PCT'][0]),
            'FG3M': float(df['FG3M'][0]),
            'FG3A': float(df['FG3A'][0]),
            'FG3_PCT': float(df['FG3_PCT'][0]),
            'FTM': float(df['FTM'][0]),
            'FTA': float(df['FTA'][0]),
            'FT_PCT': float(df['FT_PCT'][0]),
            'OREB': float(df['OREB'][0]),
            'DREB': float(df['DREB'][0]),
            'REB': float(df['REB'][0]),
            'AST': float(df['AST'][0]),
            'STL': float(df['STL'][0]),
            'BLK': float(df['BLK'][0]),
            'TOV': float(df['TOV'][0]),
            'PF': float(df['PF'][0]),
            'PTS': float(df['PTS'][0]),
            'TEAM_ABBR': team_abbr
        }
        
        # Cache the stats
        team_stats_cache[team_name] = stats
        
        print(f"Successfully fetched stats for {team_name}")
        return stats
        
    except Exception as e:
        print(f"Error fetching stats for {team_name} from NBA API: {e}")
        
        # Try to use fallback data from CSV
        if team_name in fallback_team_data:
            print(f"Using fallback data for {team_name} from CSV (after API failure)")
            team_stats_cache[team_name] = fallback_team_data[team_name]  # Cache it
            return fallback_team_data[team_name]
            
        print(f"No fallback data available for {team_name}")
        return None

# Helper function to get predictions for teams by name
def get_prediction_for_teams(home_team_name, away_team_name):
    print(f"Getting prediction for {home_team_name} vs {away_team_name}")
    
    # Get team stats from NBA API with fallback to CSV data
    home_stats = get_team_stats_from_api(home_team_name)
    away_stats = get_team_stats_from_api(away_team_name)
    
    # If we couldn't get stats from either API or CSV, use reasonable defaults
    if not home_stats:
        print(f"Warning: No stats available for {home_team_name}, using default stats")
        home_stats = {
            'W': 25, 'L': 20, 'W_PCT': 0.55, 'MIN': 240, 'FGM': 40, 'FGA': 88, 'FG_PCT': 0.45,
            'FG3M': 12, 'FG3A': 34, 'FG3_PCT': 0.35, 'FTM': 19, 'FTA': 25, 'FT_PCT': 0.76,
            'OREB': 9, 'DREB': 33, 'REB': 42, 'AST': 24, 'STL': 7, 'BLK': 5, 'TOV': 14, 'PF': 19,
            'PTS': 110, 'TEAM_ABBR': home_team_name[:3].upper()
        }
    
    if not away_stats:
        print(f"Warning: No stats available for {away_team_name}, using default stats")
        away_stats = {
            'W': 25, 'L': 20, 'W_PCT': 0.55, 'MIN': 240, 'FGM': 40, 'FGA': 88, 'FG_PCT': 0.45,
            'FG3M': 12, 'FG3A': 34, 'FG3_PCT': 0.35, 'FTM': 19, 'FTA': 25, 'FT_PCT': 0.76,
            'OREB': 9, 'DREB': 33, 'REB': 42, 'AST': 24, 'STL': 7, 'BLK': 5, 'TOV': 14, 'PF': 19,
            'PTS': 110, 'TEAM_ABBR': away_team_name[:3].upper()
        }
    
    # Get prediction
    try:
        if ml_prediction_model is None:
            raise Exception("ML prediction model not loaded")
            
        # Print detailed stats being passed to the model
        print(f"\nPassing the following stats to the prediction model:")
        print(f"Home team ({home_team_name}) stats: W-L: {home_stats['W']}-{home_stats['L']}, W_PCT: {home_stats['W_PCT']}, PTS: {home_stats['PTS']}")
        print(f"Away team ({away_team_name}) stats: W-L: {away_stats['W']}-{away_stats['L']}, W_PCT: {away_stats['W_PCT']}, PTS: {away_stats['PTS']}")
        
        # Get prediction
        results = ml_prediction_model.predict(home_stats, away_stats)
        print(f"Prediction for {home_team_name} vs {away_team_name}: {results}")
        print(f"Team1 ({home_team_name}) win probability: {float(results['team1_win_prob']):.2f}")
        print(f"Team2 ({away_team_name}) win probability: {float(results['team2_win_prob']):.2f}")
        
        return {
            'team1_win_probability': float(results['team1_win_prob']),
            'team2_win_probability': float(results['team2_win_prob'])
        }
    except Exception as e:
        print(f"Error predicting winner: {e}")
        # Fallback to random probabilities that sum to 1
        home_prob = round(random.uniform(0.4, 0.6), 2)
        return {
            'team1_win_probability': home_prob,
            'team2_win_probability': round(1 - home_prob, 2)
        }

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
