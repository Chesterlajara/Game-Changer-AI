import pandas as pd

# Read the CSV file
df = pd.read_csv('data/team_data.csv')

# Print column names
print("Columns:")
print(df.columns.tolist())

# Print first few rows
print("\nFirst 2 rows:")
print(df.head(2).to_string())
