from nba_api.stats.endpoints import leaguegamelog, boxscoretraditionalv2
import pandas as pd
import time
import os

progress_file = 'nba_2024_2025_player_game_stats_progress.csv'
if os.path.exists(progress_file):
    all_player_stats = pd.read_csv(progress_file)
    if 'GAME_ID' not in all_player_stats.columns:
        all_player_stats['GAME_ID'] = None
    print(f"Resuming from {len(all_player_stats)} rows already saved.")
else:
    all_player_stats = pd.DataFrame(columns=['GAME_ID', 'PLAYER_ID', 'TEAM_ID', 'MIN', 'PTS', 'AST', 'REB', 'STL', 'BLK', 'TO', 'PF', 'FG_PCT', 'FG3_PCT', 'FT_PCT', 'PLUS_MINUS'])
    print("Starting fresh. No progress file found.")

gamelog = leaguegamelog.LeagueGameLog(season='2024-25', season_type_all_star='Regular Season')
games_df = gamelog.get_data_frames()[0]
game_ids = games_df['GAME_ID'].unique()

for game_id in game_ids:
    if game_id in all_player_stats['GAME_ID'].values:
        print(f"Skipping game {game_id} (already processed).")
        continue

    print(f"Fetching player stats for game {game_id}...")

    max_retries = 3
    retries = 0
    success = False

    while retries < max_retries:
        try:
            boxscore = boxscoretraditionalv2.BoxScoreTraditionalV2(game_id=game_id)
            players_df = boxscore.get_data_frames()[0]
            players_df['GAME_ID'] = game_id
            players_df = players_df[~players_df.duplicated(subset=['GAME_ID', 'PLAYER_ID'], keep='first')]
            all_player_stats = pd.concat([all_player_stats, players_df], ignore_index=True)

            if len(all_player_stats) % 1000 == 0:
                all_player_stats.to_csv(progress_file, index=False)
                print(f"Progress saved at {len(all_player_stats)} rows.")

            time.sleep(1)
            success = True
            break

        except Exception as e:
            retries += 1
            print(f"Failed to fetch stats for game {game_id}, attempt {retries}/{max_retries}: {e}")
            time.sleep(5)

    if not success:
        print(f"Game {game_id} failed after {max_retries} retries. Saving progress and exiting.")
        all_player_stats.to_csv(progress_file, index=False)
        exit()

final_filename = 'nba_2024_2025_player_game_stats_complete.csv'
all_player_stats.to_csv(final_filename, index=False)
print(f"\n✅ Done! Saved player stats to '{final_filename}' with {len(all_player_stats)} rows.")
