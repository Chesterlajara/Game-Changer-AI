import pandas as pd

updated_player_df = pd.read_csv("ml_models/updated_player_data.csv")
updated_player_df.rename(columns={'TEAM_ABBREVIATION': 'TEAM_ABBR', 'TO': 'TOV'}, inplace=True)

updated_player_df[['W', 'L', 'W_PCT']] = 0
updated_player_df['MIN'] = 0

def remove_players_and_get_team_data(df, player_ids_to_remove, team_id):
    filtered_df = df[~df['PLAYER_ID'].isin(player_ids_to_remove)]

    # Group by GAME_ID, TEAM_ID, TEAM_ABBR and sum stats
    grouped = filtered_df.groupby(['GAME_ID', 'TEAM_ID', 'TEAM_ABBR']).sum(numeric_only=True).reset_index()

    if 'PLAYER_ID' in grouped.columns:
        grouped = grouped.drop(['PLAYER_ID','GAME_ID' ], axis=1)

    grouped_dict = grouped.to_dict(orient='records')

    for item in grouped_dict:
        if item['TEAM_ID'] == team_id:
            del item['TEAM_ID']
            print(item)
            return item
    
    print("No data found for TEAM_ID:", team_id)
    return None

remove_players_and_get_team_data(updated_player_df, [12345, 67890], team_id=1610612747)
