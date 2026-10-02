# AppleMessagesBot

iPhone/Mac Shortcut -> SSH over Tailscale -> `bot.sh` on Raspberry Pi -> local Ollama -> reply.

## Pi setup

```sh
curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up
sudo apt install -y jq curl
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:3b            # or any model; set BOT_MODEL to change. Small SD card? Do the drive section below FIRST.
git clone https://github.com/Ovilli/AppleMessagesBot.git ~/AppleMessagesBot
chmod +x ~/AppleMessagesBot/bot.sh
~/AppleMessagesBot/bot.sh "say hi"   # test locally
```

### Models on external drive (small SD card)

Do this before `ollama pull`. Models are GBs; Ollama stores them in `OLLAMA_MODELS`.

```sh
lsblk -f                                   # find the drive, e.g. /dev/sda1
sudo mkdir -p /mnt/data
echo 'UUID=<uuid-from-lsblk> /mnt/data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
sudo mount -a                              # use ntfs-3g/exfat in fstab if not ext4 (ext4 recommended: ownership needed)
sudo mkdir -p /mnt/data/ollama && sudo chown ollama:ollama /mnt/data/ollama
sudo systemctl edit ollama                 # add the 2 lines below, save
#   [Service]
#   Environment="OLLAMA_MODELS=/mnt/data/ollama"
sudo systemctl daemon-reload && sudo systemctl restart ollama
```

If `ollama pull` ends with `digest mismatch` (seen on USB drives), download the big blob once with curl and retry:

```sh
# H = sha256 shown in the error as "want sha256:<H>"
B=/mnt/storage/ollama/blobs; sudo mkdir -p $B
sudo curl -sL -o $B/sha256-$H https://registry.ollama.ai/v2/library/<model>/blobs/sha256:$H
sha256sum $B/sha256-$H            # must equal $H
sudo chown -R ollama:ollama /mnt/storage/ollama && ollama pull <model>
```

`nofail` keeps the Pi booting if the drive is unplugged. If you already pulled models, `sudo mv /usr/share/ollama/.ollama/models/* /mnt/data/ollama/` before restarting.

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
