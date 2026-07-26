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


# ─── Zen Verse Bank ───────────────────────────────────
ZEN_VERSE_BANK = {
    "peace": [
        {"ref": "Isaiah 26:3", "text": "You will keep in perfect peace those whose minds are steadfast, because they trust in you."},
        {"ref": "John 14:27", "text": "Peace I leave with you; my peace I give you. Not as the world gives do I give to you."},
        {"ref": "Philippians 4:7", "text": "The peace of God, which transcends all understanding, will guard your hearts and your minds."},
        {"ref": "Psalm 29:11", "text": "The Lord gives strength to his people; the Lord blesses his people with peace."},
        {"ref": "Colossians 3:15", "text": "Let the peace of Christ rule in your hearts, since as members of one body you were called to peace."},
        {"ref": "Numbers 6:26", "text": "The Lord turn his face toward you and give you peace."},
        {"ref": "Romans 8:6", "text": "The mind governed by the Spirit is life and peace."},
        {"ref": "Psalm 4:8", "text": "In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety."},
        {"ref": "Isaiah 32:17", "text": "The fruit of that righteousness will be peace; its effect will be quietness and confidence forever."},
        {"ref": "2 Thessalonians 3:16", "text": "Now may the Lord of peace himself give you peace at all times and in every way."},
        {"ref": "Psalm 46:10", "text": "Be still, and know that I am God."},
        {"ref": "Romans 5:1", "text": "Since we have been justified through faith, we have peace with God through our Lord Jesus Christ."},
    ],
    "hope": [
        {"ref": "Jeremiah 29:11", "text": "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you."},
        {"ref": "Romans 15:13", "text": "May the God of hope fill you with all joy and peace as you trust in him."},
        {"ref": "Isaiah 40:31", "text": "Those who hope in the Lord will renew their strength. They will soar on wings like eagles."},
        {"ref": "Psalm 39:7", "text": "But now, Lord, what do I look for? My hope is in you."},
        {"ref": "Romans 5:5", "text": "And hope does not put us to shame, because God's love has been poured out into our hearts."},
        {"ref": "Lamentations 3:24", "text": "The Lord is my portion; therefore I will wait for him."},
        {"ref": "Psalm 130:5", "text": "I wait for the Lord, my whole being waits, and in his word I put my hope."},
        {"ref": "Hebrews 11:1", "text": "Now faith is confidence in what we hope for and assurance about what we do not see."},
        {"ref": "Psalm 62:5", "text": "Yes, my soul, find rest in God; my hope comes from him."},
        {"ref": "1 Peter 1:3", "text": "In his great mercy he has given us new birth into a living hope."},
        {"ref": "Romans 8:28", "text": "And we know that in all things God works for the good of those who love him."},
        {"ref": "Psalm 31:24", "text": "Be strong and take heart, all you who hope in the Lord."},
    ],
    "rest": [
        {"ref": "Matthew 11:28", "text": "Come to me, all you who are weary and burdened, and I will give you rest."},
        {"ref": "Psalm 23:2", "text": "He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul."},
        {"ref": "Psalm 46:10", "text": "Be still, and know that I am God."},
        {"ref": "Exodus 33:14", "text": "My Presence will go with you, and I will give you rest."},
        {"ref": "Psalm 127:2", "text": "He grants sleep to those he loves."},
        {"ref": "Mark 6:31", "text": "Come with me by yourselves to a quiet place and get some rest."},
        {"ref": "Isaiah 30:15", "text": "In repentance and rest is your salvation, in quietness and trust is your strength."},
        {"ref": "Hebrews 4:9", "text": "There remains, then, a Sabbath-rest for the people of God."},
        {"ref": "Psalm 116:7", "text": "Return to your rest, my soul, for the Lord has been good to you."},
        {"ref": "Matthew 11:29", "text": "Take my yoke upon you and learn from me, for I am gentle and humble in heart, and you will find rest."},
        {"ref": "Psalm 62:1", "text": "Truly my soul finds rest in God; my salvation comes from him."},
        {"ref": "Isaiah 40:29", "text": "He gives strength to the weary and increases the power of the weak."},
    ],
    "gratitude": [
        {"ref": "Psalm 136:1", "text": "Give thanks to the Lord, for he is good. His love endures forever."},
        {"ref": "1 Thessalonians 5:18", "text": "Give thanks in all circumstances; for this is God's will for you in Christ Jesus."},
        {"ref": "James 1:17", "text": "Every good and perfect gift is from above, coming down from the Father of the heavenly lights."},
        {"ref": "Colossians 3:17", "text": "And whatever you do, whether in word or deed, do it all in the name of the Lord Jesus, giving thanks."},
        {"ref": "Psalm 100:4", "text": "Enter his gates with thanksgiving and his courts with praise; give thanks to him and praise his name."},
        {"ref": "Psalm 107:1", "text": "Give thanks to the Lord, for he is good; his love endures forever."},
        {"ref": "Ephesians 5:20", "text": "Always giving thanks to God the Father for everything, in the name of our Lord Jesus Christ."},
        {"ref": "Philippians 4:6", "text": "In every situation, by prayer and petition, with thanksgiving, present your requests to God."},
        {"ref": "Psalm 9:1", "text": "I will give thanks to you, Lord, with all my heart; I will tell of all your wonderful deeds."},
        {"ref": "2 Corinthians 9:15", "text": "Thanks be to God for his indescribable gift."},
        {"ref": "Psalm 28:7", "text": "The Lord is my strength and my shield; my heart trusts in him, and he helps me."},
        {"ref": "Colossians 2:7", "text": "Rooted and built up in him, strengthened in the faith as you were taught, and overflowing with thankfulness."},
    ],
    "strength": [
        {"ref": "Philippians 4:13", "text": "I can do all this through him who gives me strength."},
        {"ref": "Isaiah 41:10", "text": "So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you."},
        {"ref": "Psalm 46:1", "text": "God is our refuge and strength, an ever-present help in trouble."},
        {"ref": "Isaiah 40:29", "text": "He gives strength to the weary and increases the power of the weak."},
        {"ref": "2 Corinthians 12:9", "text": "My grace is sufficient for you, for my power is made perfect in weakness."},
        {"ref": "Ephesians 6:10", "text": "Be strong in the Lord and in his mighty power."},
        {"ref": "Psalm 18:32", "text": "It is God who arms me with strength and keeps my way secure."},
        {"ref": "Nehemiah 8:10", "text": "The joy of the Lord is your strength."},
        {"ref": "Joshua 1:9", "text": "Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you."},
        {"ref": "Psalm 28:7", "text": "The Lord is my strength and my shield; my heart trusts in him, and he helps me."},
        {"ref": "Isaiah 12:2", "text": "Surely God is my salvation; I will trust and not be afraid."},
        {"ref": "Psalm 18:1", "text": "I love you, Lord, my strength."},
    ],
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
- If in doubt, leave it out entirely

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

    resonance_profile[theme] = resonance_profile.get(theme, 0) + 1
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
    theme = data.get("theme", "peace")
    emotion = data.get("emotion", "calm")
    seed = data.get("seed", "stillness")
    used_refs = data.get("used_refs", [])

    # Pick verse from bank avoiding already-used ones
    verse_list = ZEN_VERSE_BANK.get(theme, ZEN_VERSE_BANK["peace"])
    available = [v for v in verse_list if v["ref"] not in used_refs]
    if not available:
        available = verse_list  # reset if all used

    verse = random.choice(available)
    verse_text = verse["text"]
    verse_ref = verse["ref"]

    system_prompt = """You are Lumíne, a calm spiritual narrator.

Your job is to write a short narration ABOUT a Scripture verse — not to repeat it.

STRICT RULES:
- Do NOT quote the verse text or repeat any of its words
- Do NOT say the verse reference, book name, or chapter number
- Write exactly 2 sentences
- First sentence: the human story or moment behind when this was written
- Second sentence: one quiet word of comfort for someone feeling this emotion right now
- Warm, intimate, under 35 words total
- No preaching. No religion-speak. No filler."""

    user_message = f"""The verse is: "{verse_text}"
The person is feeling: {emotion}
The session theme is: {theme}
Seed word for variety: {seed}

Write the narration now. Do not repeat the verse. Do not name the book or reference."""

    narration = call_gloo(system_prompt, user_message)

    if not narration:
        narration_map = {
            "peace": "This came from a moment of real storm — when someone had nothing left but trust. That same stillness is available to you right now.",
            "hope": "This was written in a season of waiting, when the future felt completely sealed. Something in you already knows what it means to keep going anyway.",
            "rest": "These words came from exhaustion — the kind that goes deeper than sleep. You are allowed to stop carrying this for a moment.",
            "gratitude": "This was a moment of sudden clarity — when ordinary things looked like gifts. Something good is already present with you, even now.",
            "strength": "This was written at the edge of what felt possible. The same source that held them then is holding you in this exact moment.",
        }
        narration = narration_map.get(
            theme,
            "This was written for someone who needed it exactly as much as you do right now. You are not alone in this."
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
        return {
            "journal": "Lumíne is still learning your rhythms. Interact more and your journal will begin to write itself."
        }

    emotion_summary = ", ".join(
        [f'{e["emotion"]} at {e["hour"]}:00' for e in emotions[-10:]]
    )

    system_prompt = """You are Lumíne, writing a short personal journal entry for someone's day.

RULES:
- Write 2-3 sentences ONLY
- Speak directly to the user: "You started..."
- Be warm but precise
- Reference specific emotions and times
- If there were sacred interruptions, mention them naturally
- Do NOT use scripture
- Do NOT be preachy
- Sound like a caring companion summarizing their day
- Make it feel like someone who was quietly watching over them all day"""

    user_message = f"""Today's emotional data:
{emotion_summary}

Sacred interruptions today: {interruptions}
Stress spikes today: {spikes}

Write a short journal entry for this person's day."""

    journal = call_gloo(system_prompt, user_message)

    if not journal:
        journal = "You moved through today carrying more than most people saw. Lumíne was with you through each moment."

    return {"journal": journal}


@app.post("/soulmap")
async def generate_soul_map(data: dict):
    top_emotion = data.get("top_emotion", "calm")
    anchor_verse = data.get("anchor_verse", "")
    anchor_count = data.get("anchor_count", 0)
    recovery_minutes = data.get("recovery_minutes", 0)
    stress_spikes = data.get("stress_spikes", 0)
    pattern = data.get("pattern", {})
    interruptions = data.get("interruptions", 0)
    days_active = data.get("days_active", 1)
    recent_emotions = data.get("recent_emotions", [])

    system_prompt = """You are Lumíne, writing a spiritual fingerprint for someone.

STRICT RULES:
- Write EXACTLY 2 sentences. Never more.
- First sentence: what you have noticed about them specifically.
- Second sentence: one quiet observation that feels profound.
- Maximum 30 words total.
- Be precise not poetic.
- No filler words.
- No generic comfort.
- No scripture.
- No preachy language.
- Every word must earn its place.
- Sound like someone who truly knows them."""

    user_message = f"""This person's spiritual data:
- Most frequent emotional state: {top_emotion}
- Verse that keeps finding them: {anchor_verse} (found them {anchor_count} times)
- Average time to return to calm after stress: {recovery_minutes} minutes
- Stress spikes today: {stress_spikes}
- Morning emotional tendency: {pattern.get("Morning", "calm")}
- Afternoon emotional tendency: {pattern.get("Afternoon", "calm")}
- Evening emotional tendency: {pattern.get("Evening", "calm")}
- Night emotional tendency: {pattern.get("Night", "calm")}
- Times Lumíne has intervened: {interruptions}
- Days walking with Lumíne: {days_active}
- Recent emotional journey: {", ".join(recent_emotions[-8:]) if recent_emotions else "just beginning"}

Write their spiritual fingerprint."""

    fingerprint = call_gloo(system_prompt, user_message)

    if not fingerprint:
        fingerprint = f"You carry {top_emotion} most often, and yet you keep returning to stillness. Lumíne has noticed this quiet resilience in you."

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