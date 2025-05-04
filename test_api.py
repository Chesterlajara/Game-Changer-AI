import requests
import json

# Base URL for the API
base_url = "http://localhost:5000/api"

# Test with different conference parameters
conferences = ["East", "West", "All", ""]

for conf in conferences:
    # Build URL with conference parameter
    url = f"{base_url}/team-standings"
    if conf:
        url += f"?conference={conf}"
    
    print(f"\n=== Testing URL: {url} ===")
    
    # Make the request
    response = requests.get(url)
    
    # Print response status
    print(f"Status code: {response.status_code}")
    
    # Parse JSON response
    if response.status_code == 200:
        data = response.json()
        teams = data.get("standings", [])
        print(f"Received {len(teams)} teams")
        
        # Print first few teams with their conference
        print("\nSample teams:")
        for i, team in enumerate(teams[:3]):
            print(f"  {team.get('team_name', 'Unknown')}: Conference = {team.get('conference', 'Unknown')}")
    else:
        print(f"Error: {response.text}")
