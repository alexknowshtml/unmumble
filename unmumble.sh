#!/bin/bash

# Add system paths (needed when running from Raycast)
export PATH="/usr/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

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

# Custom dictionary (single line for JSON safety)
# Format: "wrong -> right, wrong2 -> right2"
CUSTOM_RULES="Indie Hall -> Indy Hall, co-working -> coworking (no hyphen), Stacking the bricks -> Stacking the Bricks"

# ===========================================
# SCRIPT - No need to edit below this line
# ===========================================

# Select all and copy FIRST, before notification
osascript -e 'tell application "System Events"
    keystroke "a" using command down
    delay 0.1
    keystroke "c" using command down
end tell'
sleep 0.2

TEXT=$(pbpaste)

if [ -z "$TEXT" ]; then
    exit 0
fi

# Notify AFTER we have text
open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22%F0%9F%AB%A3%20oh%20boy%20here%20we%20go%22%7D"

# Build JSON payload properly using jq
PAYLOAD=$(jq -n \
    --arg text "$TEXT" \
    --arg rules "$CUSTOM_RULES" \
    '{
        model: "meta-llama/llama-3.3-70b-instruct:free",
        max_tokens: 1024,
        messages: [{
            role: "user",
            content: ("You are a text fixer. Fix spelling errors and typos in the text below. If a word is jumbled or wrong in context, replace it with the intended word. Do NOT change capitalization, punctuation, or add any commentary. Apply these rules: " + $rules + ". Output ONLY the corrected text, nothing else:\n\n" + $text)
        }]
    }')

RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -d "$PAYLOAD")

FIXED_TEXT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [ -n "$FIXED_TEXT" ]; then
    printf "%s" "$FIXED_TEXT" | pbcopy
    sleep 0.05
    osascript -e 'tell application "System Events" to keystroke "v" using command down'
    # Notify: ✅ Fixed
    open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22%E2%9C%85%20Fixed%22%7D"
    exit 0
else
    # Notify: Error
    open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22Error%22%7D"
    exit 1
fi
