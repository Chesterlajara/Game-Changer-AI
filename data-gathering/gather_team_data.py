from nba_api.stats.endpoints import teamgamelog
from nba_api.stats.static import teams
import pandas as pd
import time

nba_teams = teams.get_teams()

all_game_logs = pd.DataFrame()

for team in nba_teams:
    team_id = team['id']
    team_abbr = team['abbreviation']
    print(f"Fetching game logs for {team_abbr}...")

    gamelog = teamgamelog.TeamGameLog(
        team_id=team_id,
        season='2024-25',
        season_type_all_star='Regular Season'
    )

    df = gamelog.get_data_frames()[0]
    df['TEAM_ABBR'] = team_abbr
    all_game_logs = pd.concat([all_game_logs, df], ignore_index=True)

    time.sleep(1)  # Avoid API throttling

csv_filename = 'nba_2024_2025_first_10_team_games.csv'
all_game_logs.to_csv(csv_filename, index=False)
print(f"\n✅ Done! Saved to '{csv_filename}' with {len(all_game_logs)} total rows.")
