# 🏀 GameChangerAI

**GameChangerAI** is a mobile application designed to deliver data-driven predictions for NBA basketball games using advanced machine learning algorithms. Built with Flutter, it helps users—ranging from casual fans to analysts and sports bettors—understand game dynamics through transparent and insightful win probability forecasts.

---

## 📌 Purpose

GameChangerAI empowers users to make more informed decisions about NBA basketball games by offering:

- Accurate **win probability predictions**
- **Clear explanations** behind each prediction
- **Simulation tools** for hypothetical matchups with user-defined variables

---

## 📈 Scope

In its initial release, GameChangerAI will:

- ✅ Focus exclusively on **NBA basketball games**
- ✅ Leverage **real-time data** (e.g., player stats, injuries, team trends) from the NBA Stats API
- ✅ Provide **transparent reasoning** behind each AI-driven prediction
- ✅ Include tools to simulate outcomes of **custom matchups**
- ✅ Be developed and deployed for **mobile platforms** using **Flutter**

---

## ⚠️ Limitations

- ❌ Currently supports **only NBA** (no other sports or leagues)
- ⚠️ Predictions rely on the **availability and accuracy** of data from the NBA Stats API
- 🚫 AI predictions are **not 100% guaranteed**, as real-world sports contain unpredictable elements

---

## 🛠️ Tech Stack

- **Frontend**: Flutter
- **Backend/AI**: Python (TensorFlow / scikit-learn, etc.)
- **Data Source**: NBA Stats API
- **Version Control**: GitHub

---

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
 
 ### Flutter Setup
 1. Check if Flutter is intalled
    ```
    flutter --version
    ```  
 2. Install dependencies
     ```
    flutter pub get
    ```  
 3. Run Flutter
     ```
    flutter run -d chrome
    ```  
 ---
 
 ## API Endpoints
 
 - `/api/games`: Get current and upcoming games
 - `/api/player/<player_id>`: Get player career stats
 - `/api/predictions/<game_id>`: Get prediction for a specific game
 - `/api/simulation`: Run custom game simulation
 - `/api/teams`: Get list of all NBA teams
---

## 📱 Features

- Game prediction updates from NBA_API
- Historical matchup analysis  
- Player performance impact visualization  
- Interactive simulation interface  
- Experiment Feature
---

## 🧠 Team & Contributors
- **Christine Joyce De Leon** - Frontend Developer, UI/UX Designer
- **Chester Lajara** - Frontend Developer, Quality Assurance, Project Manager
- **Mann Lester Magbuhos** – Full Stack Developer, UI/UX Designer, AI Model Integrator  
- **Marc Linus Rosales** - AI Model Integrator, Backend Developer

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 📬 Contact

For suggestions, bug reports, or contributions:

- 📧 **mannlesterm@gmail.com**  
- 🔗 [GitHub](https://github.com/christinedln)

- 📧 **mannlesterm@gmail.com**  
- 🔗 [GitHub](https://github.com/MannLester)

- 📧 **mannlesterm@gmail.com**  
- 🔗 [GitHub](https://github.com/MannLester)

- 📧 **mannlesterm@gmail.com**  
- 🔗 [GitHub](https://github.com/MannLester)

