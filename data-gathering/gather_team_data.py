from nba_api.stats.endpoints import teamgamelog
from nba_api.stats.static import teams
import pandas as pd
import time


class NBADataCollector:
    def __init__(self, season='2024-25', season_type='Regular Season', delay=1):
        self.season = season
        self.season_type = season_type
        self.delay = delay
        self.nba_teams = teams.get_teams()
        self.all_game_logs = pd.DataFrame()

    def fetch_team_game_logs(self, team_id, team_abbr):
        """Fetch game logs for a specific team."""
        print(f"Fetching game logs for {team_abbr}...")
        gamelog = teamgamelog.TeamGameLog(
            team_id=team_id,
            season=self.season,
            season_type_all_star=self.season_type
        )
        df = gamelog.get_data_frames()[0]
        df['TEAM_ABBR'] = team_abbr
        return df

    def collect_all_logs(self):
        """Loop through all teams and collect their game logs."""
        for team in self.nba_teams:
            team_id = team['id']
            team_abbr = team['abbreviation']
            team_log = self.fetch_team_game_logs(team_id, team_abbr)
            self.all_game_logs = pd.concat([self.all_game_logs, team_log], ignore_index=True)
            time.sleep(self.delay)

    def save_to_csv(self, filename):
        """Save the combined game logs to a CSV file."""
        self.all_game_logs.to_csv(filename, index=False)
        print(f"\n✅ Done! Saved to '{filename}' with {len(self.all_game_logs)} total rows.")


if __name__ == '__main__':
    collector = NBADataCollector()
    collector.collect_all_logs()
    collector.save_to_csv('nba_2024_2025_first_10_team_games.csv')
