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
