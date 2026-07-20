import os
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


# Emotion → Scripture theme mapping
EMOTION_THEME_MAP = {
    "anxiety": "peace",
    "gratitude": "thankfulness",
    "anger": "patience",
    "neutral": "hope",
}


def get_scripture(theme: str):
    """
    Fetch a related verse from YouVersion API based on theme.
    """
    try:
        url = "https://developers.youversion.com/1.0/verses/search"
        headers = {
            "Authorization": f"Bearer {YOUVERSION_API_KEY}",
            "Accept": "application/json",
        }
        params = {"query": theme}

        response = requests.get(url, headers=headers, params=params, timeout=8)

        if response.status_code == 200:
            data = response.json()
            if "verses" in data and len(data["verses"]) > 0:
                verse = data["verses"][0]
                return {
                    "reference": verse.get("reference", "Unknown"),
                    "text": verse.get("text", "Peace be with you."),
                }
    except Exception as e:
        print("YouVersion error:", e)

    # fallback default
    return {
        "reference": "Philippians 4:6",
        "text": "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God."
    }


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