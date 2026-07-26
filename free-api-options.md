# Free providers and 9Router combos

> [!NOTE]
> **Last verified: 2026-07-26.** Free tiers change constantly — providers tighten limits, close signups, or disappear. This file is date-stamped so you can tell at a glance whether it's still current. If something here is stale, the video's pinned comment has the latest.

---

## The approach: many providers, priority-ordered combos

Don't depend on one free tier. Configure every provider that offers a top-tier model, then build **combos** in the 9Router dashboard — ordered lists that fall through to the next provider when one is rate-limited or down. Claude Code sees one endpoint and never knows the difference.

This is the whole reason the setup is usable rather than a demo. A single free tier dies in twenty minutes of real agentic work. A five-deep combo keeps going.

---

## Build two combos, not one

The part most setups get wrong.

Claude Code fires a constant stream of *small* background calls at the **Haiku** tier — file reads, summaries, tool routing, context compaction. It sends comparatively few calls to the Opus/Sonnet tier, but those are the ones that matter. If every tier points at your best provider, the background noise exhausts that provider's quota and your real work has nowhere to go.

So build two:

| Combo | Name in `settings.json` | Mapped from | Order by |
|---|---|---|---|
| **Quality** | `claude-opus-free` | `ANTHROPIC_DEFAULT_OPUS_MODEL`, `..._SONNET_MODEL`, `..._FABLE_MODEL` | Best model first — this is where real work happens |
| **Fast / cheap** | `claude-haiku-free` | `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Most generous limits first — quality barely matters here |

Net effect: your best providers stay available for the work that needs them.

> [!IMPORTANT]
> The name in `settings.json` has to match the combo name in the dashboard **exactly**. A mismatch is the most common silent failure in this setup — no useful error, it just doesn't work.

---

## Combo ordering logic

Order by, in priority:

1. **Model quality** — the best model that's genuinely free, first
2. **Limit generosity** — a slightly weaker model with 10× the quota is worth more than a great one that dies in five minutes
3. **Reliability** — providers that 500 under load belong lower, however good the model
4. **Signup friction** — irrelevant to routing, but note it so you can start with the easy ones

> [!TIP]
> Put at least one high-limit provider at the bottom of every combo as a floor. Without it, a fully rate-limited combo returns errors and Claude Code just fails.

---

## Providers configured

> [!WARNING]
> **To be filled in from the working setup.** Provider availability, limits, and card requirements were not verified when this file was written — and unverified provider claims are exactly what fills a tutorial's comment section with "doesn't work."

| Provider | Top model available | Free limit | Card needed? | In combo | Verified |
|---|---|---|---|---|---|
| | | | | | |

Candidates noted during setup, both unverified: **Kiro AI**, **OpenCode Free**.

### Tested and currently failing

| Provider | Date | Symptom | Assessment |
|---|---|---|---|
| **Antigravity** (`ag/`) | 2026-07-27 | `403` on every request to `cloudcode-pa.googleapis.com`, preceded by `onboardUser failed after 5 attempts: no project_id in response` | Google's onboarding call returns no project ID, so the request is unauthorized. Not a quota problem — a `403`, not a `429`, so retrying doesn't help. Either 9Router's implementation has gone stale against a Google-side change, the region isn't eligible, or the account never completed Antigravity's real signup. |

Antigravity access is reverse-engineered from Google's own client, so it breaks whenever Google changes that flow. Treat it as a bonus, never as a combo's floor.

### Quality combo

Fill in once tested:

1.
2.
3.

### Fast / cheap combo

1.
2.
3.

---

## Why not local models (Ollama)

Other Android tutorials point Claude Code at a local Ollama model (Llama 3.2, Qwen 2.5) running on the phone. Avoid it as the default:

- 3B-class models on phone hardware are slow and produce weak code. Fine for a demo, poor for real work.
- Battery and thermal cost is significant.
- Claude Code's agentic loop makes many calls, and weak-model errors compound across them.

Local **is** the right answer when you need to work offline, or can't send code to a third party at all.

---

## Security notes

- **The 9Router dashboard default password is `123456`.** Change it. Low risk while the proxy is localhost-only on your own phone; a real exposure the moment that port is reachable on shared Wi-Fi.
- **Provider API keys live in the 9Router config on your phone.** Anyone with the device has them. If you're recording your screen, blur the key fields and rotate the keys afterwards.
- `sk_9router` in `settings.json` is the local proxy's own token, not a real API key — safe in a public repo.

---

## Keeping this current

Re-check monthly, or whenever someone reports a dead provider, and update the date stamp at the top. A stamped file turns tier decay into a reason to revisit the repo rather than a dead comment thread.
