import os
import random
import requests
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

YOUVERSION_API_KEY = os.getenv("YOUVERSION_API_KEY")

# Simple in-memory resonance store
resonance_profile = {
    "peace": 0,
    "thankfulness": 0,
    "patience": 0,
    "hope": 0,
    "rest": 0,
    "community": 0,
    "gratitude": 0,
}

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Models ───────────────────────────────────────────────
class MessageRequest(BaseModel):
    text: str  # matches what chat_screen sends


class HabitsRequest(BaseModel):
    sleep: float
    stress: float
    social: float
    rest: float
    heart_rate: int = 72
    activity_level: float = 0.3


# ─── Emotion detection ────────────────────────────────────
EMOTION_KEYWORDS = {
    "anxiety": ["anxious", "anxiety", "worried", "nervous", "scared", "fear", "panic", "overwhelmed"],
    "gratitude": ["grateful", "thankful", "blessed", "appreciate", "thank"],
    "anger": ["angry", "anger", "frustrated", "mad", "furious", "irritated"],
    "sadness": ["sad", "depressed", "lonely", "hopeless", "empty", "grief", "lost"],
    "joy": ["happy", "joyful", "excited", "wonderful", "great", "amazing", "blessed"],
    "stress": ["stressed", "tired", "exhausted", "burnout", "pressure", "overwhelmed"],
}

EMOTION_RESPONSES = {
    "anxiety": [
        "I sense anxiety in your words. You are not alone in this moment.",
        "Anxiety often signals we are carrying more than we were meant to carry alone.",
        "Breathe. The God who holds the universe holds this moment too.",
    ],
    "gratitude": [
        "Gratitude is a spiritual posture that shifts everything.",
        "A thankful heart opens the door to deeper peace.",
        "Your gratitude is noticed — keep that light alive.",
    ],
    "anger": [
        "Anger often hides a deeper hurt beneath it. What is underneath?",
        "Your feelings are valid. Let's find stillness together.",
        "Even in anger, you are held with compassion.",
    ],
    "sadness": [
        "Sadness is not weakness — it is the soul asking for comfort.",
        "You do not have to carry this weight alone.",
        "In the valleys, light still finds its way in.",
    ],
    "joy": [
        "Joy is a gift — let it fill every corner of this moment.",
        "Your light is beautiful. Keep shining.",
        "Celebrate this. Gratitude multiplies joy.",
    ],
    "stress": [
        "Your body and soul are signaling they need rest.",
        "Stress is a signal, not a sentence. Let's breathe.",
        "You were not designed to carry this alone.",
    ],
    "neutral": [
        "I am here with you. Tell me more about what is on your heart.",
        "Every moment is sacred. What are you feeling right now?",
        "Lumíne is listening. Share what is on your mind.",
    ],
}

EMOTION_THEME_MAP = {
    "anxiety": "peace",
    "gratitude": "thankfulness",
    "anger": "patience",
    "sadness": "hope",
    "joy": "gratitude",
    "stress": "rest",
    "neutral": "hope",
}

FALLBACK_VERSES = {
    "peace": [
        {"reference": "Philippians 4:6-7", "text": "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God."},
        {"reference": "John 14:27", "text": "Peace I leave with you; my peace I give you. Do not let your hearts be troubled and do not be afraid."},
        {"reference": "Psalm 46:10", "text": "Be still, and know that I am God."},
    ],
    "thankfulness": [
        {"reference": "1 Thessalonians 5:18", "text": "Give thanks in all circumstances; for this is God's will for you in Christ Jesus."},
        {"reference": "Psalm 100:4", "text": "Enter his gates with thanksgiving and his courts with praise; give thanks to him and praise his name."},
    ],
    "patience": [
        {"reference": "James 1:19", "text": "Everyone should be quick to listen, slow to speak and slow to become angry."},
        {"reference": "Proverbs 15:1", "text": "A gentle answer turns away wrath, but a harsh word stirs up anger."},
    ],
    "hope": [
        {"reference": "Jeremiah 29:11", "text": "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future."},
        {"reference": "Romans 15:13", "text": "May the God of hope fill you with all joy and peace as you trust in him."},
        {"reference": "Isaiah 40:31", "text": "But those who hope in the Lord will renew their strength."},
    ],
    "rest": [
        {"reference": "Matthew 11:28", "text": "Come to me, all you who are weary and burdened, and I will give you rest."},
        {"reference": "Psalm 23:2", "text": "He makes me lie down in green pastures, he leads me beside quiet waters."},
    ],
    "gratitude": [
        {"reference": "Psalm 136:1", "text": "Give thanks to the Lord, for he is good. His love endures forever."},
        {"reference": "Colossians 3:17", "text": "Whatever you do, whether in word or deed, do it all in the name of the Lord Jesus, giving thanks to God the Father."},
    ],
    "community": [
        {"reference": "Hebrews 10:24-25", "text": "And let us consider how we may spur one another on toward love and good deeds."},
        {"reference": "Ecclesiastes 4:9", "text": "Two are better than one, because they have a good return for their labor."},
    ],
}


def detect_emotion(text: str) -> str:
    text_lower = text.lower()
    for emotion, keywords in EMOTION_KEYWORDS.items():
        for keyword in keywords:
            if keyword in text_lower:
                return emotion
    return "neutral"


def get_scripture(theme: str):
    # Try YouVersion API first
    try:
        if YOUVERSION_API_KEY:
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
                        "text": verse.get("text", ""),
                    }
    except Exception as e:
        print("YouVersion error:", e)

    # Fallback to local verses
    verse_list = FALLBACK_VERSES.get(theme, FALLBACK_VERSES["hope"])
    return random.choice(verse_list)


def generate_habit_insight(sleep, stress, social, rest, heart_rate, activity_level):
    insights = []

    if sleep < 6:
        insights.append("Your sleep is below what your soul needs to thrive.")
    elif sleep >= 8:
        insights.append("You are honoring rest — this is sacred discipline.")
    else:
        insights.append("Your sleep rhythm is steady. Keep nurturing it.")

    if heart_rate > 100:
        insights.append("Your heart rate signals your body is under load right now.")
    elif heart_rate < 65:
        insights.append("Your heart is calm — a rare and precious state.")

    if stress > 7:
        insights.append("Stress is high. Your spirit is asking for stillness.")
    elif stress < 4:
        insights.append("Your inner peace is evident in your rhythm today.")

    if activity_level > 0.7:
        insights.append("High activity signals strength — but remember to restore.")
    elif activity_level < 0.2:
        insights.append("Movement, even gentle, can shift your spiritual state.")

    if not insights:
        insights.append("Your rhythms are balanced. Stay present in this grace.")

    return " ".join(insights[:2])


def get_habit_verse(sleep, stress, heart_rate):
    if heart_rate > 100 or stress > 7:
        return get_scripture("peace")
    elif sleep < 6:
        return get_scripture("rest")
    else:
        return get_scripture("hope")


# ─── Routes ──────────────────────────────────────────────

@app.get("/")
async def root():
    return {"status": "Lumíne backend alive"}


@app.post("/analyze")
async def analyze_message(data: MessageRequest):
    text = data.text
    emotion = detect_emotion(text)
    theme = EMOTION_THEME_MAP.get(emotion, "hope")

    # Update resonance
    resonance_profile[theme] = resonance_profile.get(theme, 0) + 1

    # Pick response
    responses = EMOTION_RESPONSES.get(emotion, EMOTION_RESPONSES["neutral"])
    response_text = random.choice(responses)

    # Get scripture
    scripture = get_scripture(theme)

    return {
        "emotion": emotion,
        "response": response_text,
        "scripture": scripture,
    }


@app.post("/habits")
async def analyze_habits(data: dict):
    sleep = data.get("sleep", 6)
    stress = data.get("stress", 5)
    social = data.get("social", 5)
    rest = data.get("rest", 6)
    heart_rate = data.get("heart_rate", 72)
    activity_level = data.get("activity_level", 0.3)

    insight = generate_habit_insight(sleep, stress, social, rest, heart_rate, activity_level)
    scripture = get_habit_verse(sleep, stress, heart_rate)

    return {
        "insight": insight,
        "verse": scripture["text"],
        "reference": scripture["reference"],
    }


@app.get("/resonance")
async def get_resonance():
    return {"profile": resonance_profile}


@app.post("/resonance")
async def update_resonance(data: dict):
    themes = data.get("themes", [])
    for theme in themes:
        if theme in resonance_profile:
            resonance_profile[theme] += 1
    return {"profile": resonance_profile}