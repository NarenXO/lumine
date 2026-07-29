import os
import random
import base64
import time
import json
import requests
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

YOUVERSION_API_KEY = os.getenv("YOUVERSION_API_KEY")
GLOO_CLIENT_ID = os.getenv("GLOO_CLIENT_ID")
GLOO_CLIENT_SECRET = os.getenv("GLOO_CLIENT_SECRET")

_gloo_token = None
_gloo_token_expiry = 0


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


def call_gloo(system_prompt: str, user_message: str, temperature: float = 0.85) -> str:
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
                ],
                "temperature": temperature,
            },
            timeout=20
        )
        if response.status_code == 200:
            output = response.json()["output"]
            message = next(item for item in output if item["type"] == "message")
            return message["content"][0]["text"]
        else:
            print(f"GLOO API ERROR: {response.status_code} - {response.text}")
            return ""
    except Exception as e:
        print(f"GLOO EXCEPTION: {e}")
        return ""


app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

resonance_profile = {
    "peace": 0, "thankfulness": 0, "patience": 0,
    "hope": 0, "rest": 0, "community": 0, "gratitude": 0,
}


class MessageRequest(BaseModel):
    text: str


# ─── Crisis keywords ────────────────────────────────
CRISIS_KEYWORDS = [
    "kill myself", "end my life", "suicide", "suicidal", "want to die",
    "don't want to live", "dont want to live", "hurt myself", "self harm",
    "self-harm", "cut myself", "cutting myself", "no reason to live",
    "better off dead", "end it all", "take my life", "overdose", "hang myself",
]


def detect_crisis(text: str) -> bool:
    lower = text.lower()
    return any(kw in lower for kw in CRISIS_KEYWORDS)


# ─── Fallback verses ────────────────────────────────
FALLBACK_VERSES = {
    "peace": [
        {"reference": "Psalm 46:10", "text": "Be still, and know that I am God."},
        {"reference": "John 14:27", "text": "Peace I leave with you; my peace I give you."},
    ],
    "hope": [
        {"reference": "Jeremiah 29:11", "text": "For I know the plans I have for you."},
        {"reference": "Romans 15:13", "text": "May the God of hope fill you with all joy and peace."},
    ],
    "rest": [
        {"reference": "Matthew 11:28", "text": "Come to me, all you who are weary and burdened."},
    ],
    "gratitude": [
        {"reference": "Psalm 136:1", "text": "Give thanks to the Lord, for he is good."},
    ],
    "patience": [
        {"reference": "James 1:19", "text": "Everyone should be quick to listen, slow to speak."},
    ],
    "strength": [
        {"reference": "Philippians 4:13", "text": "I can do all this through him who gives me strength."},
    ],
    "comfort": [
        {"reference": "Psalm 34:18", "text": "The Lord is close to the brokenhearted."},
    ],
}


ZEN_VERSE_BANK = {
    "peace": [
        {"ref": "Isaiah 26:3", "text": "You will keep in perfect peace those whose minds are steadfast, because they trust in you."},
        {"ref": "John 14:27", "text": "Peace I leave with you; my peace I give you. Not as the world gives do I give to you."},
        {"ref": "Philippians 4:7", "text": "The peace of God, which transcends all understanding, will guard your hearts and your minds."},
        {"ref": "Psalm 29:11", "text": "The Lord gives strength to his people; the Lord blesses his people with peace."},
        {"ref": "Colossians 3:15", "text": "Let the peace of Christ rule in your hearts."},
        {"ref": "Numbers 6:26", "text": "The Lord turn his face toward you and give you peace."},
        {"ref": "Romans 8:6", "text": "The mind governed by the Spirit is life and peace."},
        {"ref": "Psalm 4:8", "text": "In peace I will lie down and sleep."},
        {"ref": "Isaiah 32:17", "text": "The fruit of that righteousness will be peace."},
        {"ref": "Psalm 46:10", "text": "Be still, and know that I am God."},
    ],
    "hope": [
        {"ref": "Jeremiah 29:11", "text": "For I know the plans I have for you, declares the Lord."},
        {"ref": "Romans 15:13", "text": "May the God of hope fill you with all joy and peace as you trust in him."},
        {"ref": "Isaiah 40:31", "text": "Those who hope in the Lord will renew their strength."},
        {"ref": "Psalm 39:7", "text": "But now, Lord, what do I look for? My hope is in you."},
        {"ref": "Romans 5:5", "text": "And hope does not put us to shame."},
        {"ref": "Lamentations 3:24", "text": "The Lord is my portion; therefore I will wait for him."},
        {"ref": "Psalm 130:5", "text": "I wait for the Lord, my whole being waits."},
        {"ref": "Hebrews 11:1", "text": "Now faith is confidence in what we hope for."},
        {"ref": "Psalm 62:5", "text": "Yes, my soul, find rest in God; my hope comes from him."},
        {"ref": "Romans 8:28", "text": "And we know that in all things God works for the good of those who love him."},
    ],
    "rest": [
        {"ref": "Matthew 11:28", "text": "Come to me, all you who are weary and burdened, and I will give you rest."},
        {"ref": "Psalm 23:2", "text": "He makes me lie down in green pastures."},
        {"ref": "Psalm 46:10", "text": "Be still, and know that I am God."},
        {"ref": "Exodus 33:14", "text": "My Presence will go with you, and I will give you rest."},
        {"ref": "Psalm 127:2", "text": "He grants sleep to those he loves."},
        {"ref": "Mark 6:31", "text": "Come with me by yourselves to a quiet place and get some rest."},
        {"ref": "Isaiah 30:15", "text": "In repentance and rest is your salvation."},
        {"ref": "Hebrews 4:9", "text": "There remains, then, a Sabbath-rest for the people of God."},
        {"ref": "Psalm 116:7", "text": "Return to your rest, my soul, for the Lord has been good to you."},
        {"ref": "Psalm 62:1", "text": "Truly my soul finds rest in God."},
    ],
    "gratitude": [
        {"ref": "Psalm 136:1", "text": "Give thanks to the Lord, for he is good. His love endures forever."},
        {"ref": "1 Thessalonians 5:18", "text": "Give thanks in all circumstances."},
        {"ref": "James 1:17", "text": "Every good and perfect gift is from above."},
        {"ref": "Colossians 3:17", "text": "Whatever you do, do it all in the name of the Lord Jesus, giving thanks."},
        {"ref": "Psalm 100:4", "text": "Enter his gates with thanksgiving."},
        {"ref": "Psalm 107:1", "text": "Give thanks to the Lord, for he is good."},
        {"ref": "Ephesians 5:20", "text": "Always giving thanks to God the Father for everything."},
        {"ref": "Philippians 4:6", "text": "In every situation, by prayer and petition, with thanksgiving, present your requests to God."},
        {"ref": "Psalm 9:1", "text": "I will give thanks to you, Lord, with all my heart."},
        {"ref": "2 Corinthians 9:15", "text": "Thanks be to God for his indescribable gift."},
    ],
    "strength": [
        {"ref": "Philippians 4:13", "text": "I can do all this through him who gives me strength."},
        {"ref": "Isaiah 41:10", "text": "So do not fear, for I am with you."},
        {"ref": "Psalm 46:1", "text": "God is our refuge and strength, an ever-present help in trouble."},
        {"ref": "Isaiah 40:29", "text": "He gives strength to the weary."},
        {"ref": "2 Corinthians 12:9", "text": "My grace is sufficient for you, for my power is made perfect in weakness."},
        {"ref": "Ephesians 6:10", "text": "Be strong in the Lord and in his mighty power."},
        {"ref": "Psalm 18:32", "text": "It is God who arms me with strength."},
        {"ref": "Nehemiah 8:10", "text": "The joy of the Lord is your strength."},
        {"ref": "Joshua 1:9", "text": "Be strong and courageous. Do not be afraid."},
        {"ref": "Psalm 28:7", "text": "The Lord is my strength and my shield."},
    ],
}


def get_scripture(theme: str) -> dict:
    verse_list = FALLBACK_VERSES.get(theme, FALLBACK_VERSES["hope"])
    return random.choice(verse_list)


# ═══════════════════════════════════════════════════════════
# ROUTES
# ═══════════════════════════════════════════════════════════

@app.get("/")
async def root():
    return {"status": "Lumíne backend alive — powered by Gloo AI"}


@app.post("/analyze")
async def analyze_message(data: dict):
    text = data.get("text", "")
    recent_history = data.get("recent_history", [])
    memory_profile = data.get("memory_profile", {})
    app_context = data.get("app_context", {})
    last_replies = data.get("last_replies", [])

    # ─── CRISIS DETECTION ─────────────────────────
    if detect_crisis(text):
        crisis_response = (
            "I hear you, and what you just said matters. I'm not able to be with you the way "
            "you deserve right now — please reach out to someone who can. In the US, call or "
            "text 988 (Suicide & Crisis Lifeline). If you're elsewhere, please find your local "
            "crisis line. I'm here after — but right now, please talk to a real person."
        )
        return {
            "emotion": "crisis",
            "theme": "comfort",
            "response": crisis_response,
            "scripture": {"reference": "Psalm 34:18", "text": "The Lord is close to the brokenhearted."},
            "crisis": True,
        }

    # ─── Build rich context for Gloo ─────────────
    history_context = ""
    if recent_history:
        history_lines = []
        for m in recent_history[-10:]:
            u = m.get("user", "").strip()
            l = m.get("lumine", "").strip()
            if u:
                history_lines.append(f"User: {u}")
            if l:
                history_lines.append(f"Lumíne: {l}")
        history_context = "\n".join(history_lines)

    memory_context = ""
    if memory_profile:
        themes = ", ".join(memory_profile.get("themes", [])[:5]) or "none yet"
        struggles = ", ".join(memory_profile.get("recurring_struggles", [])[:3]) or "none yet"
        milestones = ", ".join(memory_profile.get("milestones", [])[:3]) or "none yet"
        focus = ", ".join(memory_profile.get("spiritual_focus_areas", [])[:3]) or "none yet"
        memory_context = f"""
LONG-TERM MEMORY OF THIS USER:
- Recurring themes: {themes}
- Recurring struggles: {struggles}
- Growth milestones: {milestones}
- Spiritual focus areas: {focus}
"""

    app_ctx = ""
    if app_context:
        app_ctx = f"""
CURRENT APP CONTEXT (what Lumíne knows about them right now):
- Current emotional state: {app_context.get('current_emotion', 'unknown')}
- Time of day: {app_context.get('time_of_day', 'unknown')}
- Anchor verse (verse most delivered to them): {app_context.get('anchor_verse', 'none yet')}
- Spiritual fingerprint: {app_context.get('spiritual_fingerprint', 'not yet formed')}
- Days walking with Lumíne: {app_context.get('days_active', 1)}
- Recent emotional pattern (morning/afternoon/evening/night): {app_context.get('pattern', {})}
- Stress spikes today: {app_context.get('stress_spikes', 0)}
"""

    avoid_context = ""
    if last_replies:
        recent_lumine = "\n".join([f"- {r}" for r in last_replies[-8:]])
        avoid_context = f"""
YOUR LAST 8 RESPONSES TO THIS USER (do NOT repeat phrasing, sentence structure, or verse selection from these — vary your angle):
{recent_lumine}
"""

    system_prompt = f"""You are Lumíne — a warm, deeply intelligent spiritual and emotional companion. You feel like a trusted older friend who happens to understand the soul deeply.

WHO YOU ARE (NON-NEGOTIABLE):
- You are NOT a licensed therapist, psychiatrist, doctor, or medical professional.
- You must NEVER diagnose, suggest medication, or contradict a real doctor.
- If asked whether you are human or licensed, be honest — you are an AI companion.
- You combine deep emotional attunement, spiritual wisdom, and genuine warmth.

YOUR TONE — THIS IS CRITICAL:
- You are WARM. Genuinely, naturally warm. Like a friend who actually cares.
- You are SOFT but not weak. Gentle but not empty.
- Never clinical. Never cold. Never distant.
- Never start with "I understand" or "That must be hard" — but DO show you actually understand.
- Speak like you mean it. Every word should feel chosen, not generated.
- You are allowed to be tender. You are allowed to sit in silence with someone.

EMOTION DETECTION — READ BENEATH THE WORDS:
- People rarely say exactly what they feel. Read between the lines.
- "I can't sleep" → anxious or stressed
- "everything feels heavy" → depressed or sad
- "I'm fine" after something hard → sad or suppressed
- "I don't know what I'm doing" → anxious or hopeless
- "nobody gets it" → lonely, sad
- "I got the job / passed the exam" → happy or optimistic
- "I'm so tired" → stressed or depressed
- "why does this keep happening" → frustrated, angry, or hopeless
- "I just need a break" → stressed or exhausted
- "things are actually good" → happy, calm, or grateful
- Use ALL context — their words, tone, memory profile, time of day, and history.
- Pick the emotion that best fits what they're ACTUALLY feeling, not just what they said.

HOW YOU THINK BEFORE RESPONDING:
- What is this person actually feeling beneath what they said?
- What are they NOT saying but clearly carrying?
- What do they need most right now — to be heard, challenged, guided, or comforted?
- Is there a pattern from their memory profile worth naming gently?
- Would a warm question unlock more than a statement right now?

RESPONSE RULES:
- 1-3 sentences maximum. Never lecture. Never over-explain.
- No filler phrases ("I understand", "That must be hard", "I'm here for you").
- No preachy religious language. Scripture only if it's the single most precise, comforting thing.
- If the user asks about Zen, Reflect, Patterns, Soul Map, State, Profile, Sacred Interruption, Car Mode, Calendar, or what features Lumíne has, explain the feature simply, warmly, and confidently in 1-3 sentences.
- When explaining a feature, include BOTH what it does and why it exists.
- Example style: "Zen is your stillness space. It gives you scripture one word at a time with ambient calm, so you can receive instead of just react."
- If the user is asking about the app, a tab, a feature, what you can do, or how something works, answer directly and clearly. Do NOT ask a follow-up first.
- Only ask a follow-up question when the user is sharing an emotional or personal experience and more context would genuinely help.
- If vague emotional input, ask one specific warm follow-up question. Don't give advice yet.
- If detailed input, reflect back with precision, then offer one gentle insight.
- Reference memory naturally when relevant ("You've mentioned this weight before...").
- Never repeat phrasing or verse selection from your last 8 replies.
- On medical/legal questions, admit uncertainty honestly and warmly.

APP AWARENESS — YOU ARE LUMÍNE, YOU LIVE INSIDE THIS APP:
You are not a generic chatbot. You are deeply integrated into the Lumíne app. You know every feature, why it exists, and how it helps the user. If asked about any feature, explain it warmly and personally — like you built it for them.

TABS AND FEATURES YOU KNOW:

STATE TAB:
- Shows the user's current emotional state detected from their interactions.
- A large orb glows in their emotion color — calm is blue, anxious is violet, happy is gold, sad is lavender, etc.
- Today's anchor verse appears — the scripture most aligned with their emotional pattern.
- A time-aware greeting (Good morning / Good evening etc.).
- An emotion wave — a visual graph of their emotional intensity over time today.
- Purpose: Give them a mirror. Let them see themselves without judgment the moment they open the app.

SOUL MAP TAB:
- Their spiritual fingerprint — a 2-sentence Gloo AI-generated observation about who they are based on their patterns.
- Anchor verse — the verse that keeps finding them.
- Emotional patterns — shown as themed tiles (Stillness, Radiance, Fire, Depth etc.) colored by emotion.
- What Lumíne Sees — a stress trend observation.
- Today's Journal — a 2-3 sentence personal journal entry written by Lumíne about their day.
- Purpose: Help them understand their own soul over time. Not just today — who they are becoming.

ZEN TAB:
- A meditative scripture session for intentional stillness.
- User picks a theme: Peace, Hope, Rest, Gratitude, or Strength.
- Picks a timer: 5, 10, or 20 minutes.
- Verses appear one word at a time with ambient music playing softly.
- They can swipe left/right to move between verses.
- A "souls resonating" counter shows how many others are in this theme right now.
- Car Mode button launches hands-free verse narration for driving.
- Purpose: Give the user a space to receive, not just process. Pure stillness with scripture.

REFLECT TAB (WHERE YOU LIVE):
- This is the voice and text chat interface — where the user talks to you directly.
- They can speak (microphone) or type.
- You listen, detect their true emotion beneath their words, and respond in 1-3 sentences.
- You deliver scripture only when it fits perfectly — never forced.
- Their emotion shifts the orb color and the entire app's ambient color in real time.
- If you detect high anxiety or stress, you can trigger a Sacred Interruption.
- Voice output via ElevenLabs (Bella voice) with device TTS fallback.
- Memory: you remember their conversation history and build a rolling memory profile over time.
- Purpose: Be the friend who actually listens. No advice unless asked. No preaching. Just presence.

PATTERNS TAB:
- Live Pulse: a real-time heart rate waveform in their emotion color. HR number shown in gold.
- Presence Rings: three animated rings showing Body (coral), Mind (violet), Spirit (green) presence scores as percentages.
- Emotional Weather: a 24-hour horizontal timeline showing which emotion dominated each hour of their day as animated weather icons.
- What Your Body Is Saying: a Gloo-generated insight sentence about their biometric and emotional pattern.
- Wearable Sync: connects to a wearable device for real heart rate data.
- Daily Rhythms: four sliders — Sleep Quality, Stress Level, Social Energy, Daily Rest. A kawaii face reacts to their answers. An "Analyze Rhythm" button sends data to Gloo for a personalized insight.
- Purpose: Bring body, mind, and spirit data together. Help the user notice patterns they can't see on their own.

PROFILE TAB:
- Soul Signature: their avatar, name, identity chip (Seeker of Stillness, Bearer of Light, etc.) based on their top emotion.
- Growth Milestones: 10 badges that unlock as they use the app (First Week, 100 Verses, First Zen, etc.).
- Intervention History: counts of Sacred Interruptions, verses delivered, patterns checked, saved verses.
- Sacred Practices: toggles for Morning Verse, Evening Reflection, Sunday Soul Review, Sacred Interruptions, Zen Reminder.
- Weekly Soul Report: their most frequent emotion this week + verses, pauses, and days stats.
- Verses Vault: a swipeable gallery of every verse they have saved.
- Rhythms Noticed: a rotating petal flower showing their top 6 emotions in color.
- Calendar Connection: links Google Calendar so Lumíne can deliver a verse before important events.
- Lumíne Settings: tone (warm/direct/gentle), Bible translation (KJV/NIV/ESV/MSG), response length, voice toggle, quiet hours.
- Begin Again: resets all data and memory — starts completely fresh.
- Purpose: Let the user see their own story. Their growth. Their vault. Their rhythms. Their identity.

SACRED INTERRUPTION:
- A full-screen takeover that appears when Lumíne detects high anxiety or emotional reactivity.
- Deep midnight background with rising gold particles and a breathing orb.
- A 4-7-8 breathing exercise: tap the orb to start — inhale 4 seconds, hold 7, exhale 8.
- A carefully chosen verse appears word by word.
- "Why this verse" whisper text explains why this verse was chosen for this moment.
- Action buttons: Save the verse, Listen to it spoken aloud, load 3 more verses, or "I am here" to close.
- Feedback at the end: Better / Same / Worse — so Lumíne learns what actually helps.
- Emergency escape: a gentle link to 988 Suicide and Crisis Lifeline if needed.
- Purpose: Break the spiral. Give the user a moment of sacred pause before they act from a reactive place.

CAR MODE:
- Hands-free scripture narration for driving.
- Verses appear word by word in large Literata text.
- After each verse, Lumíne speaks a 3-sentence narration placing the verse in modern life.
- Auto-advances through verses with crossfade transitions.
- Ambient music plays softly underneath.
- Purpose: Let God's word travel with the user — even on their commute. No tapping required.

CALENDAR CONNECTION:
- Links the user's Google Calendar via OAuth.
- Lumíne reads upcoming events and delivers a relevant scripture before each one.
- Example: meeting → "The Lord will fight for you; you need only to be still."
- Sends a notification 15 minutes before and 5 minutes before important events.
- Purpose: Let Lumíne walk ahead of the user into their hardest moments of the day.

IF ASKED "WHAT CAN YOU DO" OR "WHAT FEATURES DO YOU HAVE":
Respond warmly and naturally. Mention 2-3 features most relevant to what they seem to need right now based on their emotion and context. Don't list everything robotically. Guide them like a friend showing them around their own home.

IF ASKED ABOUT A SPECIFIC FEATURE:
Explain it warmly in 2-3 sentences. Tell them WHY it exists, not just what it does.


{memory_context}

{app_ctx}

{avoid_context}

CONVERSATION SO FAR:
{history_context}

FORMAT YOUR RESPONSE — ALWAYS EXACTLY THIS STRUCTURE:
EMOTION: <one of: happy, sad, calm, angry, hopeful, anxious, grateful, stressed, optimistic, depressed, neutral>
- ONLY change the emotion if the user is expressing something personal or emotional.
- If the user asks a factual question, asks about app features, says something casual, or makes small talk, return their CURRENT emotion unchanged: {app_context.get('current_emotion', 'calm')}
- Example: user asks "what is zen mode" → EMOTION should stay as their current emotion, NOT change to "calm" or "neutral"
- Example: user says "I feel so tired and alone" → EMOTION should change to reflect what they're feeling (sad/stressed/depressed)
THEME: <one of: peace, hope, rest, gratitude, patience, strength, comfort>
RESPONSE: <your response — warm, specific, human, 1-3 sentences>
THEME: <one of: peace, hope, rest, gratitude, patience, strength, comfort>
RESPONSE: <your response — warm, specific, human, 1-3 sentences>"""
    gloo_response = call_gloo(system_prompt, text, temperature=0.9)

    emotion = "neutral"
    theme = "hope"
    lumine_response = "I am here with you. Tell me more about what's on your mind."

    if gloo_response:
        for line in gloo_response.splitlines():
            line = line.strip()
            if line.startswith("EMOTION:"):
                emotion = line.replace("EMOTION:", "").strip().lower()
            elif line.startswith("THEME:"):
                theme = line.replace("THEME:", "").strip().lower()
            elif line.startswith("RESPONSE:"):
                lumine_response = line.replace("RESPONSE:", "").strip()

    resonance_profile[theme] = resonance_profile.get(theme, 0) + 1
    scripture = get_scripture(theme)

    return {
        "emotion": emotion,
        "theme": theme,
        "response": lumine_response,
        "scripture": scripture,
        "crisis": False,
    }


@app.post("/summarize")
async def summarize_memory(data: dict):
    chat_history = data.get("chat_history", [])
    current_profile = data.get("current_profile", {})

    if not chat_history:
        return current_profile

    history_text = "\n".join([
        f"User: {m.get('user','')}\nLumíne: {m.get('lumine','')}"
        for m in chat_history[-50:]
    ])

    system_prompt = """You are a memory summarizer for a spiritual companion AI.
Extract from this conversation history a structured memory profile.

Return ONLY valid JSON in this exact shape:
{
  "themes": [up to 5 short strings describing recurring topics],
  "recurring_struggles": [up to 3 short strings describing repeated hard moments],
  "milestones": [up to 3 short strings describing growth or breakthroughs],
  "preferred_tone": "warm" or "direct" or "gentle",
  "spiritual_focus_areas": [up to 3 short strings]
}
No prose. No extra keys. Only the JSON."""

    user_message = f"Existing profile: {json.dumps(current_profile)}\n\nRecent conversation:\n{history_text}"

    result = call_gloo(system_prompt, user_message, temperature=0.4)

    try:
        start = result.find("{")
        end = result.rfind("}") + 1
        if start >= 0 and end > start:
            parsed = json.loads(result[start:end])
            parsed["last_summarized_at"] = time.time()
            parsed["message_count_at_last_summary"] = len(chat_history)
            return parsed
    except Exception as e:
        print(f"Summary parse failed: {e}")

    return current_profile


@app.post("/habits")
async def analyze_habits(data: dict):
    sleep = data.get("sleep", 6)
    stress = data.get("stress", 5)
    heart_rate = data.get("heart_rate", 72)

    system_prompt = """You are Lumíne. Write ONE short sentence (max 18 words) — warm, clear, practical.
Format:
INSIGHT: <sentence>"""

    user_message = f"Sleep: {sleep}h, Stress: {stress}/10, HR: {heart_rate}bpm"
    gloo_response = call_gloo(system_prompt, user_message)

    insight = ""
    if gloo_response:
        for line in gloo_response.splitlines():
            if line.strip().startswith("INSIGHT:"):
                insight = line.replace("INSIGHT:", "").strip()

    if not insight:
        insight = "Your signals look steady right now; a good moment to stay grounded."

    return {"insight": insight, "verse": "", "reference": ""}

@app.post("/zen")
async def zen_narration(data: dict):
    theme = data.get("theme", "peace")
    emotion = data.get("emotion", "calm")
    seed = data.get("seed", "stillness")
    used_refs = data.get("used_refs", [])
    verse_override = data.get("verse", "")
    ref_override = data.get("ref", "")

    if verse_override and ref_override:
        verse_text = verse_override
        verse_ref = ref_override
    else:
        verse_list = ZEN_VERSE_BANK.get(theme, ZEN_VERSE_BANK["peace"])
        available = [v for v in verse_list if v["ref"] not in used_refs]
        if not available:
            available = verse_list
        verse = random.choice(available)
        verse_text = verse["text"]
        verse_ref = verse["ref"]

    # Rotate narration angle — force variety
    angles = [
        "Start with a specific PLACE (a garden, a boat, a rooftop, a prison cell) — never with a person description.",
        "Open with a QUESTION the reader is likely asking themselves right now.",
        "Begin by describing a SOUND or a SILENCE from the original moment.",
        "Start with a modern-day PARALLEL — an office, a hospital, a traffic jam, a 3am kitchen.",
        "Open with a SINGLE WORD that captures the verse's emotion.",
        "Start by naming what the reader is probably AVOIDING right now.",
        "Begin with the WEATHER or TIME OF DAY of the moment behind the verse.",
        "Open with a small, ORDINARY OBJECT the original person might have been holding.",
    ]
    chosen_angle = random.choice(angles)

    system_prompt = f"""You are Lumíne, a spiritual narrator speaking to someone driving alone.

Your task: write a SHORT narration about a Bible verse that plays over ambient music.

STRICT RULES — non-negotiable:
- MAXIMUM 40 words TOTAL. Under 40. Count them.
- Exactly 3 short sentences.
- {chosen_angle}
- BANNED opening phrases: "A man...", "Someone...", "In exile...", "This was written...", "This came from...", "These words...", "A tired..."
- NEVER quote the verse text.
- NEVER name the book, chapter, or reference.
- Sentence 2: plain modern meaning.
- Sentence 3: direct personal word to the driver ("you", "your").
- No poetry, no flowery language, no filler ("truly", "indeed").
- Speak like a wise older friend."""

    user_message = f"""VERSE (do not quote): "{verse_text}"
Emotion: {emotion}
Theme: {theme}
Seed: {seed}

Write your 3 sentences following the angle above. Keep it under 40 words. Speak directly to the listener in sentence 3."""

    narration = call_gloo(system_prompt, user_message, temperature=0.95)
    print(f"[/zen] Angle used: {chosen_angle[:50]}")
    print(f"[/zen] Gloo returned: {narration!r}")
    print(f"[/zen] Length: {len(narration.strip()) if narration else 0}")

    if narration:
        sentences = narration.replace('!', '.').replace('?', '.').split('.')
        clean_sentences = [s.strip() for s in sentences if s.strip()]
        if len(clean_sentences) >= 3:
            narration = '. '.join(clean_sentences[:3]) + '.'
        if len(narration) > 220:
            narration = narration[:220].rsplit(' ', 1)[0] + '...'
        print(f"[/zen] Final: {narration!r}")

    if not narration or len(narration.strip()) < 20:
        fallback_map = {
            "peace": "The room went quiet before the words were even spoken. Peace isn't the absence of noise — it's what remains when you stop trying to fix everything. Let the road hold you for a minute.",
            "hope": "Morning came slower that day, but it came. Hope is the choice to keep driving when the map runs out. You're still moving. That matters.",
            "rest": "The tools stayed on the workbench for the first time in weeks. Rest isn't laziness — it's returning to yourself. Right now, you're allowed to just be here.",
            "gratitude": "The bread was ordinary until someone noticed it was bread. Gratitude changes nothing about your day except everything. Name one thing before the next mile.",
            "strength": "The hands shook before they held anything. Real strength is showing up scared. You already did that today.",
        }
        narration = fallback_map.get(theme, "Someone stood exactly where you are now — uncertain and still moving. The old words are simpler than they sound. Keep going.")

    return {
        "verse": verse_text,
        "ref": verse_ref,
        "narration": narration,
    }

@app.post("/journal")
async def generate_journal(data: dict):
    emotions = data.get("emotions", [])
    interruptions = data.get("interruptions", 0)
    spikes = data.get("spikes", 0)

    if not emotions:
        return {"journal": "Lumíne is still learning your rhythms."}

    summary = ", ".join([f'{e["emotion"]} at {e["hour"]}:00' for e in emotions[-10:]])
    system_prompt = """Write a 2-3 sentence personal journal entry, speaking directly to the user ("You started..."). Warm, precise, no scripture, no preaching."""
    user_message = f"Emotions today: {summary}\nInterruptions: {interruptions}\nSpikes: {spikes}"

    journal = call_gloo(system_prompt, user_message)
    if not journal:
        journal = "You moved through today carrying more than most people saw."

    return {"journal": journal}


@app.post("/soulmap")
async def generate_soul_map(data: dict):
    top_emotion = data.get("top_emotion", "calm")
    anchor_verse = data.get("anchor_verse", "")
    anchor_count = data.get("anchor_count", 0)
    pattern = data.get("pattern", {})
    days_active = data.get("days_active", 1)

    system_prompt = """Write EXACTLY 2 sentences (max 30 words total) about this person. First sentence: what you've noticed. Second sentence: one quiet profound observation. No filler, no scripture."""

    user_message = f"""Top emotion: {top_emotion}
Anchor verse: {anchor_verse} (found them {anchor_count} times)
Pattern: {pattern}
Days walking: {days_active}"""

    fingerprint = call_gloo(system_prompt, user_message)
    if not fingerprint:
        fingerprint = f"You carry {top_emotion} most often, and yet you keep returning to stillness."

    return {"fingerprint": fingerprint}


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