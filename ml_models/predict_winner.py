import pickle
import pandas as pd

class TeamPredictionModel:
    def __init__(self, model_path, scaler_path, imputer_path, columns_path):
        # Load model, scaler, imputer, and column structure
        with open(model_path, "rb") as f:
            self.model = pickle.load(f)
        
        with open(scaler_path, "rb") as f:
            self.scaler = pickle.load(f)
        
        with open(imputer_path, "rb") as f:
            self.imputer = pickle.load(f)
        
        with open(columns_path, "rb") as f:
            self.trained_columns = pickle.load(f)
        
        self.num_cols = [col for col in self.trained_columns if not col.startswith('TEAM_ABBR_')]

    def preprocess(self, team_stats):
        """Preprocesses the team statistics and scales them."""
        df = pd.DataFrame([team_stats])
        df = pd.get_dummies(df)
        df = df.reindex(columns=self.trained_columns, fill_value=0)
        df[self.num_cols] = self.imputer.transform(df[self.num_cols])
        df_scaled = self.scaler.transform(df)
        return df_scaled

    def predict(self, team1_stats, team2_stats):
        """Predicts the winner between two teams based on their statistics."""
        team1_processed = self.preprocess(team1_stats)
        team2_processed = self.preprocess(team2_stats)

        prob1 = self.model.predict_proba(team1_processed)[0][1]  # Team 1 win probability
        prob2 = self.model.predict_proba(team2_processed)[0][1]  # Team 2 win probability

        total_prob = prob1 + prob2
        prob1_normalized = prob1 / total_prob
        prob2_normalized = prob2 / total_prob

        winner = "Team 1" if prob1_normalized > prob2_normalized else "Team 2"
        
        return {
            "winner": winner,
            "team1_win_prob": prob1_normalized,
            "team2_win_prob": prob2_normalized
        }

    def display_results(self, results):
        """Displays the prediction results."""
        winner = results['winner']
        team1_win_prob = results['team1_win_prob']
        team2_win_prob = results['team2_win_prob']
        
        print(f"{winner} is more likely to win.")
        print(f"Team 1 Win Probability: {team1_win_prob:.2%}")
        print(f"Team 2 Win Probability: {team2_win_prob:.2%}")

# Usage example
team1 = {
    'W': 10, 'L': 20, 'W_PCT': 0.6, 'MIN': 240, 'FGM': 42, 'FGA': 90, 'FG_PCT': 0.47,
    'FG3M': 6, 'FG3A': 30, 'FG3_PCT': 0.20, 'FTM': 20, 'FTA': 25, 'FT_PCT': 0.80,
    'OREB': 10, 'DREB': 35, 'REB': 45, 'AST': 0, 'STL': 7, 'BLK': 5, 'TOV': 13, 'PF': 18,
    'PTS': 116, 'TEAM_ABBR': 'LAL'
}

team2 = {
    'W': 28, 'L': 22, 'W_PCT': 0.56, 'MIN': 240, 'FGM': 40, 'FGA': 88, 'FG_PCT': 0.45,
    'FG3M': 10, 'FG3A': 28, 'FG3_PCT': 0.36, 'FTM': 22, 'FTA': 28, 'FT_PCT': 0.79,
    'OREB': 12, 'DREB': 32, 'REB': 44, 'AST': 23, 'STL': 8, 'BLK': 6, 'TOV': 14, 'PF': 17,
    'PTS': 112, 'TEAM_ABBR': 'BOS'
}

# Initialize the prediction model
model = TeamPredictionModel("ml_models/xgb_model.pkl", "ml_models/scaler.pkl", 
                            "ml_models/imputer.pkl", "ml_models/x_columns.pkl")

results = model.predict(team1, team2)

# Display the results
model.display_results(results)
