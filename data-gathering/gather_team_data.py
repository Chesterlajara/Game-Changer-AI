from nba_api.stats.endpoints import teamgamelog
from nba_api.stats.static import teams
import pandas as pd
import time

nba_teams = teams.get_teams()

print(nba_teams)