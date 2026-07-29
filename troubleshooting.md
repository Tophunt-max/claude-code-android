# Troubleshooting

Fixes for the Termux → proot-Ubuntu → Claude Code → 9Router setup. Each entry is tagged with **which shell** it applies to, because that's the answer half the time.

> [!IMPORTANT]
> **First question, always: which shell are you in?**
>
> | Prompt | You're in | What belongs here |
> |---|---|---|
> | `~ $` | Termux | `9router`, `node`, `proot-distro` |
> | `root@localhost:~#` | Ubuntu | `claude`, `~/.claude/settings.json` |

> [!NOTE]
> **This file is incomplete on purpose.** Below are the predictable failure modes. The valuable entries are the errors *you* hit on your own phone — log them verbatim using the [template at the bottom](#add-your-own). That's what makes this better than a tutorial's comment section.

---

## Coming from the native install (Path A)

### Claude Code installed natively but misbehaves
`Termux` — sandbox errors, `EACCES` on file writes, hangs, one-token freezes.

This is the glibc-shim problem, not something you did wrong. Switch to proot-Ubuntu ([README Chapter 2](README.md#chapter-2--install-ubuntu)). It's the upstream maintainer's own recommendation.

### Removing a Path A install properly
`Termux`

`npm uninstall -g @anthropic-ai/claude-code` **does not remove current Path A installs.** Recent versions install a patched binary plus a launcher wrapper, not an npm package. Find what you actually have:

```bash
command -v claude
ls -la $PREFIX/bin/claude
```

Remove whatever turns up there. You don't strictly have to — a leftover Termux `claude` doesn't interfere with the one inside Ubuntu — but two different `claude` commands in two shells is a reliable way to confuse yourself.

### `claude: command not found` after switching to Path B
`Termux`

Expected. Claude Code now lives inside Ubuntu. Run `proot-distro login ubuntu` first.

---

## Install failures

### `pkg update` fails, or repos 404
`Termux`

Termux from the Play Store is an experimental branch. Uninstall it and reinstall from [F-Droid](https://f-droid.org/packages/com.termux/) or [GitHub Releases](https://github.com/termux/termux-app/releases). Single most common cause of "nothing works."

### Prompted about package maintainer configs during upgrade
`Termux` `Ubuntu`

Press `y`. Keeping old configs can leave a broken package set.

### `uname -m` prints `armv7l` or `armv8l`
`Termux`

32-bit OS. Claude Code needs aarch64 — some budget Samsung A-series ship a 32-bit OS on 64-bit hardware. This stack won't work on those, and there's no workaround.

### `proot-distro install ubuntu` fails partway, or runs out of space
`Termux`

Ubuntu needs ~2GB and the download unpacks before cleanup, so headroom matters. Check with `df -h $HOME`. To retry cleanly:

```bash
proot-distro remove ubuntu
proot-distro install ubuntu
```

> [!WARNING]
> `proot-distro remove` deletes everything inside the container — Claude Code, your config, and any files you made in there. Only use it on a container that never worked.

### `proot-distro: command not found`

`pkg install proot-distro -y` — in **Termux**, not inside Ubuntu.

### `claude --version` fails right after the install
`Ubuntu`

PATH hasn't been picked up:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
ls -la ~/.local/bin/claude
```

If the binary isn't there at all, re-run `curl -fsSL https://claude.ai/install.sh | bash` and read the output instead of scrolling past it.

### A guide told me to install Node with `curl -fsSL https://nodesource.com | bash -`

That isn't a setup script — `nodesource.com` is just a website, so the command pipes a web page into bash and does nothing. Harmless but pointless. Claude Code's official installer ships a standalone binary and needs no Node inside Ubuntu.

### `Hash Sum mismatch` during the Ubuntu step
`Ubuntu`

Nothing is wrong with your install. Ubuntu's mirror was mid-sync, or a caching proxy on your connection served a stale copy of a `.deb` that didn't match the index. The container itself installed fine — only the package fetch tripped.

`setup.sh` v1.1+ clears the package index and retries once automatically. If you hit this running the script by hand, do the same thing from inside Ubuntu:

```bash
apt clean
rm -rf /var/lib/apt/lists/*
apt-get update -o Acquire::http::No-Cache=true
apt install -y curl git wget build-essential
```

`No-Cache=true` tells any proxy in the path not to hand back the stale file. Still mismatching on the same package? Your connection has a transparent cache — switch networks (Wi-Fi ↔ mobile data) and retry. That sidesteps it every time.

---

## 9Router problems

### `9router: command not found` after `npm install -g`

Check you're in **Termux**, not Ubuntu, and that npm's global bin is on PATH:

```bash
npm config get prefix
echo $PATH
```

### Dashboard won't load at `http://localhost:20128`

9Router has to be running in a live Termux session. Close that session and the proxy dies. Start it again and leave it alone.

### Port already in use
`Termux`

```bash
pkill -f 9router
```

### Dashboard says "Claude CLI not detected locally"
`Termux` — under CLI Tools → Claude Code. **Expected. Nothing is wrong.**

9Router runs in Termux and auto-detects Claude Code by looking for a `claude` binary on the Termux PATH. Yours is inside the Ubuntu container at `/root/.local/bin/claude`, which Termux cannot see. The detection is accurate about its own shell and says nothing about whether your install works. Check the install itself from inside Ubuntu:

```bash
which claude          # /root/.local/bin/claude
claude --version
```

If those work, you're done — use the dashboard only to manage providers and combos.

> [!WARNING]
> **Don't use that card's install or auto-config buttons.**
> - The install instructions lead to `npm install -g @anthropic-ai/claude-code` in Termux, which rebuilds the native Path A install this repo exists to avoid — and leaves you with two different `claude` commands in two shells.
> - Auto-config writes `~/.claude/settings.json` in **Termux's** home, which Claude Code never reads. Write it inside Ubuntu instead, as in [Chapter 6](README.md#chapter-6--point-claude-code-at-9router).

### Dashboard password rejected

Default is `123456`. If you changed it and forgot, you'll need to reset 9Router's config.

> [!CAUTION]
> **Change the default password.** `123456` is published in the docs. Low risk while the proxy only listens on localhost on your own phone; a real exposure the moment that port is reachable from another device. Change it before using this on shared or public Wi-Fi.

---

## Claude Code can't reach the proxy

### Connection refused / API errors

Checklist, in order:

1. Is `9router` still running in its Termux session?
2. Are you editing the config **inside Ubuntu**? A `~/.claude/settings.json` in Termux's home is ignored — Claude Code runs in Ubuntu and reads Ubuntu's home. Confirm from inside Ubuntu:
   ```bash
   cat ~/.claude/settings.json
   ```
3. Is the base URL exactly `http://127.0.0.1:20128/v1` — numeric IP, and `/v1` on the end?
4. Does the combo name in `settings.json` match the dashboard **exactly**? A mismatch fails without a useful error.
5. Is the JSON valid? A trailing comma breaks it silently. From inside Ubuntu:
   ```bash
   python3 -c "import json,os;json.load(open(os.path.expanduser('~/.claude/settings.json')));print('ok')"
   ```

### Requests work from Termux but not from inside Ubuntu

Shouldn't happen — proot shares the network namespace, so `127.0.0.1` reaches the proxy either way. Test it from inside Ubuntu:

```bash
curl -s http://127.0.0.1:20128/ -o /dev/null -w '%{http_code}\n'
```

If that fails while the same command works in Termux, log it — that's a real finding worth an entry here.

### Rate limited / quota exhausted

Expected on free tiers. Add more providers to the combo and check the fallback order. See [`free-api-options.md`](free-api-options.md).

### A provider errors in the 9Router console log

First, read the status code — 403 and 429 mean opposite things and only one is worth retrying:

| Code | Meaning | What to do |
|---|---|---|
| **429** | Free quota used up | Nothing. This is normal. Fallback moves to the next provider |
| **403** | Not authorized at all | Retrying won't help. Usually the specific account, not the provider — sign it into the provider's own app first, and swap it out if it still fails. Test a second account to tell an account problem from a provider-wide one |
| **401** | Bad or expired credentials | Re-add the key or re-authenticate the account in the dashboard |
| **5xx** | Provider is down | Move that provider lower in the combo |

If the log shows a request arriving at all — a line like `▶ POST claude-opus-free → provider/model` — then Claude Code, `settings.json`, and the combo name are all correct. The failure is upstream at the provider, not in your setup.

> [!IMPORTANT]
> **Check that your combo contains more than one provider.** If every entry in the combo is from the same provider, one provider outage takes the whole combo down and the fallback has nowhere to go — you'll see it try each account, then each model, then give up. Combos only help when the entries are genuinely different providers. Keep a high-limit one at the bottom as a floor.

> [!WARNING]
> Adding several accounts on the *same* provider to multiply a free tier generally breaks that provider's terms of service, and providers tend to respond with blanket `403`s rather than rate limits. One account per provider and several different providers is both more reliable and reproducible for anyone following your setup.

---

## Mobile survival

### Termux gets killed in the background, sessions die

Android's battery optimiser. Two fixes, do both:

- Termux's wake-lock: pull down the notification shade, tap **Acquire wakelock**.
- Exempt Termux from battery optimisation: Android Settings → Apps → Termux → Battery → **Unrestricted**.

### Managing two sessions

Swipe from the left edge for the drawer, then **New session**. Session 1: `9router`. Session 2: `proot-distro login ubuntu` → `claude`.

### The keyboard is painful for terminal work
`Termux`

```bash
mkdir -p ~/.termux
echo "extra-keys = [['ESC','/','-','HOME','UP','END','PGUP'],['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN']]" >> ~/.termux/termux.properties
termux-reload-settings
```

This configures the Termux app itself, so it runs in **Termux**, not Ubuntu. A Bluetooth keyboard makes long sessions genuinely comfortable.

### Can't reach phone storage
`Termux`

```bash
termux-setup-storage
```

Grant the prompt; files appear under `~/storage/`. From inside Ubuntu, Termux's home is reachable at `/data/data/com.termux/files/home` — worth knowing when you want Claude Code working on files you can also open in an Android editor.

### Battery drains fast during long agent runs

Real constraint, not a bug. Stay plugged in for heavy tasks.

---

## Add your own

One entry per error you hit, in this shape:

```markdown
### <exact error text>
`Termux` or `Ubuntu`

When: <what you were doing>
Fix: <what actually resolved it>
```
