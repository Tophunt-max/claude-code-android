# Troubleshooting

Fixes for the Android + Termux + proot-Ubuntu + Claude Code + 9Router setup.

> **This file is incomplete on purpose.** The entries below are the predictable failure modes. The valuable ones — the errors *you actually hit* on your own phone — need adding from real install runs. Log them verbatim; that's what makes this better than every 5-minute tutorial's comment section.

**Before anything else: which shell are you in?** Half the problems in this stack are "right command, wrong environment." Termux shows `~ $`. Ubuntu shows `root@localhost:~#`. 9Router belongs in Termux; `claude` and its config belong in Ubuntu.

---

## Coming from the native install (Path A)

**Claude Code installed natively but misbehaves — sandbox errors, `EACCES` on file writes, hangs, one-token freezes**
This is the glibc-shim problem, not something you did wrong. Switch to proot-Ubuntu (README Chapter 2). It's the upstream maintainer's own recommendation.

**Removing a Path A install properly**
`npm uninstall -g @anthropic-ai/claude-code` **does not remove current Path A installs.** Recent versions install a patched binary plus a launcher wrapper, not an npm package. Find what you actually have, in Termux:

```bash
command -v claude
ls -la $PREFIX/bin/claude
```

Remove whatever turns up there. You don't strictly have to — a leftover Termux `claude` doesn't interfere with the one inside Ubuntu — but having two different `claude` commands in two shells is a reliable way to confuse yourself. Removing it means only Ubuntu has one.

**`claude: command not found` in Termux after switching to Path B**
Expected. Claude Code now lives inside Ubuntu. Run `proot-distro login ubuntu` first.

## Install failures

**`pkg update` fails, or repos 404**
Termux from the Play Store is an experimental branch. Uninstall it and reinstall from [F-Droid](https://f-droid.org/packages/com.termux/) or [GitHub Releases](https://github.com/termux/termux-app/releases). Single most common cause of "nothing works."

**Prompted about package maintainer configs during upgrade**
Press `y`. Keeping old configs can leave a broken package set.

**`uname -m` prints `armv7l` or `armv8l`**
32-bit OS. Claude Code needs aarch64 — some budget Samsung A-series ship a 32-bit OS on 64-bit hardware. This stack won't work on those.

**`proot-distro install ubuntu` fails partway, or runs out of space**
Ubuntu needs ~2GB and the download unpacks before cleanup, so headroom matters. Check with `df -h $HOME`. To retry cleanly:

```bash
proot-distro remove ubuntu
proot-distro install ubuntu
```

**`proot-distro: command not found`**
`pkg install proot-distro -y` — in Termux, not inside Ubuntu.

**`claude --version` fails right after the Ubuntu install**
PATH hasn't been picked up. Inside Ubuntu:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
ls -la ~/.local/bin/claude
```

If the binary isn't there at all, re-run `curl -fsSL https://claude.ai/install.sh | bash` and read the output instead of scrolling past it.

**A guide told me to install Node with `curl -fsSL https://nodesource.com | bash -`**
That isn't a setup script — `nodesource.com` is just a website, so the command pipes a web page into bash and does nothing. Harmless but pointless. Claude Code's official installer ships a standalone binary and needs no Node inside Ubuntu.

## 9Router problems

**`9router: command not found` after `npm install -g`**
Check you're in **Termux**, not Ubuntu, and that npm's global bin is on PATH:

```bash
npm config get prefix
echo $PATH
```

**Dashboard won't load at `http://localhost:20128`**
9Router has to be running in a live Termux session. Close that session and the proxy dies. Start it again and leave it alone.

**Port already in use**

```bash
pkill -f 9router
```

**Dashboard password rejected**
Default is `123456`. If you changed it and forgot, you'll need to reset 9Router's config.

**⚠️ Change the default password.** `123456` is published in the docs. Low-risk while the proxy only listens on localhost on your own phone; a real exposure the moment that port is reachable from another device. Change it before using this on shared or public Wi-Fi.

## Claude Code can't reach the proxy

**Connection refused / API errors**
Checklist, in order:

1. Is `9router` still running in its Termux session?
2. Are you editing the config **inside Ubuntu**? `~/.claude/settings.json` in Termux's home is ignored — Claude Code runs in Ubuntu and reads Ubuntu's home. Confirm from inside Ubuntu:
   ```bash
   cat ~/.claude/settings.json
   ```
3. Is the base URL `http://127.0.0.1:20128/v1` — numeric IP, and `/v1` on the end?
4. Does the combo name in `settings.json` match the dashboard **exactly**? A mismatch fails without a useful error.
5. Is the JSON valid? A trailing comma breaks it silently. From inside Ubuntu:
   ```bash
   python3 -c "import json,os;json.load(open(os.path.expanduser('~/.claude/settings.json')));print('ok')"
   ```

**Requests work from Termux but not from inside Ubuntu**
Shouldn't happen — proot shares the network namespace, so `127.0.0.1` reaches the proxy either way. Test it from inside Ubuntu:

```bash
curl -s http://127.0.0.1:20128/ -o /dev/null -w '%{http_code}\n'
```

If that fails while the same command works in Termux, log it — that's a real finding worth an entry here.

**Rate limited / quota exhausted**
Expected on free tiers. Add more providers to the combo and check the fallback order. See [`free-api-options.md`](free-api-options.md).

## Mobile survival

**Termux killed in the background, sessions die**
Android's battery optimiser. Two fixes:
- Termux's wake-lock: pull down the notification shade, tap **Acquire wakelock**.
- Exempt Termux from battery optimisation: Android Settings → Apps → Termux → Battery → Unrestricted.

**Managing two sessions**
Swipe from the left edge for the drawer, then **New session**. Session 1: `9router`. Session 2: `proot-distro login ubuntu` → `claude`.

**Keyboard is painful for terminal work**

```bash
mkdir -p ~/.termux
echo "extra-keys = [['ESC','/','-','HOME','UP','END','PGUP'],['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN']]" >> ~/.termux/termux.properties
termux-reload-settings
```

Run this in **Termux** — it configures the Termux app itself, not Ubuntu. A Bluetooth keyboard makes long sessions genuinely comfortable.

**Can't reach phone storage**
In Termux:

```bash
termux-setup-storage
```

Grant the prompt; files appear under `~/storage/`. From inside Ubuntu, Termux's home is reachable at `/data/data/com.termux/files/home` — worth knowing when you want Claude Code working on files you can also open in an Android editor.

**Battery drains fast during long agent runs**
Real constraint, not a bug. Stay plugged in for heavy tasks.

---

## Add your own

Template — one entry per error you hit while filming:

```markdown
**<exact error text>**
Where: Termux / Ubuntu
When: <what you were doing>
Fix: <what actually resolved it>
```
