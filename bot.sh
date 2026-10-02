#!/usr/bin/env bash
# Usage: ssh pi ./bot.sh "question"   or   echo "question" | ssh pi ./bot.sh
# Prompt from args, else stdin (Shortcuts "Run Script over SSH" passes input on stdin).
set -euo pipefail

MODEL="${BOT_MODEL:-llama3.2:3b}"   # pick something your Pi can run: ollama list
PROMPT="${*:-$(cat)}"
PROMPT="${PROMPT#@bot}"              # strip trigger word if Shortcut forwards it
PROMPT="${PROMPT#"${PROMPT%%[![:space:]]*}"}"   # trim leading whitespace

[ -n "$PROMPT" ] || { echo "empty prompt"; exit 1; }

# ponytail: stateless, no chat history. Add a per-sender history file if you want context.
printf '%s' "Reply briefly, plain text, no markdown. $PROMPT" | ollama run "$MODEL"
