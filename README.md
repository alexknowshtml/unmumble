# Unmumble

**AI-powered typo fixer for Raycast/macOS.** Works with any text field. Hit a hotkey, get clean text.

Uses Claude 3 Haiku via OpenRouter for the best results (fractions of a penny per fix), or swap in a free model or your own local model via Ollama.

---

If you're like me, using Claude Code has had one really nasty side effect: it's made me a lot more tolerant to my own goofy typos and errors...because I know the agent just understands what I meant.

The people I work with and talk to every day...they deserve better.

So I created this simple Raycast script command that automatically finds and fixes typos, spelling errors, and jumbled words without changing any meaning or loss of fidelity.

Works in any text field that Raycast can access. Just hit a hotkey and my sloppy AI-brained typing becomes clean text. Does not change capitalization or punctuation.

## What It Does

1. Copies selected text (or selects all if nothing selected)
2. Shows a "🫣 oh boy here we go" HUD notification
3. Sends it to Claude 3 Haiku via OpenRouter
4. Fixes spelling, typos, and contextually wrong words
5. Pastes the cleaned text back
6. Shows "✅ Fixed N words" or "✅ All good" HUD notification

The whole process takes about 1-2 seconds and works in any app.

## Demo

Type this:
```
i jsut wanted to chekc in abuot the meeitng tomrrow at indie hall
```

Get this:
```
i just wanted to check in about the meeting tomorrow at Indy Hall
```

## Requirements

- macOS
- [Raycast](https://raycast.com) (free)
- [Raycast Notification extension](https://www.raycast.com/maxnyby/raycast-notification) (for HUD notifications)
- [jq](https://jqlang.github.io/jq/) - JSON processor
- [OpenRouter API key](https://openrouter.ai/) (free tier works great)

## Installation

### 1. Install dependencies

```bash
# Install jq if you don't have it
brew install jq
```

### 2. Get an OpenRouter API key

1. Go to [openrouter.ai](https://openrouter.ai/)
2. Sign up (free)
3. Go to Keys → Create Key
4. Copy your API key

### 3. Install the script

```bash
# Create Raycast scripts directory (if it doesn't exist)
mkdir -p ~/Documents/Raycast\ Scripts

# Download the script
curl -o ~/Documents/Raycast\ Scripts/unmumble.sh \
  https://raw.githubusercontent.com/alexknowshtml/unmumble/main/unmumble.sh

# Make it executable
chmod +x ~/Documents/Raycast\ Scripts/unmumble.sh
```

### 4. Add your API key

Edit the script and replace `YOUR_OPENROUTER_API_KEY_HERE` with your actual key:

```bash
# Open in your editor
open ~/Documents/Raycast\ Scripts/unmumble.sh
```

Find this line and add your key:
```bash
OPENROUTER_API_KEY="YOUR_OPENROUTER_API_KEY_HERE"
```

### 5. Add the script directory to Raycast

1. Open Raycast
2. Go to Settings (`Cmd+,`)
3. Click **Extensions** → **Script Commands**
4. Click **Add Directories**
5. Select `~/Documents/Raycast Scripts`

### 6. Set up a hotkey

1. Open Raycast and search for "Unmumble"
2. Press `Cmd+K` to open actions
3. Click **Add Hotkey**
4. Set your preferred hotkey (I use `Hyper+Enter` with Raycast's built-in Hyper Key feature)

### 7. Install the notification extension

For HUD notifications at the bottom of your screen:

1. Open Raycast
2. Search for "Store"
3. Search for "Raycast Notification" by maxnyby
4. Install it

Without this extension, the script still works but you won't see the status notifications.

## Custom Dictionary

You can add custom word corrections that the AI will always apply. Edit the `CUSTOM_RULES` line in the script:

```bash
# Format: "wrong -> right, wrong2 -> right2"
CUSTOM_RULES="Indie Hall -> Indy Hall, co-working -> coworking (no hyphen), Stacking the bricks -> Stacking the Bricks"
```

Add your own rules following the same comma-separated format.

## How It Works

The script:
1. Checks for double-runs (shows "⏳ hold on..." if already running)
2. Tries to copy current selection first; if nothing selected, does `Cmd+A` then `Cmd+C`
3. Sends the text to Claude 3 Haiku via OpenRouter
4. The AI fixes errors while preserving your tone, capitalization, punctuation, and formatting
5. Pastes the result back with `Cmd+V`
6. Shows how many words were fixed in the notification

The model is instructed to:
- Fix spelling and typos
- Figure out jumbled/contextually wrong words
- Preserve all formatting, line breaks, and whitespace
- NOT change capitalization or punctuation
- Apply your custom dictionary rules
- Return only the corrected text (no explanations)

## Troubleshooting

### Nothing happens when I run it

1. Check that jq is installed: `which jq`
2. Verify your API key is set correctly in the script
3. Make sure the script is executable: `chmod +x ~/Documents/Raycast\ Scripts/unmumble.sh`

### I get an error notification

- Check your OpenRouter API key is valid
- Check you have credits (the free tier should work, but has rate limits)
- Try running the script manually to see error output:
  ```bash
  ~/Documents/Raycast\ Scripts/unmumble.sh
  ```

### The text selection is visible/annoying

The script tries to copy the current selection first. If nothing is selected, it falls back to select all. To fix just part of your text, select it first then trigger Unmumble.

## Cost

The script defaults to **Claude 3 Haiku** via OpenRouter for the best results. It's cheap:

| Usage | Monthly Cost |
|-------|-------------|
| 10 fixes/day | ~$0.04 |
| 50 fixes/day | ~$0.21 |
| 100 fixes/day | ~$0.42 |

That's fractions of a penny per fix ($0.25/million input tokens, $1.25/million output tokens).

### Want Free Instead?

You can switch to OpenRouter's free tier (Llama 3.3 70B) by changing the model in the script:

```bash
model: "meta-llama/llama-3.3-70b-instruct:free"
```

Free tier limits:
- 50 requests/day (no credits)
- 1,000 requests/day ($10+ credits purchased once, ever)

The free models work but can be slower and less accurate. Haiku is worth the pennies.

### Using a Local Model (Ollama)

If you'd rather run completely locally with no API calls, you can use Ollama. Just change the curl call in the script:

```bash
# Replace the OpenRouter curl call with:
RESPONSE=$(curl -s http://localhost:11434/api/chat \
    -d "$PAYLOAD")
```

And update the model name in the payload to match your local model (e.g., `llama3.2`, `mistral`, etc.). The response format is the same, so everything else should just work.

## Want a Proper Raycast Extension?

This script works great, but if you'd prefer a one-click install from the Raycast Store with a proper settings UI, [open an issue](https://github.com/alexknowshtml/unmumble/issues) and let me know. If there's enough interest, I'll build it.

## Credits

Built by [Alex Hillman](https://alexhillman.com) with help from Claude.

## License

MIT - do whatever you want with it.
