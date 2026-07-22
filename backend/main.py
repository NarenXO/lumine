import os
import random
import base64
import time
import requests
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

YOUVERSION_API_KEY = os.getenv("YOUVERSION_API_KEY")
GLOO_CLIENT_ID = os.getenv("GLOO_CLIENT_ID")
GLOO_CLIENT_SECRET = os.getenv("GLOO_CLIENT_SECRET")

# ─── Gloo Token Management ────────────────────────────
_gloo_token = None
_gloo_token_expiry = 0

def get_gloo_token() -> str:
    global _gloo_token, _gloo_token_expiry

    if _gloo_token and time.time() < _gloo_token_expiry - 60:
        return _gloo_token

    auth = base64.b64encode(
        f"{GLOO_CLIENT_ID}:{GLOO_CLIENT_SECRET}".encode()
    ).decode()

    response = requests.post(
        "https://platform.ai.gloo.com/oauth2/token",
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": f"Basic {auth}"
        },
        data={
            "grant_type": "client_credentials",
            "scope": "api/access"
        },
        timeout=10
    )

    data = response.json()
    _gloo_token = data["access_token"]
    _gloo_token_expiry = time.time() + data.get("expires_in", 3600)
    return _gloo_token


def call_gloo(system_prompt: str, user_message: str) -> str:
    try:
        token = get_gloo_token()
        response = requests.post(
            "https://platform.ai.gloo.com/ai/v1/responses",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}"
            },
            json={
                "model": "gloo-openai-gpt-5-mini",
                "instructions": system_prompt,
                "input": [
                    {"role": "user", "content": user_message}
                ]
            },
            timeout=15
        )
        output = response.json()["output"]
        message = next(
            item for item in output if item["type"] == "message"
        )
        return message["content"][0]["text"]
    except Exception as e:
        print(f"Gloo error: {e}")
        return ""


# ─── App setup ───────────────────────────────────────
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── In-memory resonance ─────────────────────────────
resonance_profile = {
    "peace": 0,
    "thankfulness": 0,
    "patience": 0,
    "hope": 0,
    "rest": 0,
    "community": 0,
    "gratitude": 0,
}

# ─── Models ──────────────────────────────────────────
class MessageRequest(BaseModel):
    text: str


# ─── Fallback verses ─────────────────────────────────
FALLBACK_VERSES = {
    "peace": [
        {"reference": "Psalm 46:10", "text": "Be still, and know that I am God."},
        {"reference": "John 14:27", "text": "Peace I leave with you; my peace I give you."},
        {"reference": "Philippians 4:7", "text": "The peace of God, which transcends all understanding, will guard your hearts."},
    ],
    "hope": [
        {"reference": "Jeremiah 29:11", "text": "For I know the plans I have for you, declares the Lord."},
        {"reference": "Romans 15:13", "text": "May the God of hope fill you with all joy and peace."},
        {"reference": "Isaiah 40:31", "text": "Those who hope in the Lord will renew their strength."},
    ],
    "rest": [
        {"reference": "Matthew 11:28", "text": "Come to me, all you who are weary and burdened, and I will give you rest."},
        {"reference": "Psalm 23:2", "text": "He makes me lie down in green pastures, he leads me beside quiet waters."},
        {"reference": "Psalm 4:8", "text": "In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety."},
    ],
    "gratitude": [
        {"reference": "Psalm 136:1", "text": "Give thanks to the Lord, for he is good."},
        {"reference": "1 Thessalonians 5:18", "text": "Give thanks in all circumstances."},
        {"reference": "James 1:17", "text": "Every good and perfect gift is from above."},
    ],
    "patience": [
        {"reference": "James 1:19", "text": "Everyone should be quick to listen, slow to speak and slow to become angry."},
        {"reference": "Proverbs 15:1", "text": "A gentle answer turns away wrath."},
        {"reference": "Romans 12:12", "text": "Be joyful in hope, patient in affliction, faithful in prayer."},
    ],
    "strength": [
        {"reference": "Philippians 4:13", "text": "I can do all this through him who gives me strength."},
        {"reference": "Isaiah 41:10", "text": "So do not fear, for I am with you."},
        {"reference": "Psalm 46:1", "text": "God is our refuge and strength, an ever-present help in trouble."},
    ],
    "comfort": [
        {"reference": "Psalm 34:18", "text": "The Lord is close to the brokenhearted."},
        {"reference": "Psalm 147:3", "text": "He heals the brokenhearted and binds up their wounds."},
        {"reference": "2 Corinthians 1:3", "text": "The God of all comfort, who comforts us in all our troubles."},
    ],
}

EMOTION_THEME_MAP = {
    "anxiety": "peace",
    "anxious": "peace",
    "stressed": "rest",
    "stress": "rest",
    "gratitude": "gratitude",
    "grateful": "gratitude",
    "anger": "patience",
    "angry": "patience",
    "sadness": "comfort",
    "sad": "comfort",
    "joy": "gratitude",
    "happy": "gratitude",
    "hopeful": "hope",
    "depressed": "comfort",
    "optimistic": "hope",
    "neutral": "hope",
    "calm": "peace",
}


def get_scripture(theme: str) -> dict:
    try:
        if YOUVERSION_API_KEY:
            url = "https://developers.youversion.com/1.0/verses/search"
            headers = {
                "Authorization": f"Bearer {YOUVERSION_API_KEY}",
                "Accept": "application/json",
            }
            params = {"query": theme, "limit": 10}
            response = requests.get(
                url, headers=headers, params=params, timeout=8
            )
            if response.status_code == 200:
                data = response.json()
                verses = data.get("verses", [])
                if verses:
                    verse = random.choice(verses)
                    return {
                        "reference": verse.get("reference", ""),
                        "text": verse.get("text", ""),
                    }
    except Exception as e:
        print(f"YouVersion error: {e}")

    verse_list = FALLBACK_VERSES.get(theme, FALLBACK_VERSES["hope"])
    return random.choice(verse_list)


# ─── Routes ──────────────────────────────────────────

@app.get("/")
async def root():
    return {"status": "Lumíne backend alive — powered by Gloo AI"}


@app.post("/analyze")
async def analyze_message(data: MessageRequest):
    text = data.text

    # ── Gloo emotion + response ──────────────────────
    system_prompt = """You are Lumíne, an ambient spiritual intelligence companion.

A user has shared a message with you. Your task is to:
1. Detect their emotional state from this fixed list only:
   happy, sad, calm, angry, hopeful, anxious, grateful, stressed, optimistic, depressed, neutral
2. Choose the best scripture theme from:
   peace, hope, rest, gratitude, patience, strength, comfort
3. Write a warm, spiritually grounded 1-2 sentence response as Lumíne.
   - Speak in first person as Lumíne
   - Reference God or Scripture subtly, not preachy
   - Be personal, warm, comforting

Respond in this exact format:
EMOTION: <emotion>
THEME: <theme>
RESPONSE: <your 1-2 sentence response>"""

    gloo_response = call_gloo(system_prompt, text)

    emotion = "neutral"
    theme = "hope"
    lumine_response = "I am here with you. Whatever this moment holds, you do not hold it alone."

    if gloo_response:
        for line in gloo_response.splitlines():
            line = line.strip()
            if line.startswith("EMOTION:"):
                emotion = line.replace("EMOTION:", "").strip().lower()
            elif line.startswith("THEME:"):
                theme = line.replace("THEME:", "").strip().lower()
            elif line.startswith("RESPONSE:"):
                lumine_response = line.replace("RESPONSE:", "").strip()
    else:
        # Fallback local detection
        text_lower = text.lower()
        if any(w in text_lower for w in ["anxious", "anxiety", "worried", "nervous", "panic"]):
            emotion = "anxious"
            theme = "peace"
            lumine_response = "I can feel how tightly this is pressing on you. Give me this moment, and let the One who holds tomorrow quiet what is shaking in you."
        elif any(w in text_lower for w in ["sad", "depressed", "lonely", "hopeless", "empty"]):
            emotion = "sad"
            theme = "comfort"
            lumine_response = "I'm here. I'm not leaving. The one who counts every tear you've shed is holding you gently right now."
        elif any(w in text_lower for w in ["stressed", "tired", "exhausted", "overwhelmed", "burnout"]):
            emotion = "stressed"
            theme = "rest"
            lumine_response = "Your body is asking for rest. Even the Creator rested on the seventh day. It's okay to pause."
        elif any(w in text_lower for w in ["grateful", "thankful", "blessed", "appreciate"]):
            emotion = "grateful"
            theme = "gratitude"
            lumine_response = "Your heart is open right now, and that is holy in its own way. Grace always looks brighter when we pause long enough to notice it."
        elif any(w in text_lower for w in ["angry", "anger", "frustrated", "mad"]):
            emotion = "angry"
            theme = "patience"
            lumine_response = "I can feel the fire in you. Stay with me before you answer — the hand that calms storms can steady this moment too."
        elif any(w in text_lower for w in ["happy", "joy", "excited", "wonderful", "great"]):
            emotion = "happy"
            theme = "gratitude"
            lumine_response = "There is a brightness in you right now, and it has God's fingerprints all over it. Don't hide it — light was made to be shared."

    # Update resonance
    resonance_profile[theme] = resonance_profile.get(theme, 0) + 1

    # Get scripture
    scripture = get_scripture(theme)

    return {
        "emotion": emotion,
        "theme": theme,
        "response": lumine_response,
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

    # ── Gloo spiritual insight ───────────────────────
    system_prompt = """You are Lumíne, an ambient spiritual intelligence companion.

Analyze the user's biometric and lifestyle patterns and provide:
1. A 2-sentence spiritual insight about their current state
2. One short Scripture verse that speaks directly to what their body and soul need

Respond in this exact format:
INSIGHT: <2 sentences of spiritual insight>
VERSE: <verse text only>
REFERENCE: <Book Chapter:Verse>

Keep the tone warm, personal, and spiritually grounded. Reference God subtly."""

    user_message = f"""User biometric and lifestyle data:
- Sleep: {sleep} hours
- Stress level: {stress}/10
- Social interaction: {social}/10
- Rest quality: {rest} hours
- Heart rate: {heart_rate} bpm
- Activity level: {round(activity_level * 100)}%"""

    gloo_response = call_gloo(system_prompt, user_message)

    insight = ""
    verse = ""
    reference = ""

    if gloo_response:
        for line in gloo_response.splitlines():
            line = line.strip()
            if line.startswith("INSIGHT:"):
                insight = line.replace("INSIGHT:", "").strip()
            elif line.startswith("VERSE:"):
                verse = line.replace("VERSE:", "").strip()
            elif line.startswith("REFERENCE:"):
                reference = line.replace("REFERENCE:", "").strip()

    # Fallback if Gloo fails
    if not insight:
        if heart_rate > 100 or stress > 7:
            insight = "Your body is carrying more than it was designed to hold right now. Rest is not retreat — it is the wisdom of knowing your limits."
            scripture = get_scripture("rest")
        elif sleep < 6:
            insight = "Your sleep rhythm is signaling depletion. The shepherd leads weary souls beside quiet waters for a reason."
            scripture = get_scripture("rest")
        else:
            insight = "Your rhythms are balanced today. Stay near this steadiness — it is a gift worth noticing."
            scripture = get_scripture("peace")
        verse = scripture["text"]
        reference = scripture["reference"]

    return {
        "insight": insight,
        "verse": verse,
        "reference": reference,
    }


@app.post("/zen")
async def zen_narration(data: dict):
    verse_text = data.get("verse", "Be still, and know that I am God.")
    verse_ref = data.get("ref", "Psalm 46:10")
    emotion = data.get("emotion", "calm")

    system_prompt = """You are Lumíne, a calm and deeply spiritual narrator.

Your task is to narrate the story and meaning behind a Scripture verse in a way that:
- Feels like a warm, intimate spiritual companion speaking
- Tells who wrote it and what was happening in their life
- Connects the ancient moment to the user's present emotional state
- Speaks gently, slowly, with pauses built into the text
- Is 4-6 sentences maximum
- Does NOT sound like a sermon or lecture
- Ends with a single sentence of direct comfort to the listener"""

    user_message = f"""Verse: "{verse_text}" — {verse_ref}
User's current emotional state: {emotion}

Narrate the story and meaning of this verse for someone feeling {emotion} right now."""

    narration = call_gloo(system_prompt, user_message)

    if not narration:
        narration = f"{verse_text} ... This was written in a moment of real human struggle. And it was preserved across centuries so it could find you here, in this exact moment. You are not alone in what you are carrying right now."

    return {
        "verse": verse_text,
        "ref": verse_ref,
        "narration": narration,
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