# Unmumble

A Raycast script command that fixes typos, spelling errors, and jumbled words in any text field using AI. Hit a hotkey, and your sloppy typing becomes clean text - perfect for those of us who've gotten lazy because AI chat understands us anyway.

## What It Does

1. Selects all text in the current field
2. Shows a "🫣 oh boy here we go" HUD notification
3. Sends it to an AI model (Llama 3.3 70B via OpenRouter - free!)
4. Fixes spelling, typos, and contextually wrong words
5. Pastes the cleaned text back
6. Shows a "✅ Fixed" HUD notification

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
1. Uses AppleScript to simulate `Cmd+A` and `Cmd+C` to grab the text
2. Sends the text to Llama 3.3 70B via OpenRouter's free API
3. The AI fixes errors while preserving your tone, capitalization, and punctuation
4. Pastes the result back with `Cmd+V`

The model is instructed to:
- Fix spelling and typos
- Figure out jumbled/contextually wrong words
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

The script tries to minimize the visible selection by doing select+copy very quickly. If it's still bothersome, you can modify your workflow to manually select (`Cmd+A`) and copy (`Cmd+C`) first, then edit the script to skip those steps.

## Cost

**Free!** OpenRouter's free tier includes Llama 3.3 70B which is more than capable for this task. You might hit rate limits with heavy use, but for normal usage it costs nothing.

## Credits

Built by [Alex Hillman](https://alexhillman.com) with help from Claude.

## License

MIT - do whatever you want with it.
