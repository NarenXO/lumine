# Lumíne — Scripture That Reads You

> An ambient spiritual intelligence that delivers the right word at the right physiological and emotional moment.

---

## What is Lumíne?

Most people don't open a Bible app when they're falling apart at 2am. They scroll. They spiral. They carry weight alone.

Lumíne changes that. It listens, reads your emotional and physiological state, and delivers Scripture at the exact moment it's needed — not when you remember to open it. When you need it.

---

## Features

| Feature | Description |
|---|---|
| **Reflect** | Voice-first spiritual companion. Speak freely. Lumíne listens beneath your words and responds with warmth and scripture. |
| **State Tab** | Your emotional fingerprint the moment you open the app. Emotion-colored orb, anchor verse, emotion wave. |
| **Soul Map** | Your spiritual identity built over time. Fingerprint, patterns, journal, stress observations. |
| **Zen Mode** | Meditative scripture sessions. Word-by-word verse reveal with ambient music. |
| **Patterns** | Body, mind, spirit visualization. Heart rate waveform, presence rings, emotional weather, daily rhythms. |
| **Sacred Interruption** | Full-screen breathing pause triggered by high anxiety. 4-7-8 breath with a precisely chosen verse. |
| **Car Mode** | Hands-free verse narration for driving. Auto-advances with ambient music. |
| **Calendar** | Google Calendar integration. Scripture delivered before your hardest moments of the day. |

---

## Tech Stack

- **Frontend:** Flutter (Android)
- **Backend:** Python FastAPI deployed on Render
- **AI:** Gloo AI Studio — Claude Haiku 4.5
- **Scripture:** YouVersion Platform API
- **Voice:** ElevenLabs (Bella voice) with device TTS fallback
- **Audio:** audioplayers
- **Biometrics:** Health Connect API
- **Calendar:** Google Calendar OAuth
- **Memory:** Local persistence with rolling summarization

---

## Architecture
User
↓
Flutter App (Android)
↓
FastAPI Backend (Render)
├── Gloo AI Studio → emotion detection, responses, journal, soul map, zen narration
└── YouVersion Platform API → scripture delivery across all surfaces

text


---

## How the APIs Are Used

### YouVersion Platform API
- Scripture delivery in Zen mode, Sacred Interruption, State tab, Soul Map, Car Mode, and Calendar integration
- Multiple translations supported: NIV, KJV, ESV, MSG

### Gloo AI Studio — Claude Haiku 4.5
- Emotion detection from indirect language — reads beneath the words
- Warm, psychiatrist-level spiritual responses in 1-3 sentences
- Daily journal generation based on emotional patterns
- Spiritual fingerprint generation over time
- Zen narration — 3 sentences, under 40 words, faith-tuned
- Rolling memory summarization into structured user profile
- Soul map generation — who you are becoming

---

## Backend Endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/` | GET | Health check |
| `/analyze` | POST | Emotion detection and spiritual response |
| `/zen` | POST | Verse selection and narration |
| `/journal` | POST | Daily journal generation |
| `/soulmap` | POST | Spiritual fingerprint |
| `/summarize` | POST | Rolling memory summarization |
| `/habits` | POST | Biometric pattern analysis |
| `/resonance` | GET/POST | Resonance profile |

---

## Setup Instructions

### Backend

```bash
cd backend
pip install -r requirements.txt
Create a .env file in the backend folder:

text

YOUVERSION_API_KEY=your_key_here
GLOO_CLIENT_ID=your_id_here
GLOO_CLIENT_SECRET=your_secret_here
Then run:

Bash

uvicorn main:app --reload
Mobile App
Bash

cd mobile_app
flutter pub get
flutter run
The app connects to the deployed backend at:

text

https://lumine-backend-420v.onrender.com
Project Structure
text

lumine/
├── backend/
│   ├── main.py              FastAPI backend — all endpoints
│   ├── requirements.txt
│   └── render.yaml
│
└── mobile_app/
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   │   ├── home_screen.dart
    │   │   ├── dashboard_screen.dart
    │   │   ├── scripture_feed_screen.dart
    │   │   ├── chat_screen.dart
    │   │   ├── habits_screen.dart
    │   │   ├── profile_screen.dart
    │   │   ├── sacred_interruption_screen.dart
    │   │   ├── car_mode_screen.dart
    │   │   └── calendar_screen.dart
    │   ├── services/
    │   │   ├── api_service.dart
    │   │   ├── app_controller.dart
    │   │   ├── app_theme.dart
    │   │   ├── tts_service.dart
    │   │   ├── memory_service.dart
    │   │   ├── stats_service.dart
    │   │   └── notification_service.dart
    │   └── widgets/
    │       ├── lumine_background.dart
    │       ├── animated_bento_card.dart
    │       └── glow_orb.dart
    └── assets/
        └── audio/ambient.mp3
Hackathon
Built for Scripture in New Frontiers — YouVersion + Gloo AI Hackathon on Kaggle

Deadline: August 1, 2025

Scripture should not wait to be found. It should arrive — in the car, before the meeting, during the spiral, in the stillness. Lumíne is the bridge between where people already are and the word that was written for exactly that moment.

Made with love by Naren Rakesh

