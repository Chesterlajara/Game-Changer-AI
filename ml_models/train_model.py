import pandas as pd
import pickle
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler
from xgboost import XGBClassifier

class NBAModelTrainer:
    def __init__(self, csv_path):
        self.csv_path = csv_path
        self.df = None
        self.X = None
        self.y = None
        self.model = None
        self.imputer = SimpleImputer(strategy='mean')
        self.scaler = StandardScaler()
        self.columns = None

    def load_data(self):
        self.df = pd.read_csv(self.csv_path)
        self.df.drop(columns=['GAME_DATE', 'MATCHUP'], inplace=True)
        self.df['target'] = self.df['WL'].apply(lambda x: 1 if x == 'W' else 0)
        self.df.drop(columns=['WL'], inplace=True)

    def preprocess_data(self):
        self.X = self.df.drop(columns=['target'])
        self.y = self.df['target']

        # Impute numeric columns
        num_cols = self.X.select_dtypes(include=['float64', 'int64']).columns
        self.X[num_cols] = self.imputer.fit_transform(self.X[num_cols])

        # One-hot encode categoricals
        self.X = pd.get_dummies(self.X, drop_first=True)

        # Store column names
        self.columns = self.X.columns.tolist()

        # Scale features
        self.X = self.scaler.fit_transform(self.X)

    def train_model(self):
        self.model = XGBClassifier(
            use_label_encoder=False,
            eval_metric='logloss',
            learning_rate=0.1,
            max_depth=3,
            n_estimators=200
        )
        self.model.fit(self.X, self.y)

    def save_artifacts(self, model_path="xgb_model.pkl",
                       imputer_path="imputer.pkl",
                       scaler_path="scaler.pkl",
                       columns_path="x_columns.pkl"):
        with open(model_path, "wb") as f:
            pickle.dump(self.model, f)
        with open(imputer_path, "wb") as f:
            pickle.dump(self.imputer, f)
        with open(scaler_path, "wb") as f:
            pickle.dump(self.scaler, f)
        with open(columns_path, "wb") as f:
            pickle.dump(self.columns, f)

    def run(self):
        self.load_data()
        self.preprocess_data()
        self.train_model()
        self.save_artifacts()

# Example usage:
# trainer = NBAModelTrainer("nba_team_data.csv")
# trainer.run()
