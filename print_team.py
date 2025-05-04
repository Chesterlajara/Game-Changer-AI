from nba_api.stats.endpoints import leaguestandings

# Get real data from NBA API
print("Fetching data from NBA API...")
standings = leaguestandings.LeagueStandings()
standings_data = standings.get_data_frames()[0]
print(f"Successfully retrieved {len(standings_data)} teams from NBA API")

# Print column names for debugging
print(f"API response columns: {list(standings_data.columns)}")

# PRINT ONE COMPLETE TEAM ROW WITH ALL FIELDS
print("\n==== ONE COMPLETE TEAM FROM NBA API WITH ALL FIELDS: =====")
if len(standings_data) > 0:
    first_team = standings_data.iloc[0]
    for col in standings_data.columns:
        print(f"  {col}: {first_team[col]}")
print("==== END OF COMPLETE TEAM DATA =====")

# Print the raw Conference values from the first few teams
print("\n==== RAW CONFERENCE VALUES FROM NBA API: =====")
for i, (_, row) in enumerate(standings_data.iterrows()):
    if i >= 5:  # Only print first 5 teams
        break
    team_name = row['TeamName'] if 'TeamName' in row else 'Unknown'
    conference = row['Conference'] if 'Conference' in row else 'Unknown'
    print(f"Team {i+1}: {team_name}, Conference: '{conference}'")
print("==== END OF RAW CONFERENCE VALUES =====")

# Print all unique conference values
unique_conferences = set(row['Conference'] for _, row in standings_data.iterrows() if 'Conference' in row)
print(f"UNIQUE CONFERENCE VALUES: {unique_conferences}")
