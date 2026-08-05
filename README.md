# Claudme (tamagotchi)

One desktop pet per running Claude Code session. Little Claude sparks float and roam your
whole screen — the spark spins faster while Claude works (like the TUI spinner), they hop
and show "!" when a session needs you, throw confetti when a turn finishes, and drift down
to sleep at the bottom when idle for long.

Native Swift/AppKit. No Electron. No macOS permissions needed. Fully click-through —
pets never steal your clicks.

## Build & run

```bash
./build.sh
open build/Claudme.app
```

A `✳ N` item appears in the menubar (N = live sessions). Pets appear at the bottom
of the main screen within ~1 s.

## Live reactions (hooks)

The registry alone gives pets + idle/busy/waiting states (1 s lag). For instant
celebrations + confetti on turn completion, install the hooks:

```bash
build/Claudme.app/Contents/MacOS/Claudme --install-hooks
```

or use the menubar menu → *Install Claude Code hooks*.

This merges `command` hooks (a 1-line `curl` to `127.0.0.1:48291`, loopback only) into
`~/.claude/settings.json` for: `SessionStart`, `UserPromptSubmit`, `Stop`, `Notification`,
`SessionEnd`. A backup is written to `~/.claude/settings.json.bak-claudme` first.
Already-running sessions pick hooks up after a restart; new sessions get them immediately.

Uninstall: `… --remove-hooks` (or the menu item). Then quit the app and delete the folder.

## How it works

- `~/.claude/sessions/<pid>.json` — Claude Code's own per-session registry
  (`name`, `cwd`, `status: idle|busy|waiting`, timestamps). Polled at 1 Hz,
  dead PIDs filtered with `kill(pid, 0)`.
- Hooks POST their stdin JSON to the app's loopback HTTP listener.
- One transparent overlay window, one layer-backed view per pet, Core Animation
  for everything else.

## Known limits (v0)

- Main display only.
- The sessions registry is an undocumented Claude Code internal — a CC update may
  change it (parser is defensive, worst case pets just don't appear).
- Not for distribution as-is: the mascot/name are Claude-flavored; swap them for
  original ones before shipping (see docs/superpowers/specs/).
