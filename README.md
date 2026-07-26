# Claude Code on Android — 100% Free, No PC, No Root

Run Claude Code on an unrooted Android phone via Termux + proot-Ubuntu, with free model access through a local 9Router proxy.

Companion repo for the DevZoneX video. Commands are numbered to match the video chapters.

> **Verified on:** 2026-07-26 · Android, unrooted, aarch64
> Free provider tiers change often. If a step breaks, check [`free-api-options.md`](free-api-options.md), then [`troubleshooting.md`](troubleshooting.md).

---

## Why proot-Ubuntu and not the native Termux install

There are two ways to get Claude Code onto Android. **The simpler-looking one is the one that breaks.**

**Native Termux (Path A)** patches Anthropic's official `linux-arm64` binary to run against Termux's `glibc-runner`. It installs in 5–10 minutes and costs ~230MB. It is also a shim: Anthropic ships Claude Code as a glibc-linked binary with no Android build, and Termux runs on Android's Bionic libc. When it goes wrong you get sandbox errors, `EACCES` on file writes, and hangs — because the filesystem and `process.platform` don't behave the way Claude Code expects.

**proot-Ubuntu (Path B)** installs a real Ubuntu userland inside Termux and runs Anthropic's own official installer in it. ~2GB on disk instead of 230MB, a few minutes longer to set up, and everything behaves like ordinary Linux — because as far as Claude Code can tell, it *is* ordinary Linux.

Path B is what this repo documents. The maintainer of the Path A installer recommends the same:

> "Native Termux (Path A) works and is great for those who need it, especially with hardware or storage limitations. I highly recommend running it in proot-Ubuntu (Path B) though: it is the most native way I could get it running since the 2.1.112 regression."
> — [ferrumclaudepilgrim/claude-code-android](https://github.com/ferrumclaudepilgrim/claude-code-android)

Choose Path A only if you're tight on storage, or on Android 8/10 where the native binary trips Android's seccomp filter anyway.

---

## Two ways to follow this

**Manual (recommended the first time).** Chapters 1–6 below. Every command explained, and you'll understand what broke when something breaks.

**Automated.** [`setup.sh`](setup.sh) does Chapters 1–3 — Termux packages, Ubuntu, Claude Code — unattended:

```bash
curl -fsSL https://raw.githubusercontent.com/iAmAjayTeli/claude-code-android/main/setup.sh -o setup.sh
cat setup.sh          # read it before running it
bash setup.sh
```

It stops there on purpose. Chapters 4–6 (9Router, providers, combos, `settings.json`) need your own API keys and a browser, so the script prints them as next steps instead of guessing. It's safe to re-run — completed steps are detected and skipped.

---

## What you need

- Any Android phone, **not rooted**, Android 8+, **aarch64** (verify with `uname -m`)
- 4GB+ RAM, **~5GB free storage** (Ubuntu alone is ~2GB)
- **Termux from [F-Droid](https://f-droid.org/packages/com.termux/) or [GitHub Releases](https://github.com/termux/termux-app/releases)** — the Play Store build is an experimental branch the Termux maintainers recommend against
- No PC. No paid Claude plan.

### How the pieces fit

```
Termux
├── session 1:  9router                      → listens on 127.0.0.1:20128
└── session 2:  proot-distro login ubuntu
                └── Ubuntu ── claude         → talks to 127.0.0.1:20128
```

9Router runs in **Termux**. Claude Code runs **inside Ubuntu**. proot doesn't isolate the network, so `127.0.0.1` inside Ubuntu still reaches the proxy running in Termux.

> Two consequences that catch people out:
> - Ubuntu has its **own home directory**. `~/.claude/settings.json` must be created *inside* Ubuntu — a copy in Termux's home is invisible to Claude Code.
> - Node.js is needed in **Termux** (for 9Router), not in Ubuntu.

---

## Chapter 1 — Prepare Termux

```bash
pkg update && pkg upgrade -y
pkg install proot-distro nodejs -y
```

Press `y` if prompted about package maintainer configurations.

`proot-distro` runs the Ubuntu container. `nodejs` is for 9Router, which stays on the Termux side.

```bash
uname -m        # must print aarch64
node -v         # confirms Node is ready for 9Router
```

## Chapter 2 — Install Ubuntu

```bash
proot-distro install ubuntu
```

2–5 minutes depending on connection speed. Then log in:

```bash
proot-distro login ubuntu
```

The prompt changes from `~ $` to something like `root@localhost:~#`. **You are now inside Ubuntu.** Everything in Chapter 3 runs here.

Leave Ubuntu with `exit`. Get back in with `proot-distro login ubuntu`.

## Chapter 3 — Install Claude Code (inside Ubuntu)

```bash
apt update && apt upgrade -y
apt install -y curl git wget build-essential
```

Then Anthropic's official installer:

```bash
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
claude --version
```

That's the real installer from Anthropic — no patching, no community shim. It installs a standalone binary, which is why **you don't need Node.js inside Ubuntu.**

> **Skip the `nodesource` step some guides include here.** `curl -fsSL https://nodesource.com | bash -` is not a setup script — `nodesource.com` is just a website, so that command pipes a web page into bash and accomplishes nothing. Claude Code doesn't need Node in Ubuntu regardless. If you want Node for your own projects, use [NodeSource's actual instructions](https://github.com/nodesource/distributions).

## Chapter 4 — Install 9Router (back in Termux)

9Router gives you one local endpoint that fans out to multiple free providers, with fallback when one runs dry.

Leave Ubuntu (`exit`), or open a fresh Termux session — swipe from the left edge → **New session**:

```bash
npm install -g 9router
9router
```

The proxy starts on `http://localhost:20128`. **Leave this session running.** Close it and the proxy dies, and Claude Code stops working.

## Chapter 5 — Configure providers and combos

Open `http://localhost:20128` in your phone's browser.

Default dashboard password: `123456`

> **Change this password.** It's a published default. Low risk while it only listens on localhost on your own phone — a real problem the moment that port is reachable from another device. Change it before you join any shared or public network.

Add your free providers, then build a **combo**: a priority-ordered list of them. Name it `claude-opus-free`. See [`free-api-options.md`](free-api-options.md) for ordering logic and why a second combo for the Haiku tier is worth making.

## Chapter 6 — Point Claude Code at 9Router (inside Ubuntu)

Back into Ubuntu, in your other session:

```bash
proot-distro login ubuntu
mkdir -p ~/.claude
nano ~/.claude/settings.json
```

**This has to be Ubuntu's home directory, not Termux's.** Claude Code runs inside Ubuntu and only reads the config there. A `settings.json` sitting in Termux's `~` is silently ignored — expect this to be the most common mistake for anyone following along.

Paste, then `Ctrl+O`, `Enter`, `Ctrl+X`:

```json
{
  "hasCompletedOnboarding": true,
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:20128/v1",
    "ANTHROPIC_AUTH_TOKEN": "sk_9router",
    "ANTHROPIC_DEFAULT_FABLE_MODEL": "claude-opus-free",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-free",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-opus-free",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-opus-free"
  }
}
```

Four things in here that matter:

- **`127.0.0.1`, not `localhost`.** `localhost` can resolve to IPv6 `::1` while 9Router listens on IPv4 only — you get connection refused for no obvious reason. Use the numeric address.
- **`/v1` on the end of the base URL.** Without it the API paths don't line up and every request fails.
- **`hasCompletedOnboarding: true`** skips Claude Code's login flow. You're authenticating against your own local proxy rather than Anthropic, so this is what stops it demanding a Claude account.
- **`sk_9router`** is the local proxy's own token, not a real Anthropic key. Nothing secret — safe in a public repo. If you set a custom token in the dashboard, use that instead.

**`claude-opus-free` is a 9Router combo name, not a model name.** You create the combo in the dashboard; Claude Code just asks for `claude-opus-free`, and 9Router picks the first available provider in the list, falling through when one is rate-limited or down. Claude Code never knows.

So the name here must match the dashboard **exactly**. That's the most common silent failure in this setup.

### Optional: a second combo for the Haiku tier

All four aliases above point at one combo, which works. But Claude Code fires a constant stream of *small* background calls at the **Haiku** tier — file reads, summaries, tool routing, context compaction — and comparatively few at Opus/Sonnet, though those few are the real work.

Point everything at one combo and the background noise burns through your best providers before you've built anything. Make a second combo ordered by *limit generosity* rather than model quality:

```json
"ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-haiku-free"
```

Verify:

```bash
claude
```

---

## Daily use

Two Termux sessions, swipe from the left edge to switch:

| Session | Command |
|---|---|
| 1 | `9router` — leave running |
| 2 | `proot-distro login ubuntu` → `claude` |

See [`troubleshooting.md`](troubleshooting.md) for keyboard setup, session persistence, and battery survival.

---

## Honest limits

- Ubuntu costs ~2GB of storage. That's the price of the version that actually works.
- proot adds syscall-translation overhead. Noticeable on older devices, not prohibitive.
- Free provider tiers have rate limits. 9Router's fallback softens this, it doesn't remove it.
- Long agentic tasks drain battery fast. Stay plugged in for heavy work.
- Big repos are slow on phone hardware; this shines for small-to-medium projects.
- **Anthropic's official mobile path** (Claude Code Remote Control) needs a PC running *and* a Pro/Max plan. This setup needs neither — that's the whole point.

## Credits

Path comparison and the native-install alternative: [`ferrumclaudepilgrim/claude-code-android`](https://github.com/ferrumclaudepilgrim/claude-code-android) · Container: [proot-distro](https://github.com/termux/proot-distro) · Proxy: [9Router](https://www.npmjs.com/package/9router)
