import sys
print("Python version:", sys.version)
print("Testing NBA API...")

try:
    from nba_api.stats.endpoints import leaguestandings
    print("Successfully imported leaguestandings")
    
    try:
        print("Attempting to call LeagueStandings()...")
        standings = leaguestandings.LeagueStandings()
        print("API call successful")
        
        try:
            print("Getting data frames...")
            df = standings.get_data_frames()[0]
            print(f"Successfully retrieved {len(df)} teams")
            print("Sample columns:", list(df.columns)[:5])
            print("First two rows:")
            print(df.head(2))
        except Exception as e:
            print(f"Error getting data frames: {e}")
    except Exception as e:
        print(f"Error calling LeagueStandings(): {e}")
except Exception as e:
    print(f"Error importing: {e}")

print("Test complete")
