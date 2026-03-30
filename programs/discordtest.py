import urllib.request
import urllib.error
import json
import sys

if len(sys.argv) < 2:
    print("Usage: python test_bot.py <bot_token>")
    sys.exit(1)

BOT_TOKEN  = sys.argv[1]
CHANNEL_ID = "1487707180390940773"

# First check if the token is valid at all
url = "https://discord.com/api/v10/users/@me"
req = urllib.request.Request(
    url,
    headers={
        "Authorization": f"Bot {BOT_TOKEN}",
        "User-Agent": "DiscordBot (https://github.com/TsuBenn/dotfiles, 1.0)"
    }
)
try:
    with urllib.request.urlopen(req, timeout=10) as r:
        print(f"Bot identity: {json.loads(r.read().decode('utf-8'))}")
except urllib.error.HTTPError as e:
    print(f"Token invalid: {e.status} {e.read().decode('utf-8')}")
    sys.exit(1)

# Then try the channel
url = f"https://discord.com/api/v10/channels/{CHANNEL_ID}/messages?limit=1"
req = urllib.request.Request(
    url,
    headers={
        "Authorization": f"Bot {BOT_TOKEN}",
        "User-Agent": "DiscordBot (https://github.com/TsuBenn/dotfiles, 1.0)"
    }

)
try:
    with urllib.request.urlopen(req, timeout=10) as r:
        print(f"Messages: {json.loads(r.read().decode('utf-8'))}")
except urllib.error.HTTPError as e:
    print(f"Channel error: {e.status} {e.read().decode('utf-8')}")
