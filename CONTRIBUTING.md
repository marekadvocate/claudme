# Contributing to Claudme

No dependencies, no package manager, no project file. `./build.sh` compiles every
`.swift` in `Sources/` into an app bundle. If you have Xcode command line tools, you
can build.

```bash
./build.sh && open build/Claudme.app
```

## Where things live

| file | what it does |
|---|---|
| `SessionRegistry.swift` | polls `~/.claude/sessions/*.json`, reads the model from the transcript |
| `HookServer.swift` | loopback HTTP listener that Claude Code hooks post to |
| `HooksInstaller.swift` | merges/removes our hooks in `~/.claude/settings.json` |
| `PetManager.swift` | one overlay window per display, spawning and ambient behaviour |
| `PetView.swift` | a single crab: pixel geometry, states, animations, click handling |
| `Naming.swift` | ranks, eras, made names |
| `Quips.swift` | everything a crab can say, per language |
| `StatusItemController.swift` | the menubar menu |
| `TerminalFocus.swift` | walks the process tree to find and raise a session's terminal |

## Good first contributions

**Add a language.** One entry in the `table` in `Quips.swift` plus a case in `Lang`.
Write the lines in the voice of a made man reporting to his boss — they should be
funny in *your* language, not translated word for word.

**Add an idle behaviour.** Look at `beerBreak()` and `doTrick()` in `PetView.swift`
for the shape: pick a duration, suspend crawling, add layers, clean them up. Keep it
rare — anything a user sees more than a few times an hour becomes noise.

**Add an era.** `Era` in `Naming.swift` needs given names; the matching skin work
lives in `PetView`'s pixel cell tables.

## House rules

- **No image assets.** Every pixel is drawn in code. It keeps the app tiny and makes
  crabs scale cleanly on any display.
- **Never block Claude Code.** The hook command must always exit 0 and time out fast.
- **Parse defensively.** The session registry is an internal Claude Code detail. If a
  field is missing or changes shape, degrade quietly — never crash, never spam.
- **Stay out of the way.** Overlays are click-through except directly over a crab.
  No permissions, no network beyond loopback, no telemetry.
- Match the surrounding style: comments explain *why*, not *what*.

## Testing your change

There is no test suite; verify by running it. Setting `CLAUDME_DEBUG=1` enables a
`GET /snapshot` endpoint that renders the overlays to
`~/Library/Application Support/Claudme/snapshot.png`, which is useful for checking
layout without screen-recording permission:

```bash
CLAUDME_DEBUG=1 ./build/Claudme.app/Contents/MacOS/Claudme &
curl -s localhost:48291/snapshot
open ~/Library/Application\ Support/Claudme/snapshot.png
```

You can also fire a fake hook event at a real session id:

```bash
curl -s -X POST --data-binary \
  '{"hook_event_name":"Stop","session_id":"<id from ~/.claude/sessions>"}' \
  localhost:48291/hook
```
