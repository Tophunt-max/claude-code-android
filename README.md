<div align="center">

# Claude Code on Android

**The real Claude Code, running on an unrooted phone. No PC, no root, no paid plan.**

Termux → proot-Ubuntu → Claude Code, with free model access through a local [9Router](https://www.npmjs.com/package/9router) proxy.

![Android 8+](https://img.shields.io/badge/Android-8%2B-3DDC84?logo=android&logoColor=white)
![No root](https://img.shields.io/badge/root-not%20needed-success)
![Cost](https://img.shields.io/badge/cost-free-blue)
![Arch](https://img.shields.io/badge/arch-aarch64-lightgrey)
![Disk](https://img.shields.io/badge/disk-~5GB-orange)

Companion repo for the [DevZoneX](https://www.youtube.com/@DevZoneX) video. The chapters here match the chapters on screen.

</div>

> [!NOTE]
> **Verified 2026-07-26** on an unrooted aarch64 Android phone.
> Free provider tiers change often. If a step breaks: [`free-api-options.md`](free-api-options.md), then [`troubleshooting.md`](troubleshooting.md).

---

## Contents

| | |
|---|---|
| [How the pieces fit](#how-the-pieces-fit) | The one thing to understand before you start |
| [What you need](#what-you-need) | Requirements, and the Termux build that actually works |
| [Quick start](#quick-start-scripted) | `setup.sh` — Chapters 1–3, unattended |
| [Full walkthrough](#full-walkthrough) | Chapters 1–6, every command explained |
| [Daily use](#daily-use) | The two-session routine |
| [Why proot-Ubuntu](#why-proot-ubuntu-and-not-the-native-install) | And why the easier-looking path breaks |
| [Honest limits](#honest-limits) | What this setup is bad at |

---

## How the pieces fit

```
Termux
├── session 1:  9router                      → listens on 127.0.0.1:20128
└── session 2:  proot-distro login ubuntu
                └── Ubuntu ── claude         → talks to 127.0.0.1:20128
```

9Router runs in **Termux**. Claude Code runs **inside Ubuntu**. proot doesn't isolate the network, so `127.0.0.1` inside Ubuntu still reaches the proxy running in Termux.

**Always know which shell you're in.** Most problems in this stack are the right command in the wrong environment:

| Prompt | You're in | What lives here |
|---|---|---|
| `~ $` | Termux | `9router`, `node`, `proot-distro` |
| `root@localhost:~#` | Ubuntu | `claude`, `~/.claude/settings.json` |

> [!IMPORTANT]
> Ubuntu has its **own home directory**. `~/.claude/settings.json` has to be created *inside* Ubuntu — a copy in Termux's home is silently ignored, with no error.
>
> Node.js is needed in **Termux** (for 9Router), not in Ubuntu.

---

## What you need

| | |
|---|---|
| **Phone** | Any Android 8+, **not rooted** |
| **CPU** | `aarch64` — check with `uname -m` |
| **RAM** | 4GB or more |
| **Storage** | ~5GB free (Ubuntu alone is ~2GB) |
| **App** | Termux from [F-Droid](https://f-droid.org/packages/com.termux/) or [GitHub Releases](https://github.com/termux/termux-app/releases) |
| **Not needed** | A PC, a paid Claude plan, root |

> [!WARNING]
> **Don't use the Play Store build of Termux.** It's an experimental branch the Termux maintainers recommend against, and it's the single most common cause of "nothing works." Uninstall it and install from F-Droid or GitHub Releases.

---

## Quick start (scripted)

[`setup.sh`](setup.sh) does Chapters 1–3 — Termux packages, Ubuntu, Claude Code — unattended:

```bash
curl -fsSL https://raw.githubusercontent.com/iAmAjayTeli/claude-code-android/main/setup.sh -o setup.sh
cat setup.sh          # read it before you run it
bash setup.sh
```

Tested on a clean run: freshly wiped Termux → working `claude` inside Ubuntu, no manual fixes needed. Safe to re-run too — completed steps are detected and skipped.

It stops after Chapter 3 on purpose. Chapters 4–6 (9Router, providers, combos, `settings.json`) need your own API keys and a browser, so the script prints them as next steps instead of guessing.

> [!TIP]
> Do it manually the first time anyway. When something breaks later — and on free tiers it will — you'll know which piece to look at.

---

# Full walkthrough

## Chapter 1 — Prepare Termux

> Runs in **Termux** — prompt `~ $`

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

> Runs in **Termux**

```bash
proot-distro install ubuntu
```

2–5 minutes depending on connection speed. Then log in:

```bash
proot-distro login ubuntu
```

The prompt changes from `~ $` to something like `root@localhost:~#`. **You are now inside Ubuntu.** Everything in Chapter 3 runs here.

Leave Ubuntu with `exit`. Get back in with `proot-distro login ubuntu`.

## Chapter 3 — Install Claude Code

> Runs **inside Ubuntu** — prompt `root@localhost:~#`

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

> [!TIP]
> **Skip the `nodesource` step some guides put here.** `curl -fsSL https://nodesource.com | bash -` is not a setup script — `nodesource.com` is just a website, so that command pipes a web page into bash and accomplishes nothing. If you want Node for your own projects, use [NodeSource's actual instructions](https://github.com/nodesource/distributions).

## Chapter 4 — Install 9Router

> Back in **Termux** — prompt `~ $`

9Router gives you one local endpoint that fans out to several free providers, falling through to the next one when one runs dry.

Leave Ubuntu (`exit`), or open a fresh Termux session — swipe from the left edge → **New session**:

```bash
npm install -g 9router
9router
```

The proxy starts on `http://localhost:20128`. **Leave this session running.** Close it and the proxy dies, and Claude Code stops working.

## Chapter 5 — Configure providers and combos

Open `http://localhost:20128` in your phone's browser. Default dashboard password: `123456`

> [!CAUTION]
> **Change that password.** It's a published default. Low risk while the proxy only listens on localhost on your own phone — a real problem the moment that port is reachable from another device. Change it before you join any shared or public network.

Add your free providers, then build a **combo**: a priority-ordered list of them. Name it `claude-opus-free`.

See [`free-api-options.md`](free-api-options.md) for ordering logic and why a second combo is worth making.

## Chapter 6 — Point Claude Code at 9Router

> Runs **inside Ubuntu** — in your other session

```bash
proot-distro login ubuntu
mkdir -p ~/.claude
nano ~/.claude/settings.json
```

> [!IMPORTANT]
> **This has to be Ubuntu's home directory, not Termux's.** Claude Code runs inside Ubuntu and only reads the config there. A `settings.json` sitting in Termux's `~` is silently ignored — no error, nothing works. Expect this to be the most common mistake for anyone following along.

Paste this, then `Ctrl+O`, `Enter`, `Ctrl+X`:

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

Four things in there that matter:

| | |
|---|---|
| **`127.0.0.1`, not `localhost`** | `localhost` can resolve to IPv6 `::1` while 9Router listens on IPv4 only — connection refused for no obvious reason. Use the numeric address. |
| **`/v1` on the end** | Without it the API paths don't line up and every request fails. |
| **`hasCompletedOnboarding`** | Skips Claude Code's login flow. You're authenticating against your own local proxy, so this is what stops it asking for a Claude account. |
| **`sk_9router`** | The local proxy's own token, not a real Anthropic key. Nothing secret — safe in a public repo. If you set a custom token in the dashboard, use that instead. |

> [!IMPORTANT]
> **`claude-opus-free` is a 9Router combo name, not a model name.** You create the combo in the dashboard; Claude Code just asks for `claude-opus-free`, and 9Router picks the first available provider in the list, falling through when one is rate-limited or down. Claude Code never knows.
>
> So the name here has to match the dashboard **exactly**. That's the most common silent failure in this setup.

Then start it:

```bash
claude
```

<details>
<summary><b>Optional: a second combo for the Haiku tier</b></summary>

<br>

All four aliases above point at one combo, which works. But Claude Code fires a constant stream of *small* background calls at the **Haiku** tier — file reads, summaries, tool routing, context compaction — and comparatively few at Opus/Sonnet, though those few are the real work.

Point everything at one combo and the background noise burns through your best providers before you've built anything. Make a second combo ordered by *limit generosity* rather than model quality, and map only Haiku to it:

```json
"ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-haiku-free"
```

</details>

---

## Daily use

Two Termux sessions, swipe from the left edge to switch:

| Session | Command | |
|---|---|---|
| 1 | `9router` | leave it running |
| 2 | `proot-distro login ubuntu` → `claude` | do your work here |

See [`troubleshooting.md`](troubleshooting.md) for keyboard setup, session persistence, and battery survival.

---

## Why proot-Ubuntu, and not the native install

There are two ways to get Claude Code onto Android. **The simpler-looking one is the one that breaks.**

| | Native Termux (Path A) | proot-Ubuntu (Path B) — this repo |
|---|---|---|
| How it works | Patches Anthropic's `linux-arm64` binary to run against Termux's `glibc-runner` | Real Ubuntu userland inside Termux, running Anthropic's own installer |
| Disk | ~230MB | ~2GB |
| Setup time | 5–10 min | 10–15 min |
| When it goes wrong | Sandbox errors, `EACCES` on file writes, hangs | Behaves like ordinary Linux |
| Pick it when | You're tight on storage | Default |

Anthropic ships Claude Code as a glibc-linked binary with no Android build, and Termux runs on Android's Bionic libc. Path A is a shim over that gap, so the filesystem and `process.platform` don't behave the way Claude Code expects. Path B removes the gap: as far as Claude Code can tell, it *is* ordinary Linux.

The maintainer of the Path A installer recommends the same:

> "Native Termux (Path A) works and is great for those who need it, especially with hardware or storage limitations. I highly recommend running it in proot-Ubuntu (Path B) though: it is the most native way I could get it running since the 2.1.112 regression."
>
> — [ferrumclaudepilgrim/claude-code-android](https://github.com/ferrumclaudepilgrim/claude-code-android)

Choose Path A only if you're tight on storage, or on Android 8/10 where the native binary trips Android's seccomp filter anyway.

---

## Honest limits

- Ubuntu costs ~2GB of storage. That's the price of the version that actually works.
- proot adds syscall-translation overhead. Noticeable on older devices, not prohibitive.
- Free provider tiers have rate limits. 9Router's fallback softens this, it doesn't remove it.
- Long agentic tasks drain battery fast. Stay plugged in for heavy work.
- Big repos are slow on phone hardware. This shines for small-to-medium projects.
- **Anthropic's official mobile path** (Claude Code Remote Control) needs a PC running *and* a Pro/Max plan. This setup needs neither — that's the whole point.

---

## What's in this repo

| File | |
|---|---|
| [`setup.sh`](setup.sh) | Automates Chapters 1–3. Idempotent, no 9Router. |
| [`free-api-options.md`](free-api-options.md) | Providers, combo ordering, and why two combos beat one |
| [`troubleshooting.md`](troubleshooting.md) | Failure modes, each tagged with the shell it happens in |

## Credits

Path comparison and the native-install alternative: [`ferrumclaudepilgrim/claude-code-android`](https://github.com/ferrumclaudepilgrim/claude-code-android) · Container: [proot-distro](https://github.com/termux/proot-distro) · Proxy: [9Router](https://www.npmjs.com/package/9router)

Hit an error that isn't documented? Open an issue — [`troubleshooting.md`](troubleshooting.md) is meant to grow.

Licensed [MIT](LICENSE).
