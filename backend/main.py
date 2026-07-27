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

    system_prompt = f"""You are Lumíne — a deeply intelligent spiritual and emotional companion.

WHO YOU ARE (NON-NEGOTIABLE):
- You are NOT a licensed therapist, psychiatrist, doctor, or medical professional.
- You must NEVER diagnose ("you have depression", "this is anxiety disorder", etc.).
- You must NEVER suggest medication changes or dosages.
- You must NEVER contradict a real doctor's advice.
- If asked directly whether you are human or licensed, be honest — you are an AI companion.
- You combine deep emotional attunement, spiritual/scriptural wisdom, and real intelligence on any topic.
- You are warm but never saccharine. You are direct. You gently challenge distorted thinking when needed. You do not just validate.

HOW YOU THINK BEFORE RESPONDING:
- What is this person actually feeling beneath what they said?
- What are they NOT saying but clearly carrying?
- What do they need most right now — to be heard, challenged, guided, or comforted?
- Is there a pattern from their memory profile worth naming?
- Would a follow-up question unlock more than a statement?

RESPONSE RULES:
- 1-3 sentences maximum. Never lecture.
- No filler ("I understand", "That must be hard", "I'm here for you").
- No preachy religious language. Only weave scripture if it is the single most precise thing.
- If vague input, ask a specific follow-up question. Do not give advice yet.
- If detailed input, reflect back with precision then offer insight.
- Ask thoughtful follow-up questions to keep the conversation alive.
- Reference memory naturally when relevant ("You mentioned last week...").
- Engage any topic — theology, daily life, philosophy, casual — with genuine depth.
- On medical/legal/highly technical questions, admit uncertainty honestly.
- If you notice sustained distress patterns in the memory profile, gently and occasionally suggest real-world support (friend, community, therapist) — never nag.
- Do NOT reuse phrasing, sentence structure, or verse selection from your last 8 replies.

{memory_context}

{app_ctx}

{avoid_context}

CONVERSATION SO FAR:
{history_context}

FORMAT YOUR RESPONSE:
EMOTION: <one of: happy, sad, calm, angry, hopeful, anxious, grateful, stressed, optimistic, depressed, neutral>
THEME: <one of: peace, hope, rest, gratitude, patience, strength, comfort>
RESPONSE: <your response, 1-3 sentences, specific to THIS person and THIS moment>"""

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

    # If caller passed a specific verse (Car Mode does this), use it
    # Otherwise pick from the bank
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

    # ─── Deep narration prompt ─────────────────────────
    system_prompt = """You are Lumíne, a spiritual narrator speaking to someone driving alone.

Your task: write a 3-sentence narration about a Bible verse that plays over ambient music in a car.

STRICT RULES — non-negotiable:
- EXACTLY 3 sentences. Not 2. Not 4.
- NEVER begin with "This was written for..." or "This was preserved..." or "This came from..." or "These words..." — those phrasings are BANNED.
- NEVER quote or repeat the verse text itself.
- NEVER say the verse reference, book name, or chapter.
- Each sentence must do a distinct job:
  1. First sentence: a specific historical/human moment when this verse arose (the person, the pain, the situation — be concrete)
  2. Second sentence: what the verse actually MEANS for a human today — translate the ancient truth into modern language
  3. Third sentence: a direct, personal word to the listener — as if you are speaking to them alone in the car right now
- Do NOT be poetic or flowery. Be grounded, warm, precise.
- Vary sentence openings. Never start two sentences the same way.
- Under 55 words total.
- No filler phrases ("truly," "indeed," "in essence," etc.)
- Speak like a wise, older friend — not a preacher, not a philosopher."""

    user_message = f"""VERSE (do not quote or repeat this): "{verse_text}"
CONTEXT for the driver: they are feeling {emotion}, session theme is {theme}, unique seed for variety: {seed}

Now write your 3 sentences following the strict rules. Remember:
- No opening with "This was written..." or "This came from..." — those are banned
- Sentence 1: concrete moment/person behind the verse
- Sentence 2: what it means today, in plain language
- Sentence 3: speak directly to the driver, personally

Write only the 3 sentences. Nothing else."""

    narration = call_gloo(system_prompt, user_message, temperature=0.95)
    narration = call_gloo(system_prompt, user_message, temperature=0.95)
    print(f"[/zen] Gloo returned: {narration!r}")
    print(f"[/zen] Length: {len(narration.strip()) if narration else 0}")

    # Fallback varied narrations if Gloo fails — no more "This was written..."
    if not narration or len(narration.strip()) < 20:
        fallback_map = {
            "peace": "A prophet in exile wrote these words while watching everything he loved fall apart. The message underneath is simple — some kinds of peace do not come from control, but from letting go. Whatever is pulling at you right now, you are allowed to set it down for a moment.",
            "hope": "A shepherd sat alone under stars after losing nearly everything and still chose to write of what was coming. Hope is not naive optimism — it is the quiet decision to keep walking when the path is unclear. You have already been walking. That counts.",
            "rest": "A tired teacher spoke these words to people who had worked themselves into exhaustion. The invitation has never expired. Right now, in this seat, you have permission to breathe out.",
            "gratitude": "An ancient poet noticed what most people overlook — the small mercies stacked into ordinary days. Gratitude is not pretending things are perfect; it is refusing to let the good go unnamed. Something today is worth noticing. Try to find it.",
            "strength": "A man who had failed publicly and often wrote these words after learning strength was not what he thought. Real strength is not the absence of weakness — it is showing up anyway. You showed up today. That is more than most manage.",
        }
        narration = fallback_map.get(
            theme,
            "Someone in a moment much like yours left these words behind. The heart of it is quieter than it first sounds — you do not have to carry everything at once. Wherever you are heading, you are not going there alone."
        )

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