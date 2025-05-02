# Game Changer AI

A mobile application that leverages the power of AI for basketball game predictions with transparent reasoning.

## Project Overview

Game Changer AI is a mobile application that uses artificial intelligence for predictive analysis of basketball games. It focuses on real-time data, individual player stats, and provides transparent prediction logic to users.

### Key Features

- AI-based game prediction model
- Transparent prediction logic
- Real-time NBA data integration
- User-driven customization for predictions

## Project Structure

- `app.py`: Flask backend API for the Flutter frontend
- `requirements.txt`: Python dependencies

## Setup Instructions

### Backend Setup

1. Create a virtual environment:
   ```
   python -m venv .venv
   ```

2. Activate the virtual environment:
   - Windows: `.venv\Scripts\activate`
   - macOS/Linux: `source .venv/bin/activate`

3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

4. Run the Flask application:
   ```
   python app.py
   ```

### Flutter Setup (Coming Soon)

Flutter frontend setup instructions will be added as the project progresses.

## API Endpoints

- `/api/games`: Get current and upcoming games
- `/api/player/<player_id>`: Get player career stats
- `/api/predictions/<game_id>`: Get prediction for a specific game
- `/api/simulation`: Run custom game simulation
- `/api/teams`: Get list of all NBA teams

## Technologies Used

- Backend: Flask, NBA API, pandas, NumPy, scikit-learn
- Frontend (Planned): Flutter
- Database (Planned): Firebase Firestore