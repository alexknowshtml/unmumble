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
# @raycast.description Fix spelling/typos in selected text (or select all if nothing selected)

# ===========================================
# CONFIGURATION
# ===========================================

# Get your free API key at https://openrouter.ai/
OPENROUTER_API_KEY="YOUR_OPENROUTER_API_KEY_HERE"

# Custom dictionary (single line for JSON safety)
# Format: "wrong -> right, wrong2 -> right2"
CUSTOM_RULES="co-working -> coworking"

# ===========================================
# SCRIPT - No need to edit below this line
# ===========================================

LOCK_FILE="/tmp/unmumble.lock"

# Prevent double-runs - check lock first
if [ -f "$LOCK_FILE" ] && [ $(($(date +%s) - $(stat -f %m "$LOCK_FILE"))) -lt 30 ]; then
    open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22%E2%8F%B3%20hold%20on...%22%7D" >/dev/null 2>&1
    exit 0
fi

touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Clear clipboard first to detect if copy worked
echo -n "" | pbcopy

# First, try to copy current selection
osascript -e 'tell application "System Events" to keystroke "c" using command down' 2>/dev/null
sleep 0.15

TEXT=$(pbpaste)

# If clipboard is still empty, nothing was selected - do select all
if [ -z "$TEXT" ]; then
    osascript -e 'tell application "System Events"
        keystroke "a" using command down
        delay 0.1
        keystroke "c" using command down
    end tell' 2>/dev/null
    sleep 0.2
    TEXT=$(pbpaste)
fi

if [ -z "$TEXT" ]; then
    exit 0
fi

# Notify AFTER we have text
open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22%F0%9F%AB%A3%20oh%20boy%20here%20we%20go%22%7D" >/dev/null 2>&1

# Build JSON payload with few-shot prompting for better accuracy
PAYLOAD=$(jq -n \
    --arg text "$TEXT" \
    --arg rules "$CUSTOM_RULES" \
    '{
        model: "meta-llama/llama-3.3-70b-instruct:free",
        max_tokens: 1024,
        messages: [{
            role: "system",
            content: "You fix typos and wrong words. If a word is spelled correctly but wrong in context, fix it (e.g. their vs there, your vs you are). Return ONLY the corrected text, then FIXCOUNT:N on its own line. Never add commentary."
        }, {
            role: "user",
            content: "Fix typos: teh qucik brwon fox"
        }, {
            role: "assistant",
            content: "the quick brown fox\nFIXCOUNT:3"
        }, {
            role: "user",
            content: ("Fix typos: " + $text + "\n\nCustom rules: " + $rules)
        }]
    }')

RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -d "$PAYLOAD" 2>/dev/null)

FIXED_TEXT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

if [ -n "$FIXED_TEXT" ]; then
    # Extract count from last line
    COUNT=$(echo "$FIXED_TEXT" | grep -o 'FIXCOUNT:[0-9]*' | tail -1 | cut -d: -f2)

    # Remove the FIXCOUNT line from the text
    CLEAN_TEXT=$(echo "$FIXED_TEXT" | sed '/^FIXCOUNT:[0-9]*$/d')

    # Copy to clipboard and paste
    printf "%s" "$CLEAN_TEXT" | pbcopy
    sleep 0.05
    osascript -e 'tell application "System Events" to keystroke "v" using command down' 2>/dev/null

    # Show count in notification
    if [ -n "$COUNT" ] && [ "$COUNT" != "0" ]; then
        open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22%E2%9C%85%20Fixed%20${COUNT}%20words%22%7D" >/dev/null 2>&1
    else
        open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22%E2%9C%85%20All%20good%22%7D" >/dev/null 2>&1
    fi
    exit 0
else
    open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22Error%22%7D" >/dev/null 2>&1
    exit 1
fi
