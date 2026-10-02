# AppleMessagesBot

iPhone/Mac Shortcut -> SSH over Tailscale -> `bot.sh` on Raspberry Pi -> local Ollama -> reply.

## Pi setup

```sh
curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:3b            # or any model; set BOT_MODEL to change
git clone https://github.com/Ovilli/AppleMessagesBot.git ~/AppleMessagesBot
chmod +x ~/AppleMessagesBot/bot.sh
~/AppleMessagesBot/bot.sh "say hi"   # test locally
```

Enable SSH on the Pi (`sudo systemctl enable --now ssh`). Note its Tailscale name (`tailscale status`), e.g. `raspberrypi`.

## Test from another tailnet device

```sh
ssh pi@raspberrypi '~/AppleMessagesBot/bot.sh "what is 2+2"'
```

## Apple Shortcut

1. Auth: easiest is password auth in the SSH action. For key auth, generate a key in the action (Authentication -> SSH Key), then append its public key to `~/.ssh/authorized_keys` on the Pi.
2. Shortcut steps:
   - **Receive** input (Share Sheet / Siri) or **Ask for Input**
   - **Run Script over SSH**: Host `raspberrypi` (tailnet name or 100.x IP), Port 22, User `pi`, Script `~/AppleMessagesBot/bot.sh`, Input = text from step 1 (arrives on stdin)
   - **Show Result** / **Send Message** / **Speak Text** with script output
3. Optional trigger: Shortcuts Automation -> Message -> "Message contains `@bot`" -> Run Shortcut, input = Message content.

Tailscale must be connected on the iPhone.

## Config

`BOT_MODEL=llama3.2:3b` env var picks the model. Prefix `@bot` is stripped from the prompt.
