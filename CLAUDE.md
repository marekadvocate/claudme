# Claudme — working rules

## Docs are part of the change, not a follow-up

Every change that adds, removes or alters something a user can see or run **must land
with its documentation in the same commit**. A feature that only exists in the source is
not finished.

When you add or change a behaviour, walk this list and update every entry that applies:

| what changed | update |
|---|---|
| a crab behaviour, state or prop | `README.md` — "What the crabs tell you" table **and** "A life of their own" |
| a Playground effect | `README.md` menubar table, and the effect list in `docs/index.html` |
| a hook event | `README.md` "How it works", and `HooksInstaller.events` |
| a `QuipKind` | every language in `Sources/Quips.swift`, and the language count wherever it is quoted |
| a menubar item | `README.md` menubar table |
| anything on the site | `docs/index.html`, and re-run `docs/make-og.sh` if the hero changed |
| a new source file | the source map table in `README.md` |
| a promo behaviour | `promo/` beat sheets, and re-render both cuts |

Numbers quoted in prose (language counts, effect counts, line counts) are facts that go
stale silently. Grep for the old number before you leave.

## Before saying something works

- `./build.sh` must pass. A warning-free build is not proof the behaviour fires.
- `docs/check.sh` must pass for any edit to `docs/index.html`. The script is inline, so a
  syntax error is invisible until a browser loads it — and a single duplicate `const` has
  already silently killed every feature on the page once.
- For timed behaviour, work out the real odds from the actual intervals before claiming a
  user will see it. "Wired" and "reachable" are different things: rope and rocket were
  correctly wired for weeks and fired about once every two hours.
- Verify by observation where you can — `CLAUDME_DEBUG=1` exposes `GET /snapshot` (renders
  the overlays to a PNG) and `GET /effect/<name>`. Say plainly when you could not observe
  something rather than implying you did.

## House rules that are deliberate

- **No image assets.** Every pixel is drawn in code, in both the app and the site.
- **Never block Claude Code.** The hook command always exits 0.
- **Parse the session registry defensively.** It is an internal Claude Code detail; if the
  format changes the crabs must simply not appear.
- **No permission prompts.** No screen recording, no accessibility, no microphone.
- **No third-party dependencies**, and no external requests from the site.
