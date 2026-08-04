# ClaudePet — design (v0)

One desktop pet per running Claude Code session, walking along the bottom of the screen.
Native Swift/AppKit menubar app, no Electron, no permissions needed.

## Why per-session

Every competitor (Codogotchi, AgentPet, OpenPets…) shows one global pet or one per project.
Nobody maps pets 1:1 to terminal sessions — yet that's the actual pain: "which of my 5 agents
just finished / needs input / died?" The pet is a status UI for multi-agent work, the cuteness
is the delivery vehicle.

## Data sources (two channels, complementary)

1. **Session registry — source of truth for existence + coarse state.**
   `~/.claude/sessions/<pid>.json`, one file per live CLI session, written by Claude Code itself.
   Confirmed live fields: `pid`, `sessionId`, `cwd`, `name` (e.g. `advocate-98`), `status`
   (**idle / busy / waiting**, confirmed by observing a mid-turn session), `updatedAt`,
   `statusUpdatedAt`. Polled at 1 Hz; stale files filtered via `kill(pid, 0)`.
   *Risk: undocumented internal format — parse defensively, degrade gracefully.*

2. **Hooks — real-time spark.** Installed into `~/.claude/settings.json` (with backup) as
   `command` hooks that `curl` the event JSON to a loopback HTTP server in the app
   (`127.0.0.1:48291`, port file fallback). Events: `SessionStart`, `UserPromptSubmit`,
   `Stop` (the money shot → celebration + confetti), `Notification` (needs input),
   `SessionEnd`. App works without hooks (registry only), gets snappier with them.

## Rendering

- One borderless transparent **overlay window** covering the main screen,
  `ignoresMouseEvents = true` (fully click-through — sidesteps the macOS 26 transparent-window
  hit-testing bug), `.floating` level, joins all Spaces + fullscreen.
- Each pet = a layer-backed `NSView` inside the overlay. Body is a code-drawn orange starburst
  (Claude-style asterisk) with capsule eyes + smile; no image assets.
- Walk = 30 fps frame-origin updates along `visibleFrame.minY` (on top of the Dock);
  bob/wobble/blink/breathe = repeating Core Animation; confetti = `CAEmitterLayer`.
- Name pill under each pet = session `name` from the registry.

## State mapping (hybrid: small when idle, big on events)

| session state | pet |
|---|---|
| `idle` | small (0.72×), strolls occasionally, blinks |
| `idle` > 10 min | sleeping, "z Z" bubble |
| `busy` (or UserPromptSubmit pulse) | full size, paces fast, "…" chatter |
| `waiting` / Notification | stands, hops every ~2.5 s, "!" bubble |
| Stop hook | 1.3×, double jump, confetti, "✓" — 3.2 s, then back |
| SessionEnd / dead pid | fade out |

## Non-goals in v0

Multi-display, AX terminal-window following, sounds, login item, persistence/XP,
custom skins. All are v1+ candidates.

## Shipping note

Current mascot is deliberately Claude-flavored for the personal prototype. Before any public
distribution the mascot and name must be replaced with original ones (Anthropic trademark
guidelines require prior approval; "works with Claude Code" text mention is the industry norm).
