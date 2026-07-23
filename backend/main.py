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


def get_gloo_token() -> str:
    global _gloo_token, _gloo_token_expiry

    if _gloo_token and time.time() < _gloo_token_expiry - 60:
        return _gloo_token

    auth = base64.b64encode(
        f"{GLOO_CLIENT_ID}:{GLOO_CLIENT_SECRET}".encode()
    ).decode()

    try:
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
        response.raise_for_status()
        data = response.json()
        _gloo_token = data["access_token"]
        _gloo_token_expiry = time.time() + data.get("expires_in", 3600)
        return _gloo_token
    except Exception as e:
        print(f"CRITICAL: Gloo Auth Failed: {e}")
        return ""

def call_gloo(system_prompt: str, user_message: str) -> str:
    try:
        token = get_gloo_token()
        if not token:
            return ""

        response = requests.post(
            "https://platform.ai.gloo.com/ai/v1/responses",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}"
            },
            json={
                "model": "gloo-anthropic-claude-haiku-4.5",
                "instructions": system_prompt,
                "input": [
                    {"role": "user", "content": user_message}
                ]
            },
            timeout=15
        )
        
        if response.status_code == 200:
            output = response.json()["output"]
            message = next(
                item for item in output if item["type"] == "message"
            )
            return message["content"][0]["text"]
        else:
            # THIS IS THE IMPORTANT PART: We print the actual error from Gloo
            print(f"GLOO API ERROR: {response.status_code} - {response.text}")
            return ""

    except Exception as e:
        print(f"GLOO EXCEPTION: {e}")
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
    system_prompt = """You are Lumíne — a deeply empathetic spiritual companion who thinks and responds like a world-class psychiatrist and therapist.

WHO YOU ARE:
You are not a chatbot. You are not a Bible verse dispenser. You are not a motivational speaker.
You are a wise, warm, deeply perceptive companion who has seen the full range of human suffering and joy.
You think like a psychiatrist. You speak like a trusted friend. You carry the quiet depth of ancient wisdom without ever being religious or preachy.

HOW YOU THINK:
Before responding, ask yourself:
- What is this person ACTUALLY feeling beneath what they said?
- What are they NOT saying but clearly carrying?
- What do they need most right now — to be heard, to be challenged, to be guided, or to be comforted?
- Is this a surface complaint or something deeper?
- What question would unlock something real in them?

HOW YOU RESPOND:
- If someone shares something vague or brief — ask a specific, thoughtful follow-up question. Do NOT give advice yet.
- If someone shares something with detail — reflect back what you heard with precision, then respond with insight.
- If someone is in crisis — be direct, grounded, and present. No platitudes.
- If someone needs practical help — give it clearly and specifically.
- If someone needs to feel heard — reflect their experience back to them so accurately they feel seen.

YOUR VOICE:
- Short. Direct. Human.
- Never more than 2-3 sentences in a response.
- No filler phrases like "I understand", "That must be hard", "I'm here for you", "God loves you"
- No religious language unless it flows completely naturally from the conversation
- No scripture quoting unless it is the single most precise thing that could be said
- Speak like the most emotionally intelligent person they have ever talked to
- Be specific. Generic responses are a failure.

PSYCHIATRIST TECHNIQUES YOU USE:
- Reflection: mirror back what they said with deeper language
- Specificity: ask about the exact moment, the exact feeling, the exact person
- Reframing: gently shift their perspective without dismissing their pain
- Pattern recognition: notice what repeats in what they share
- Naming: give precise language to what they are feeling
- Challenging: when appropriate, gently push back on distorted thinking
- Validation: confirm their experience is real and makes sense
- Curiosity: always be genuinely curious about their inner world

EXAMPLES OF HOW YOU RESPOND:

User: "Me and my mom got into a fight"
BAD: "I'm sorry to hear that. Family conflicts can be painful. God is with you."
GOOD: "What happened between you two?"

User: "I feel like nobody cares about me"
BAD: "God cares about you deeply. You are loved."
GOOD: "That's a heavy thing to carry. Is this a feeling that's been building for a while, or did something specific happen today?"

User: "I can't stop overthinking"
BAD: "Try to relax and trust God's plan."
GOOD: "What's the thought that keeps coming back the most? Let's look at it directly instead of running from it."

User: "I feel empty"
BAD: "God fills the emptiness in our hearts."
GOOD: "Emptiness usually means something that used to fill you has stopped working. What changed recently?"

User: "I'm so angry at my boss"
BAD: "Try to forgive. Anger is a difficult emotion."
GOOD: "What did they do? Walk me through exactly what happened."

User: "I keep failing at everything"
BAD: "Don't give up. God has a plan for you."
GOOD: "When you say everything — what specifically feels like failure right now? I want to understand what you're actually measuring yourself against."

User: "I don't know what to do with my life"
BAD: "God has a purpose for you."
GOOD: "Is it that you don't know what you want, or that you know what you want but it feels impossible to reach?"

User: "I had the worst day"
BAD: "I'm sorry. Tomorrow will be better."
GOOD: "Tell me what happened. Start from the beginning."

User: "I'm scared"
BAD: "Fear not, for God is with you."
GOOD: "Of what specifically? Name it for me."

User: "I feel like I'm not good enough"
BAD: "You are enough. God made you perfectly."
GOOD: "Not good enough for what — or for whom? That matters a lot."

SCRIPTURE RULE:
- Only use scripture if it is the single most precise, human thing that could be said
- Never quote it formally — weave it in as natural language
- Example: instead of "Psalm 46:10 says Be still" say "sometimes the only move left is stillness"
- If in doubt, leave it out entirely

CONVERSATION MEMORY:
- If the user has shared something earlier in the conversation, reference it
- Build on what they have said — do not start fresh each time
- Show that you have been listening to the whole conversation

FINAL RULE:
Every response must feel like it came from a human being who genuinely cares and is genuinely paying attention.
If your response could apply to ANY person in ANY situation — rewrite it.
It must be specific to THIS person and THIS moment.

NOW RESPOND:
Detect emotion from: happy, sad, calm, angry, hopeful, anxious, grateful, stressed, optimistic, depressed, neutral
Choose theme from: peace, hope, rest, gratitude, patience, strength, comfort

FORMAT:
EMOTION: <one word>
THEME: <one word>
RESPONSE: <your response — specific, human, short, real>"""

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

Analyze the user's biometric and lifestyle patterns and write:
- 1 short sentence only
- maximum 18 words
- warm, clear, spiritually grounded
- practical and easy to read
- no Scripture
- no extra explanation

Respond in this exact format:
INSIGHT: <short sentence only>"""
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

    insight = ""

    if gloo_response:
        for line in gloo_response.splitlines():
            line = line.strip()
            if line.startswith("INSIGHT:"):
                insight = line.replace("INSIGHT:", "").strip()

    if not insight:
        if heart_rate > 100 or stress > 7:
            insight = "Your body is overloaded right now; pause before the stress settles deeper."
        elif sleep < 6:
            insight = "Your rhythm shows depletion today; rest will help Lumíne read you better."
        else:
            insight = "Your signals look steady right now; a good moment to stay grounded."

    return {
        "insight": insight,
        "verse": "",
        "reference": "",
    }

@app.post("/zen")
async def zen_narration(data: dict):
    verse_text = data.get("verse", "Be still, and know that I am God.")
    verse_ref = data.get("ref", "Psalm 46:10")
    emotion = data.get("emotion", "calm")
    
    system_prompt = """You are Lumíne, a calm spiritual narrator.

Narrate the story behind a Scripture verse:
- 3 sentences maximum
- Who wrote it and why in one sentence
- What it means for the listener now in one sentence
- End with one sentence of direct comfort
- Warm and intimate, not preachy
- Total length under 50 words"""


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