import os
import random
import requests
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

YOUVERSION_API_KEY = os.getenv("YOUVERSION_API_KEY")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class MessageRequest(BaseModel):
    message: str


class HabitsRequest(BaseModel):
    sleep: float
    stress: float
    social: float
    rest: float


EMOTION_THEME_MAP = {
    "anxiety": "peace",
    "gratitude": "thankfulness",
    "anger": "patience",
    "neutral": "hope",
}


def get_scripture(theme: str):
    try:
        url = "https://developers.youversion.com/1.0/verses/search"
        headers = {
            "Authorization": f"Bearer {YOUVERSION_API_KEY}",
            "Accept": "application/json",
        }
        params = {"query": theme, "limit": 10}

        response = requests.get(url, headers=headers, params=params, timeout=8)

        if response.status_code == 200:
            data = response.json()
            verses = data.get("verses", [])
            if verses:
                verse = random.choice(verses)
                return {
                    "reference": verse.get("reference", "Unknown"),
                    "text": verse.get("text", "Peace be with you."),
                }
    except Exception as e:
        print("YouVersion error:", e)

    fallback_verses = [
        {"reference": "Philippians 4:6",
         "text": "Do not be anxious about anything, but in every situation present your requests to God."},
        {"reference": "Psalm 23:1",
         "text": "The Lord is my shepherd, I lack nothing."},
        {"reference": "Isaiah 41:10",
         "text": "So do not fear, for I am with you."},
        {"reference": "Matthew 11:28",
         "text": "Come to me, all you who are weary and burdened, and I will give you rest."},
    ]
    return random.choice(fallback_verses)


@app.post("/analyze")
async def analyze_message(data: MessageRequest):
    text = data.message.lower()

    emotion = "neutral"
    response_text = "Tell me more."

    if "anxious" in text:
        emotion = "anxiety"
        response_text = "I sense anxiety. Let's breathe for a moment."
    elif "grateful" in text:
        emotion = "gratitude"
        response_text = "Gratitude shifts your spiritual posture."
    elif "angry" in text:
        emotion = "anger"
        response_text = "Anger often hides deeper hurt. What is beneath it?"

    theme = EMOTION_THEME_MAP.get(emotion, "hope")
    scripture = get_scripture(theme)

    return {
        "emotion": emotion,
        "response": response_text,
        "scripture": scripture,
    }


@app.post("/habits")
async def analyze_habits(data: HabitsRequest):
    insight = ""
    theme = "hope"

    if data.sleep < 5:
        insight = "You are sleep-deprived. Rest restores the soul."
        theme = "rest"
    elif data.stress > 7:
        insight = "You are under heavy stress. Peace is possible."
        theme = "peace"
    elif data.social < 3:
        insight = "You may be isolating. Community is medicine."
        theme = "community"
    elif data.rest < 4:
        insight = "You need deeper rest. Sabbath is sacred."
        theme = "rest"
    else:
        insight = "You are in a balanced rhythm. Keep walking in gratitude."
        theme = "gratitude"

    scripture = get_scripture(theme)

    return {
        "insight": insight,
        "scripture": scripture,
    }