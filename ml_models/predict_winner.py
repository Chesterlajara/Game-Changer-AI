import pickle
import pandas as pd

# Load model, scaler, imputer, and column structure
with open("ml_models/xgb_model.pkl", "rb") as f:
    model = pickle.load(f)

with open("ml_models/scaler.pkl", "rb") as f:
    scaler = pickle.load(f)

with open("ml_models/imputer.pkl", "rb") as f:
    imputer = pickle.load(f)

with open("ml_models/x_columns.pkl", "rb") as f:
    trained_columns = pickle.load(f)

def predict_winner(team1_stats: dict, team2_stats: dict):
    def preprocess(team_stats):
        df = pd.DataFrame([team_stats])
        df = pd.get_dummies(df)
        df = df.reindex(columns=trained_columns, fill_value=0)
        df[num_cols] = imputer.transform(df[num_cols])
        df_scaled = scaler.transform(df)
        return df_scaled

    num_cols = [col for col in trained_columns if not col.startswith('TEAM_ABBR_')]

    team1_processed = preprocess(team1_stats)
    team2_processed = preprocess(team2_stats)

    prob1 = model.predict_proba(team1_processed)[0][1]  # Team 1 win probability
    prob2 = model.predict_proba(team2_processed)[0][1]  # Team 2 win probability

    total_prob = prob1 + prob2
    prob1_normalized = prob1 / total_prob
    prob2_normalized = prob2 / total_prob

    winner = "Team 1" if prob1_normalized > prob2_normalized else "Team 2"
    print(f"{winner} is more likely to win.")
    print(f"Team 1 Win Probability: {prob1_normalized:.2%}")
    print(f"Team 2 Win Probability: {prob2_normalized:.2%}")

team1 = {
    'W': 100, 'L': 20, 'W_PCT': 0.6, 'MIN': 240, 'FGM': 42, 'FGA': 90, 'FG_PCT': 0.47,
    'FG3M': 12, 'FG3A': 30, 'FG3_PCT': 0.40, 'FTM': 20, 'FTA': 25, 'FT_PCT': 0.80,
    'OREB': 10, 'DREB': 35, 'REB': 45, 'AST': 0, 'STL': 7, 'BLK': 5, 'TOV': 3, 'PF': 18,
    'PTS': 116, 'TEAM_ABBR': 'LAL'
}

team2 = {
    'W': 28, 'L': 22, 'W_PCT': 0.56, 'MIN': 240, 'FGM': 40, 'FGA': 88, 'FG_PCT': 0.45,
    'FG3M': 10, 'FG3A': 28, 'FG3_PCT': 0.36, 'FTM': 22, 'FTA': 28, 'FT_PCT': 0.79,
    'OREB': 12, 'DREB': 32, 'REB': 44, 'AST': 23, 'STL': 8, 'BLK': 6, 'TOV': 14, 'PF': 17,
    'PTS': 112, 'TEAM_ABBR': 'BOS'
}

predict_winner(team1, team2)