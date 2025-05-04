from nba_api.stats.endpoints import leaguestandings
import pandas as pd
import traceback

def test_nba_api():
    try:
        print("Attempting to fetch data from NBA API...")
        standings = leaguestandings.LeagueStandings()
        standings_data = standings.get_data_frames()[0]
        print(f"Successfully retrieved {len(standings_data)} teams from NBA API")
        
        # Print column names
        print(f"API response columns: {list(standings_data.columns)}")
        
        # Print first few rows
        print("Sample data from API:")
        print(standings_data.head(2))
        
        return True
    except Exception as e:
        print(f"Error fetching data from NBA API: {e}")
        print("Full traceback:")
        traceback.print_exc()
        return False

if __name__ == "__main__":
    test_nba_api()
