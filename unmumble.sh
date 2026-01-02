#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Unmumble
# @raycast.mode silent
# @raycast.packageName Unmumble

# Optional parameters:
# @raycast.icon ✨
# @raycast.description Select all text in current field, fix spelling/typos with AI, paste back

# ===========================================
# CONFIGURATION
# ===========================================

# Get your free API key at https://openrouter.ai/
OPENROUTER_API_KEY="YOUR_OPENROUTER_API_KEY_HERE"

# ===========================================
# CUSTOM DICTIONARY - Add your corrections here
# These rules are passed to the AI along with the text
# ===========================================
CUSTOM_RULES='
- Example: "teh" should be "the"
'

# ===========================================
# SCRIPT - No need to edit below this line
# ===========================================

# Select all and copy in one quick AppleScript (minimizes visible selection)
osascript -e 'tell application "System Events"
    keystroke "a" using command down
    delay 0.02
    keystroke "c" using command down
end tell'
sleep 0.05

# Get clipboard content
TEXT=$(pbpaste)

# Skip if empty
if [ -z "$TEXT" ]; then
    exit 0
fi

# Show "working" HUD (requires Raycast Notification extension)
# Install from: https://www.raycast.com/maxnyby/raycast-notification
open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22Fixing%20text...%22%7D" 2>/dev/null

# Escape text for JSON (remove outer quotes since we embed it in the prompt)
ESCAPED_TEXT=$(echo "$TEXT" | jq -Rs '.' | sed 's/^"//;s/"$//')

# Call OpenRouter API (using free Llama model)
RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -d "{
        \"model\": \"meta-llama/llama-3.3-70b-instruct:free\",
        \"max_tokens\": 1024,
        \"messages\": [{
            \"role\": \"user\",
            \"content\": \"Fix this text. Correct spelling and typos. If a word is jumbled or doesn't make sense in context, figure out what word was intended and use it. Do NOT change capitalization or punctuation. Keep the same tone, meaning, and voice.\\n\\nAlso apply these specific corrections:\\n$CUSTOM_RULES\\n\\nReturn ONLY the corrected text with no explanation or commentary:\\n\\n$ESCAPED_TEXT\"
        }]
    }")

# Extract the text from response (OpenAI-compatible format)
FIXED_TEXT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

# If we got a response, paste it back
if [ -n "$FIXED_TEXT" ]; then
    # Remove trailing newline and copy to clipboard
    printf "%s" "$FIXED_TEXT" | pbcopy
    sleep 0.05
    osascript -e 'tell application "System Events" to keystroke "v" using command down'
    # Success HUD
    open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22%E2%9C%A8%20Fixed!%22%7D" 2>/dev/null
    exit 0
else
    # Error HUD
    open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22Error%20fixing%20text%22%7D" 2>/dev/null
    exit 1
fi
