import pandas as pd
from datetime import datetime

def apply_performance_factors(team1_win_prob, team2_win_prob, performance_factors):
    """
    Apply performance factors to adjust win probabilities
    
    Args:
        team1_win_prob: Base win probability for team 1
        team2_win_prob: Base win probability for team 2
        performance_factors: Dict containing the performance factor values:
            - home_court_advantage: 0-10 scale for home court advantage factor
            - rest_days_impact: 0-10 scale for rest days impact
            - recent_form_weight: 0-10 scale for recent performance weight
            - home_team: 1 if team1 is home, 2 if team2 is home, 0 for neutral
            - team1_rest_days: Number of rest days for team1
            - team2_rest_days: Number of rest days for team2
            - team1_recent_wins: Recent wins (last 10 games) for team1
            - team1_recent_losses: Recent losses (last 10 games) for team1
            - team2_recent_wins: Recent wins (last 10 games) for team2
            - team2_recent_losses: Recent losses (last 10 games) for team2
            
    Returns:
        tuple: Adjusted (team1_win_prob, team2_win_prob)
    """
    # Extract performance factors
    home_court_advantage = performance_factors.get('home_court_advantage', 5) / 10
    rest_days_impact = performance_factors.get('rest_days_impact', 5) / 10
    recent_form_weight = performance_factors.get('recent_form_weight', 5) / 10
    
    # Default values if not provided
    home_team = performance_factors.get('home_team', 0)  # 0 = neutral, 1 = team1 home, 2 = team2 home
    team1_rest_days = performance_factors.get('team1_rest_days', 1)
    team2_rest_days = performance_factors.get('team2_rest_days', 1)
    team1_recent_wins = performance_factors.get('team1_recent_wins', 5)
    team1_recent_losses = performance_factors.get('team1_recent_losses', 5)
    team2_recent_wins = performance_factors.get('team2_recent_wins', 5)
    team2_recent_losses = performance_factors.get('team2_recent_losses', 5)
    
    # Initialize adjustments
    team1_adjustment = 0
    team2_adjustment = 0
    
    # 1. Home Court Advantage (0-10% boost)
    max_home_advantage = 0.10
    if home_team == 1:
        # Team 1 is home
        team1_adjustment += home_court_advantage * max_home_advantage
        print(f"Team 1 home court adjustment: +{home_court_advantage * max_home_advantage:.3f}")
    elif home_team == 2:
        # Team 2 is home
        team2_adjustment += home_court_advantage * max_home_advantage
        print(f"Team 2 home court adjustment: +{home_court_advantage * max_home_advantage:.3f}")
    
    # 2. Rest Days Impact (0-2% per day difference)
    rest_difference = team1_rest_days - team2_rest_days
    rest_factor = rest_days_impact * 0.02
    rest_adjustment = rest_difference * rest_factor
    
    if rest_difference > 0:
        team1_adjustment += rest_adjustment
        print(f"Team 1 rest days adjustment: +{rest_adjustment:.3f} ({rest_difference} more rest days)")
    elif rest_difference < 0:
        team2_adjustment += abs(rest_adjustment)
        print(f"Team 2 rest days adjustment: +{abs(rest_adjustment):.3f} ({abs(rest_difference)} more rest days)")
    
    # 3. Recent Form Weight (0-15% impact)
    max_form_impact = 0.15
    
    team1_recent_win_pct = team1_recent_wins / (team1_recent_wins + team1_recent_losses) if (team1_recent_wins + team1_recent_losses) > 0 else 0.5
    team2_recent_win_pct = team2_recent_wins / (team2_recent_wins + team2_recent_losses) if (team2_recent_wins + team2_recent_losses) > 0 else 0.5
    
    # Calculate baseline win percentage from current probabilities
    baseline_team1_win_pct = team1_win_prob / (team1_win_prob + team2_win_prob)
    baseline_team2_win_pct = team2_win_prob / (team1_win_prob + team2_win_prob)
    
    # Calculate form difference compared to baseline
    team1_form_diff = team1_recent_win_pct - baseline_team1_win_pct
    team2_form_diff = team2_recent_win_pct - baseline_team2_win_pct
    
    # Apply form adjustment
    team1_form_adjustment = team1_form_diff * recent_form_weight * max_form_impact
    team2_form_adjustment = team2_form_diff * recent_form_weight * max_form_impact
    
    team1_adjustment += team1_form_adjustment
    team2_adjustment += team2_form_adjustment
    
    print(f"Team 1 form adjustment: {team1_form_adjustment:.3f} (recent form: {team1_recent_win_pct:.2f})")
    print(f"Team 2 form adjustment: {team2_form_adjustment:.3f} (recent form: {team2_recent_win_pct:.2f})")
    
    # Apply adjustments to probabilities
    adjusted_team1_win_prob = team1_win_prob * (1 + team1_adjustment)
    adjusted_team2_win_prob = team2_win_prob * (1 + team2_adjustment)
    
    # Normalize to ensure probabilities sum to 1
    total_prob = adjusted_team1_win_prob + adjusted_team2_win_prob
    normalized_team1_win_prob = adjusted_team1_win_prob / total_prob
    normalized_team2_win_prob = adjusted_team2_win_prob / total_prob
    
    print(f"Final adjustments - Team 1: {team1_adjustment:.3f}, Team 2: {team2_adjustment:.3f}")
    
    return normalized_team1_win_prob, normalized_team2_win_prob


def get_team_data_from_csv(team_abbr, data_path='data/team_data.csv'):
    """
    Extract team data from CSV file for a specific team
    
    Args:
        team_abbr: Team abbreviation
        data_path: Path to team_data.csv
        
    Returns:
        dict: Team data including rest days and recent form
    """
    try:
        # Read CSV file
        df = pd.read_csv(data_path)
        
        # Filter data for the specific team
        team_data = df[df['TEAM_ABBREVIATION'] == team_abbr]
        
        if team_data.empty:
            print(f"No data found for team {team_abbr}")
            return {
                'rest_days': 1,
                'recent_wins': 5,
                'recent_losses': 5,
                'is_home': False
            }
        
        # Sort by game date (most recent first)
        team_data['GAME_DATE'] = pd.to_datetime(team_data['GAME_DATE'])
        team_data = team_data.sort_values('GAME_DATE', ascending=False)
        
        # Get most recent game
        latest_game = team_data.iloc[0]
        
        # Calculate rest days (days since last game)
        today = datetime.now()
        last_game_date = latest_game['GAME_DATE']
        rest_days = (today - last_game_date).days
        
        # Determine if home team (vs) or away team (@)
        is_home = 'vs' in latest_game['MATCHUP']
        
        # Calculate recent form (wins and losses in last 10 games)
        recent_games = team_data.head(10)
        recent_wins = len(recent_games[recent_games['WL'] == 'W'])
        recent_losses = len(recent_games[recent_games['WL'] == 'L'])
        
        return {
            'rest_days': max(1, rest_days),  # Minimum 1 day rest
            'recent_wins': recent_wins,
            'recent_losses': recent_losses,
            'is_home': is_home
        }
    
    except Exception as e:
        print(f"Error getting team data: {e}")
        return {
            'rest_days': 1,
            'recent_wins': 5,
            'recent_losses': 5,
            'is_home': False
        }
