#!/usr/bin/env bash
# Usage: ssh pi ./bot.sh "question"   or   echo "question" | ssh pi ./bot.sh
# Prompt from args, else stdin (Shortcuts "Run Script over SSH" passes input on stdin).
# Needs: curl, jq. Uses the Ollama HTTP API ("ollama run" prints spinner escape codes even when piped).
set -euo pipefail

MODEL="${BOT_MODEL:-llama3.2:3b}"   # pick something your Pi can run: ollama list
HOST="${BOT_OLLAMA_URL:-http://127.0.0.1:11434}"
PROMPT="${*:-$(cat)}"
PROMPT="${PROMPT#@bot}"              # strip trigger word if Shortcut forwards it
PROMPT="${PROMPT#"${PROMPT%%[![:space:]]*}"}"   # trim leading whitespace

[ -n "$PROMPT" ] || { echo "empty prompt"; exit 1; }

# ponytail: stateless, no chat history. Add a per-sender history file if you want context.
jq -n --arg m "$MODEL" --arg p "$PROMPT" \
  '{model:$m, stream:false, keep_alive:"30m",
    messages:[{role:"system",content:"You are a witty, sarcastic chat bot. Answer correctly but with a joke, pun or playful roast. Max 2 short sentences, plain text, no markdown."},
              {role:"user",content:$p}]}' |
  curl -s --max-time 300 "$HOST/api/chat" -d @- |
  jq -r '.message.content // ("bot error: " + (.error // "no reply from ollama"))'
