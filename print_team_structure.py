from nba_api.stats.endpoints import leaguestandings
import json

# Get real data from NBA API
print("Fetching data from NBA API...")
standings = leaguestandings.LeagueStandings()
standings_data = standings.get_data_frames()[0]
print(f"Successfully retrieved {len(standings_data)} teams from NBA API")

# Print the first team's data structure
if len(standings_data) > 0:
    first_team = standings_data.iloc[0]
    print("\n==== TEAM DATA STRUCTURE: =====")
    for col in standings_data.columns:
        print(f"  {col}: {first_team[col]}")
    
    # Convert to dictionary to see the exact structure
    team_dict = first_team.to_dict()
    print("\n==== TEAM DICTIONARY STRUCTURE: =====")
    print(json.dumps(team_dict, indent=2, default=str))
    
    # Print all unique conference values
    unique_conferences = set(row['Conference'] for _, row in standings_data.iterrows() if 'Conference' in row)
    print(f"\nUNIQUE CONFERENCE VALUES: {unique_conferences}")
    
    # Print the first few teams with their conference
    print("\n==== FIRST 5 TEAMS WITH CONFERENCE: =====")
    for i, (_, row) in enumerate(standings_data.iterrows()):
        if i >= 5:
            break
        team_name = row['TeamName'] if 'TeamName' in row else 'Unknown'
        conference = row['Conference'] if 'Conference' in row else 'Unknown'
        print(f"Team {i+1}: {team_name}, Conference: '{conference}'")
