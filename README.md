<div align="center">

<img src="assets/logo.png" width="140" alt="Claudme">

# Claudme

**Your AI coding agents are a crime family. Now you can see them.**

One pixel crab per running Claude Code session, crawling the edges of your screen.
They earn ranks, wear the family colours, celebrate finished work, take beer breaks,
and jump you to the right terminal when you click them.

Native Swift. No Electron. No permissions. ~3 MB.

</div>

---

## Why

If you run one agent, you don't need this. If you run six, you know the problem:

> Which one just finished? Which one is waiting on permission? Which one died on a rate limit?

Claudme puts the answer in your peripheral vision. Every session becomes a crab on the
edge of your screen. You stop alt-tabbing through terminals to find out who needs you.

The crime family part is because it's more fun that way.

## Install

Requires macOS 13+ and Xcode command line tools (`xcode-select --install`).

```bash
git clone https://github.com/marekadvocate/claudme.git
cd claudme
./build.sh
open build/Claudme.app
```

A `🦀 N` appears in your menubar, where N is the number of live sessions. Crabs show up
along your screen edge within a second.

To make the crabs react the *instant* a turn ends, install the hooks — menubar →
**Live reactions**, or:

```bash
build/Claudme.app/Contents/MacOS/Claudme --install-hooks
```

This merges a one-line `curl` hook into `~/.claude/settings.json` for ten events, after
backing the file up to `settings.json.bak-claudme`. The `curl` only ever talks to
`127.0.0.1` and always exits 0, so it can never block or slow down Claude Code.
Sessions already running pick the hooks up after a restart.

Uninstall: menubar → **Live reactions** again (or `--remove-hooks`), then quit and
delete the folder. Nothing else is left on your machine.

## What the crabs tell you

| you see | it means |
|---|---|
| crab strolling slowly, small | session idle |
| crab hurrying, full size, steam off its head | session working (steam = `xhigh`/`max` effort) |
| crab stops and hops, `!` bubble | **waiting for you** — permission or input |
| jump, confetti, *"It's done, boss."* | turn just finished |
| curled up on the bottom edge, `z Z` | idle more than 10 minutes |
| ⚠️ bubble | rate limit or API error |
| little crabs bobbing alongside | that session's subagents |
| 🕶️ black shades | `--dangerously-skip-permissions` |
| 🤓 round glasses | plan mode |
| 🛰️ orbiting satellite | remote / bridged session |

**Click a crab** and the terminal running that session comes to the front.
**Right-click** for its working directory and status.

## The family

Every session is a made man. The name is stable — the same session name always produces
the same crab.

```
Don Vito Opus          ← rank · given name · family
```

- **Rank** is earned by staying alive: Picciotto (< 10 min) → Soldato (< 1 h) → Capo (< 4 h) → **Don**
- **Given name** comes from one of six eras, hashed from the session name:
  Roman, Medieval, Renaissance, Prohibition, Yakuza, Syndicate
- **Family** is the model — Opus, Fable, Sonnet, Haiku
- **Fedora colour** is unique among your live crabs, and matches the dot in the menubar

Bigger models are bigger, darker crabs. The higher your effort setting, the more wired
they get: dilated eyes, jitter, and steam while they work.

They also have lives of their own. They greet each other in passing, take a beer break
every few minutes, clink glasses if a neighbour is close, occasionally take a balloon
ride when bored, and do a stadium wave when the last busy session finishes.

## Languages

English, Slovak and Czech, picked in the menubar. Defaults to your system language.
Adding one is a single entry in [`Sources/Quips.swift`](Sources/Quips.swift) — PRs very welcome.

## How it works

Two independent channels, so it degrades gracefully:

1. **Session registry** — Claude Code maintains `~/.claude/sessions/<pid>.json` for every
   live CLI session, with its name, working directory and status. Polled once a second;
   dead PIDs are filtered with `kill(pid, 0)`. This alone gives you crabs and their
   idle/busy/waiting states, with no hooks installed at all.
2. **Hooks** — for instant reactions, each hook `curl`s its event JSON to a loopback
   listener on `127.0.0.1:48291`.

The model is read from the tail of the session transcript, cached by file stamp.

Rendering is one borderless, transparent, click-through `NSWindow` per display, sitting
one level above the Dock so crabs walk in front of it. Each crab is a layer-backed
`NSView` drawn entirely in code — there are no image assets in this repo. Movement is
constrained to the screen's perimeter ring, with the body rotating so the legs always
face the edge.

> The session registry is an internal Claude Code detail, not a public API. The parser is
> defensive — if a future version changes the format, the crabs simply don't appear.

## Known limits

- macOS only. The rendering is AppKit and the process-tree walk is BSD `sysctl`.
- Terminal *tabs* can't be told apart — clicking a crab raises the window, not the tab.
- Sessions started before the hooks were installed need a restart to get live reactions.

## Contributing

Issues and PRs welcome — especially new languages, new idle behaviours, and era skins.
Everything is plain Swift with no dependencies; `./build.sh` is the whole build system.

## Licence

MIT — see [LICENSE](LICENSE).

---

<div align="center">
<sub>

Works with **Claude Code**. Not affiliated with, endorsed by, or sponsored by Anthropic.

</sub>
</div>
