import pandas as pd
import pickle
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler
from xgboost import XGBClassifier

df = pd.read_csv("nba_team_data.csv")

df = df.drop(columns=[ 'GAME_DATE', 'MATCHUP'])

# Encode target
df['target'] = df['WL'].apply(lambda x: 1 if x == 'W' else 0)
df = df.drop(columns=['WL'])

X = df.drop(columns=['target'])
y = df['target']

# Impute missing values
num_cols = X.select_dtypes(include=['float64', 'int64']).columns
imputer = SimpleImputer(strategy='mean')
X[num_cols] = imputer.fit_transform(X[num_cols])

# One-hot encode categorical features
X = pd.get_dummies(X, drop_first=True)

# Scale features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Train XGBoost model with best parameters
model = XGBClassifier(
    use_label_encoder=False, 
    eval_metric='logloss',
    learning_rate=0.1, 
    max_depth=3, 
    n_estimators=200
)
model.fit(X_scaled, y)

with open("xgb_model.pkl", "wb") as f:
    pickle.dump(model, f)

with open("imputer.pkl", "wb") as f:
    pickle.dump(imputer, f)

with open("scaler.pkl", "wb") as f:
    pickle.dump(scaler, f)

with open("x_columns.pkl", "wb") as f:
    pickle.dump(X.columns.tolist(), f)

# X.columns.tolist()[:10]  # Show a sample of the feature names for reference
