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

if [ "$PROMPT" = "/status" ]; then
  echo "up: $(uptime -p | sed 's/^up //') | load: $(cut -d' ' -f1-3 /proc/loadavg)"
  free -m | awk '/Mem:/{printf "ram: %d/%d MB used\n",$3,$2}'
  df -h / | awk 'NR==2{print "disk /: "$5" used, "$4" free"}'
  command -v vcgencmd >/dev/null && vcgencmd measure_temp | sed 's/temp=/temp: /'
  echo "ollama: $(curl -s --max-time 3 "$HOST/api/ps" | jq -r 'if (.models|length)>0 then "loaded " + .models[0].name else "up, no model loaded" end' 2>/dev/null || echo DOWN)"
  echo "model: $MODEL"
  echo "last req: $(tail -1 "${BOT_LOG:-$HOME/bot.log}" 2>/dev/null | cut -d' ' -f1-3 | cut -c1-40)"
  exit 0
fi

# ponytail: stateless, no chat history. Add a per-sender history file if you want context.
REPLY=$(jq -n --arg m "$MODEL" --arg p "$PROMPT" \
  '{model:$m, stream:false, keep_alive:"30m", options:{num_predict:120},
    messages:[{role:"system",content:"You are a witty, sarcastic chat bot. Answer correctly but with a joke, pun or playful roast. Max 2 short sentences, plain text, no markdown."},
              {role:"user",content:$p}]}' |
  curl -s --max-time 120 "$HOST/api/chat" -d @- |
  jq -r '.message.content // ("bot error: " + (.error // "no reply from ollama"))')
printf '%s | %ss | %s -> %s\n' "$(date -Is)" "$SECONDS" "$PROMPT" "$REPLY" >> "${BOT_LOG:-$HOME/bot.log}"
echo "$REPLY"
