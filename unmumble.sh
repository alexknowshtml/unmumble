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

# Escape text for JSON (handle newlines and special chars)
TEXT_ESCAPED=$(printf '%s' "$TEXT" | jq -Rs '.')
if [ -z "$TEXT_ESCAPED" ]; then
    open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22Error%3A%20text%20escape%22%7D" >/dev/null 2>&1
    exit 1
fi

# Build JSON payload with few-shot prompting for better accuracy
PAYLOAD=$(jq -n --argjson text "$TEXT_ESCAPED" --arg rules "$CUSTOM_RULES" '{
    model: "anthropic/claude-3-haiku",
    max_tokens: 1024,
    messages: [{
        role: "system",
        content: ("Fix these specific issues: 1) Transposed letters (teh->the, adn->and), 2) Missing or extra letters (wiht->with, helllo->hello), 3) Spaces or punctuation in the middle of words (ra ycast->raycast, hel.lo->hello), 4) Wrong word in context (their->there, your->youre when needed). Do NOT change: intentional capitalization, sentence structure, or add/remove words. Be conservative - if unsure, leave it. Apply these replacements: " + $rules + ". Return the corrected text, then FIXCOUNT:N on its own line.")
    }, {
        role: "user",
        content: "i jsut wantd to say teh meet. ing went wel and their going to love it. lets talk tmrw"
    }, {
        role: "assistant",
        content: "i just wanted to say the meeting went well and theyre going to love it. lets talk tomorrow\nFIXCOUNT:7"
    }, {
        role: "user",
        content: $text
    }]
}' 2>/dev/null)

if [ -z "$PAYLOAD" ] || ! echo "$PAYLOAD" | jq -e '.messages' >/dev/null 2>&1; then
    open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22Error%3A%20payload%22%7D" >/dev/null 2>&1
    exit 1
fi

RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -d "$PAYLOAD" 2>/dev/null)

# Check for API error
if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22API%20Error%22%7D" >/dev/null 2>&1
    exit 1
fi

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
    open -g "raycast://extensions/maxnyby/raycast-notification/index?launchType=background&arguments=%7B%22title%22%3A%22Error%3A%20no%20response%22%7D" >/dev/null 2>&1
    exit 1
fi
