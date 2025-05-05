import os
import time
import pandas as pd
from nba_api.stats.endpoints import leaguegamelog, boxscoretraditionalv2


class NBAStatsScraper:
    def __init__(self, season='2024-25', season_type='Regular Season',
                 progress_file='nba_2024_2025_player_game_stats_progress.csv',
                 final_file='nba_2024_2025_player_game_stats_complete.csv'):

        self.season = season
        self.season_type = season_type
        self.progress_file = progress_file
        self.final_file = final_file
        self.all_player_stats = self._load_progress()

    def _load_progress(self):
        if os.path.exists(self.progress_file):
            df = pd.read_csv(self.progress_file)
            if 'GAME_ID' not in df.columns:
                df['GAME_ID'] = None
            print(f"Resuming from {len(df)} rows already saved.")
            return df
        else:
            print("Starting fresh. No progress file found.")
            return pd.DataFrame(columns=[
                'GAME_ID', 'PLAYER_ID', 'TEAM_ID', 'MIN', 'PTS', 'AST', 'REB',
                'STL', 'BLK', 'TO', 'PF', 'FG_PCT', 'FG3_PCT', 'FT_PCT', 'PLUS_MINUS'
            ])

    def _save_progress(self):
        self.all_player_stats.to_csv(self.progress_file, index=False)
        print(f"✅ Progress saved with {len(self.all_player_stats)} rows.")

    def _fetch_game_ids(self):
        gamelog = leaguegamelog.LeagueGameLog(
            season=self.season, season_type_all_star=self.season_type)
        games_df = gamelog.get_data_frames()[0]
        return games_df['GAME_ID'].unique()

    def _fetch_player_stats_for_game(self, game_id):
        boxscore = boxscoretraditionalv2.BoxScoreTraditionalV2(game_id=game_id)
        players_df = boxscore.get_data_frames()[0]
        players_df['GAME_ID'] = game_id
        players_df = players_df[~players_df.duplicated(subset=['GAME_ID', 'PLAYER_ID'], keep='first')]
        return players_df

    def run(self):
        game_ids = self._fetch_game_ids()

        for game_id in game_ids:
            if game_id in self.all_player_stats['GAME_ID'].values:
                print(f"Skipping game {game_id} (already processed).")
                continue

            print(f"Fetching player stats for game {game_id}...")

            max_retries = 3
            for attempt in range(1, max_retries + 1):
                try:
                    players_df = self._fetch_player_stats_for_game(game_id)
                    self.all_player_stats = pd.concat([self.all_player_stats, players_df], ignore_index=True)

                    if len(self.all_player_stats) % 1000 == 0:
                        self._save_progress()

                    time.sleep(1)
                    break
                except Exception as e:
                    print(f"Failed to fetch stats for game {game_id}, attempt {attempt}/{max_retries}: {e}")
                    time.sleep(5)
            else:
                print(f"Game {game_id} failed after {max_retries} retries. Saving progress and exiting.")
                self._save_progress()
                return

        self.all_player_stats.to_csv(self.final_file, index=False)
        print(f"\n✅ Done! Saved player stats to '{self.final_file}' with {len(self.all_player_stats)} rows.")


if __name__ == '__main__':
    scraper = NBAStatsScraper()
    scraper.run()
