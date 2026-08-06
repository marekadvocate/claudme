{
 "copy": {
  "xPost": "I run six Claude Code sessions and can never tell which one is waiting on me.\n\nNow each one is a pixel crab on the edge of my screen. Hops when it needs permission, sleeps when idle.\n\nFree, MIT, native Swift, ~3MB. Not an Anthropic product.\n\nmarekadvocate.github.io/claudme",
  "xThread": [
   "What you read out of the corner of your eye:\n\nstrolling small = idle\nhurrying, full size = working\nstops and hops = waiting on you\nconfetti = turn finished\ncurled up asleep = idle 10+ min\nwarning triangle = rate limit\n\nClick a crab, its terminal comes forward.",
   "Each session is a made man with a stable name: Don Vito Opus IX.\n\nRank is earned by uptime — Picciotto under 10 min, Soldato under an hour, Capo under four, then Don. Family is the model. Era is one of six, each with its own hat.\n\nSame session, same crab, every time.",
   "How it works: Claude Code keeps a live session file per PID in ~/.claude/sessions. Poll it once a second and you know who is alive, busy or waiting. Optional hooks curl to 127.0.0.1 for instant reactions.\n\nNo screen recording, no accessibility prompt. It never blocks the CLI.",
   "There is not a single image asset in the repo. Every crab is drawn in code — no Electron, about 3 MB.\n\nWhen anything plays audio on the Mac the family dances: the shell comes apart into pixel cubes and a wave runs through them. You can switch that off.",
   "Nineteen languages, none of them translations — each written in its own crime-fiction register, plus a street-talk mode that swears.\n\nMIT and free. Not made by, endorsed by or affiliated with Anthropic — I just use their CLI a lot.\n\ngithub.com/marekadvocate/claudme"
  ],
  "tiktokCaption": "six terminals, six spinners, nothing to look at. so every Claude Code session is now a crab crawling the edge of my screen — it hops when it wants permission, throws confetti when it finishes, falls asleep when you forget about it. free and open source, mac only, no permissions, about 3 MB. not an Anthropic product, just a thing I built. link in bio",
  "hashtags": [
   "#claudecode",
   "#opensource",
   "#macos",
   "#swift",
   "#devtools",
   "#pixelart",
   "#buildinpublic",
   "#ai"
  ],
  "hnTitle": "Show HN: Claudme – a pixel crab per Claude Code session on your screen edge",
  "firstComment": "I run five or six Claude Code sessions at once and kept losing track of which one had stopped to ask me something. The state exists — it's just buried in whichever terminal is behind the others.\n\nSo the state lives on the screen edge now. One crab per session, walking the perimeter, never on top of your work. It hops with a \"!\" when it wants permission, throws confetti when a turn ends, curls up after ten idle minutes, shows a warning bubble on a rate limit, chews and burps while compacting. Click a crab and that session's terminal comes to the front.\n\nHow it works: Claude Code writes a small JSON file per live session under ~/.claude/sessions with name, cwd, start time and status. Polling that once a second gives you everything above with no hooks at all; dead PIDs get filtered with kill(pid, 0). For instant reactions there are optional hooks that curl their event JSON to a loopback listener on 127.0.0.1:48291 — they always exit 0 so they can't block or slow the CLI, and settings.json is backed up before anything is merged in. The model comes from the tail of the session transcript.\n\nCaveats, since they're the interesting part: the session registry is an internal detail, not a public API, so the parser is deliberately defensive — if the format changes in a future version, the crabs simply don't appear. macOS only (AppKit rendering, BSD sysctl for the process-tree walk). Terminal tabs can't be told apart, so clicking raises the window, not the tab. Fullscreen detection got removed because no heuristic I tried could tell a fullscreen app from a maximised Chrome window.\n\nRendering is one borderless, transparent, click-through NSWindow per display, sitting one level above the Dock so the crabs walk in front of it. Every crab is drawn in code — there is not a single image asset in the repo. No Electron, about 3 MB, no permission prompts.\n\nThe crime-family part (rank by session uptime, a family per model, six era skins, nineteen languages written per-language rather than translated) is there because a progress bar with a fedora is easier to care about than a progress bar.\n\nMIT, no dependencies, no project file — build.sh is the whole build system. To be explicit: this is not an Anthropic product and I'm not affiliated with them. It's an unofficial tool that reads local files their CLI happens to write.\n\nPatches welcome. A new language is one entry in Quips.swift."
 },
 "x_board": {
  "name": "Cold Open: The Dance",
  "platform": "X",
  "lengthSeconds": 20,
  "hook": "Frame one is not a desktop — it is two pixel crabs in fedoras filling a quarter of the screen each, their flat shells tearing apart into 42-pixel cubes with a ripple running diagonally through them, hats and all. No logo, no title, no caption, no idea what you are looking at. The only thing that resolves it is the next two seconds.",
  "why": "The old cut opened wide on a cluttered dev desktop where the crabs were 5% of frame height — roughly 10px on a phone — and buried its only genuine scroll-stopper two-thirds in. This opens on that visual at 3x nearest-neighbour scale, so the thing you cannot place is physically large, and then the wide reveal lands as the answer rather than as a set-up. Every caption is a crab's own line quoted verbatim in the upper half of frame, so the jokes survive mute, a 200px mobile player, and the fact that an 11pt speech bubble is unreadable at any crop. It ends on the funniest line in the product over a crab still walking, not on a static URL card nobody types from.",
  "shots": [
   {
    "t": "0.0-2.6",
    "visual": "Hard in on two pixel crabs in fedoras crawling the bottom edge of a Mac screen, each about a quarter of the frame tall. Their flat shells break apart into individual pixel cubes and a ripple travels diagonally through each body — hat included — squashing and stretching while they keep walking. Above them a band of terminal text blown up far too large to read. The screen is filled with chunky, crisp pixel blocks.",
    "overlay": "",
    "note": "THE ONE-TAKE RULE IS DROPPED — every beat is its own take, matched on crop scale, cuts invisible. CAPTURE: Cmd+Shift+5, entire screen, native Retina 3024x1964 (1512x982pt @2x), Dock on auto-hide. DELIVER 1920x1080 by cropping a 640x360px window out of the full-res capture and scaling it 3x with NEAREST-NEIGHBOUR interpolation. One crab pixel is 7pt = 14 device px; x3 gives a 42px block, so the art gets crisper, not softer — smooth/bilinear scaling is the single thing that would ruin this shot. Choosing the crop in post is what unlocks the whole shoot: roaming stops being a blocking problem, you follow the crab with a crop instead of directing a camera. There is no bottom-only setting — applyPerimeterPosition() has four segments (floor, right wall, ceiling, left wall) and placeOnPerimeter() seeds a random t — so crabs WILL be on walls and the ceiling and you simply crop to wherever they are. TO GET THIS: play music out of the Mac speakers, wait ~8s, then roll 60-90s. AudioSense polls every 1.5s and setMusicPlaying sets resumeDanceAt = now + random(0...5), so crabs trickle in one at a time; stints run 25-35s. Harvest the window where two crabs are dancing within a frame-width of each other. They dance WHILE they crawl — that is the code's own behaviour, do not wait for them to stop."
   },
   {
    "t": "2.6-5.2",
    "visual": "The same recorded moment pulled all the way out to the whole desktop. Three terminal windows with live Claude Code output scrolling in two of them. Around the screen's edges, five crabs in fedoras: one at full size hurrying, two small ones strolling the other way at a visibly slower crawl, one wearing black shades, one curled up asleep under a tiny 'z Z'. All of them still rippling.",
    "overlay": "5 Claude Code sessions.\n5 crabs.",
    "note": "Same clip as shot 1 — no cut, just a single scale keyframe from the 3x crop out to full frame over 0.8s, then hold. That move is free and it is the only place the unbroken-recording feel is worth paying for. Overlay fades in at 3.2s, top-left, over a 60% black rounded pill, and lives in the UPPER half of frame so it never covers a crab. Run all five sessions for this take; every take after this uses one or two. Do not caption the speed difference: idle crawl is 24-40 pt/s and working is 90-130 pt/s (a real 3x gap you can see), but the size gap is only 0.8x vs 1.0x and is invisible — let the motion carry it and spend no words."
   },
   {
    "t": "5.2-8.6",
    "visual": "Tight again at ~2x. One crab on the bottom edge with its terminal directly above. In the terminal a real permission prompt appears — 'Do you want to proceed? 1. Yes  2. No'. The crab stops dead, hops, and a bubble opens over its head: 'Boss? A word.' It holds its ground and hops again a couple of seconds later.",
    "overlay": "\"Boss? A word.\"",
    "note": "Separate take, and from here on run EXACTLY ONE Claude Code session for every tight beat: PetManager.run() does pets.values.randomElement(), so with five sessions a hotkey effect lands on your hero crab one time in five. Trigger this beat for real rather than via an effect — have the session run a command needing approval so the terminal prompt and the crab react in the same instant. No time pressure at all: the waiting bubble is shown with duration nil, so it persists until the state changes, and the crab re-hops every 2.2-3.4s on a loop. The line is a uniform pick from five, so to get 'Boss? A word.' verbatim, approve and re-trigger — each transition into waiting re-rolls. About five goes. If a line you like better lands, rewrite the overlay to match; the overlay and the bubble must never disagree."
   },
   {
    "t": "8.6-11.4",
    "visual": "Ease back to ~1.6x so a second terminal window enters frame. The cursor slides down onto the waiting crab — it does a startled little jump and blinks — then clicks. A click ring lands on it, the crab squashes, and the window stack visibly re-orders: that session's terminal snaps to the front, its prompt now large and readable.",
    "overlay": "click him",
    "note": "Show Mouse Clicks ON for this take only. Move the cursor slowly; fast travel reads as jitter at this scale. The hover jump is free — hoverPoke() fires on cursor entry — but it has an 8s cooldown on lastPokeAt, so do not hover-test right before the roll. CRITICAL: TerminalFocus.focusApp() walks up the process tree and activates the parent APP, not the window, so put the sessions in three DIFFERENT terminal apps (Terminal, iTerm2, Ghostty) or you will front the correct app and the wrong window and the beat reads as broken."
   },
   {
    "t": "11.4-14.4",
    "visual": "Hold ~1.6x. The approved command finishes. The crab swells noticeably, double-hops, and a burst of orange, yellow, teal and pink confetti fires upward off it and falls through frame. A beat later, the bubble: 'It's done, boss.'",
    "overlay": "(nothing until 12.8, then)\n\"It's done, boss.\"",
    "note": "Real durations to cut against: hop 0.85s, body scales to 1.3x, confetti emitter births for 0.4s and the layer is removed at 2.6s, bubble holds 3.0s, the celebrating state lasts 3.2s. Deliberately run the first 1.4s with NO overlay — the confetti is the punctuation and the film needs one silent bar. HAZARD: keep a second session BUSY through this take. PetManager.sync() fires an automatic stadium wave the instant busy count drops from >0 to 0 with two or more pets and >120s since the last wave, and it will land on top of your confetti. 'It's done, boss.' is one of eight random done-lines, so bind /effect/celebrate to a hotkey and re-fire until it lands — roughly eight goes."
   },
   {
    "t": "14.4-16.4",
    "visual": "Two crabs standing close together on the bottom edge. A pixel beer mug with white foam pops into each claw, tiny bubbles rising off the foam, and the two mugs tip together. Bubble: '🍻 To the family.'",
    "overlay": "\"🍻 To the family.\"",
    "note": "Two sessions, and walk them together BEFORE triggering: maybeClink() only pulls in a second crab inside 140pt (dx²+dy² < 140²), otherwise you get one crab drinking alone. TRIGGER RIG for this and every effect: launch with CLAUDME_DEBUG=1 and bind `curl -s 127.0.0.1:48291/effect/clink` to a hotkey (HookServer.swift:84, debug-gated, same entry point the Playground menu uses). Do NOT use the Playground menubar menu on camera — it drops a submenu hundreds of points down from the menubar and lands inside any crop that includes the upper screen. Beer runs 4.6s with a three-sip tilt and the toast bubble holds 2.6s, so fire ~1.2s before the beat opens and cut in with the mugs already up. Toast is one of three lines, so this one lands fast."
   },
   {
    "t": "16.4-18.6",
    "visual": "Bottom edge, a crab curled up asleep under a small 'z Z'. It stirs, hops, and the bubble reads 'Screw this corner.' — then it shuffles off along the edge.",
    "overlay": "\"Screw this corner.\"",
    "note": "The most screenshot-able line in the product and it was missing from the last cut. It cannot be triggered — there is no grumble effect. Get it by leaving one session idle: after 10 minutes the crab sleeps and crawls to the floor (sleepingSpotT is a floor coordinate, so sleepers are reliably on the bottom edge), then rest() grumbles and relocates every ~60s it has spent parked in one patch, on a loop — once it starts you can roll until you like a take. Bubble holds 2.6s. Kill the Mac's audio well before this take or the crab is still dancing; stints run 25-35s. FLAG FOR MAREK: the brief says this line is 'Fuck this work.' It is not in the build. Quips.swift:114 has 'Screw this corner.' / 'I'm done here, boss.' / 'Somebody else can watch it.' / 'That's me for tonight.' / 'Not my problem now.', and the English street register has no grumble entry so it falls back to these. Shoot what ships, or add the line first."
   },
   {
    "t": "18.6-20.0",
    "visual": "The crab keeps shuffling along the bottom edge. The card fades up over the top half of the frame while it walks underneath. The image never freezes and never cuts to black.",
    "overlay": "CLAUDME\nyour AI agents are a crime family\nfree · open source · macOS",
    "note": "1.4s only, faded in over 0.3s, held to the last frame, upper half only so the crab stays unobstructed and visibly moving — motion under the card is what makes it read as a recording rather than an ad. NO URL on the card; nobody types a URL off a video. The link and the pitch line go in the post text above the video, which on X is read before the video even plays: 'You used to build things. Now you type a sentence, watch a spinner, and read a diff.' + github.com/marekadvocate/claudme."
   }
  ],
  "endCard": "CLAUDME — your AI agents are a crime family. Free · open source · macOS. (No URL on screen: the link and the \"you type a sentence, watch a spinner, and read a diff\" line go in the X post text, above the video.)",
  "soundIdea": "A ~143 BPM neo-noir boom-bap loop — upright bass, brushed drums, a muted trumpet stab on the turnaround — starting cold on frame one so the cut opens on a downbeat. Be honest about what the tempo buys you: it is cosmetic, not synced. danceBeat is 0.42s but setMusicPlaying re-rolls it per crab as 0.42 ± 0.05 with no audio phase reference, so no crab is ever truly on your downbeat and no two are in lockstep — a ~143 BPM bed just makes the ripple read as roughly tempo-matched to a casual viewer. Practical: music must actually play out of the Mac speakers during the capture of shots 1-2 (it is what makes them dance at all), then mute that captured audio and lay the same file in clean, aligned to the cut. Keep the raw capture audio at ~10% under the bed so terminal keystrokes are faintly there for anyone who unmutes. Silence the Mac entirely before shooting shots 6-8, or the crabs are still dancing when they should be drinking and sleeping. The video must be fully legible with sound off; nothing in it depends on audio."
 },
 "tiktok_board": {
  "name": "Your AI Agents Are a Crime Family",
  "platform": "TikTok",
  "lengthSeconds": 23.1,
  "hook": "Frame one: a pixel crab in a fedora already mid-stride along the top of the Dock icons on a real Mac desktop, \"1 Claude Code session = 1 crab\" over it. At 1.26s it cuts on the drop to the whole desktop with seven crabs dancing, then punches straight inside one as its 2D shell comes apart into pixel cubes. Recognisable desktop, unexplainable object, product claim, and feed-grade motion all inside the first two seconds.",
  "why": "The opening image is one nobody has scrolled past — a fedora'd crab walking on your own Dock — and the claim rides on it instead of costing a second of its own. Then it zooms rather than lists: one crab, all of them, inside one, so the shatter lands at readable scale in the first three seconds instead of at fifteen where nobody was left. The back half is the part that converts: a crab that stops dead because a session is waiting on you, then a real mouse click that yanks that terminal to the front — a beat that is impossible to fake and is the whole reason to install. Shot lengths run 3/2/6/6/8/4/8/10 beats so the viewer can never predict the next cut.",
  "shots": [
   {
    "t": "0.00-1.26",
    "visual": "Hard punch-in on the bottom-left of a real Mac desktop: the Dock with its real app icons, and one pixel crab in a fedora strolling left-to-right along the top edge of the icons, legs scuttling, shell in its identity colour. Already mid-stride on frame one — no fade, no title card.",
    "overlay": "centred, large: 1 Claude Code session = 1 crab",
    "note": "540x960 retina crop, nearest-neighbour 2x to 1080x1920 — NEVER bilinear, the pixel art must stay blocky. SET THE DOCK SIZE SLIDER NEAR MINIMUM BEFORE ROLLING: the overlay window sits at dockWindow+1 (PetManager.swift:18) so crabs draw in FRONT of the Dock, and roamArea.minY=-37 with the body centre at (75,60) puts the crab's head at ~44pt — a default 70-80pt Dock means the crab wades through the icons instead of walking on them. Near-black wallpaper so the identity colour reads. Cut in on a walk cycle mid-stride; legs flip every ~7px travelled."
   },
   {
    "t": "1.26-2.10",
    "visual": "Cut on the drop to the WHOLE desktop, letterboxed as a band across the middle of the frame on near-black: seven crabs strung along all four edges, every one of them dancing — bouncing, twisting, headbanging, hats lagging a beat behind the heads.",
    "overlay": "in the black above the band: when music plays on your Mac, they all dance",
    "note": "This is an 0.84s establishing flash, NOT a payoff — at 3024x1964 scaled to 1080x701 each dancer is ~29px wide, a 10pt speck on a phone, so it exists only to establish 'all of them' before the punch-in. Turn 3D/voxel mode OFF and Party mode ON. Crucially: setMusicPlaying staggers entry 0-5s and then each crab dances 25-35s before sitting out 25-35s (PetView.swift:1474,1483-1495) — every crab is only guaranteed to be moving together in the first ~25s after playback starts, so hit play, wait 7s for the audio poll (1.5s interval) plus stagger, and shoot inside that window. Caption never overlaps the desktop band."
   },
   {
    "t": "2.10-4.62",
    "visual": "Slow push into a single dancing crab: the 2D shell comes apart into its individual pixel cubes and a wave travels diagonally through them, eyes riding the same wave, the fedora lagging behind, then the cubes settle back into a crab.",
    "overlay": "caption from the previous shot holds to ~3.4, then clears",
    "note": "540x960 @2x nearest-neighbour, crab dead centre so the cubes break the silhouette. Shatter is 2D-only — guarded by !voxelMode at PetView.swift:547,1642 — so voxel mode MUST be off. applyDance() rebuilds the cubes on every move change (every danceBeat x 6-10 = 2.5-4.2s), so the wave runs continuously; point the crop at any 2D dancer and you get it. Watch out: dancing does not stop the crawl, the crab can walk off frame mid-shatter — pick an idle crab and shoot during one of its 2-7s standing pauses between decisions."
   },
   {
    "t": "4.62-7.13",
    "visual": "Two crabs on the bottom edge, close together. A beer mug springs into each one's claw, both squint happily, and a toast bubble pops over both: '🍻 To the family.'",
    "overlay": "1  they take beer breaks",
    "note": "Run exactly TWO sessions so the random pet pick cannot miss. Trigger: curl -s \"http://127.0.0.1:$(cat ~/Library/Application\\ Support/Claudme/port)/effect/clink\" with the app launched under CLAUDME_DEBUG=1. maybeClink only fires if the second crab is on the SAME display, in idle or working state, and within 140pt centre-to-centre (PetManager.swift:484-497) — wait until they are that close. CUT AT 2.5s: showClink puts the toast bubble up at t=0 for 2.6s (PetView.swift:932), while the beer quip does not appear until t=4.0 and is only ever ONE of 'Ahh~' / 'That's the stuff.' / 'Salute.' — never the concatenation. Toast line is 1-in-3; retrigger until you get 'To the family.'"
   },
   {
    "t": "7.13-10.49",
    "visual": "Cut to a full-height tall slice of the left of the screen: menubar at top, a Claude Code terminal spinning mid-frame, Dock at the bottom. A crab on the ceiling stops, a 🪢 bubble pops, a thin rope draws downward and it rappels the entire height of the screen past the terminal, lands on the bottom edge and scuttles off.",
    "overlay": "2  they rappel down from the ceiling",
    "note": "Crop 1080x1920 straight out of the retina capture at 1:1, x=0, y=44 — zero scaling, perfectly crisp, and 44 is exactly the menubar inset the roam area already uses. The rope effect picks a crab with currentSegment==2 and silently falls back to a random pet if none is up there (PetManager.swift:391-393), so WAIT until a crab is actually on the ceiling before firing /effect/rope. Descent is ~2.2s at travSpeed 0.45; the remaining 1.2s is the landing and the walk-off."
   },
   {
    "t": "10.49-12.17",
    "visual": "Punch back in on a single crab walking the bottom edge. Three tiny crabs spring-pop in beside it one after another, each wearing the same fedora in the same cap colour, bobbing along at its leg line as the parent keeps walking.",
    "overlay": "3  they bring their kids to work        smaller, under it: (those are its subagents)",
    "note": "Deliberately the shortest beat in the video — 1.68s, three pops, out. curl .../effect/babies spawns 3 at slots x=40±56 and ±94, feet at y=31 on the parent's leg line, each with a CASpringAnimation (PetView.swift:1708-1723). Fire while the parent is mid-stride so the pops land over movement. 540x960 @2x nearest-neighbour, framed slightly right of the parent to leave room for the outer slots."
   },
   {
    "t": "12.17-15.53",
    "visual": "Wide on the real desktop with three Claude Code terminals open. Several crabs are scuttling along the edges — and one has stopped dead, slightly larger than the rest, hopping in place with a bubble that stays up: 'Boss? A word.' Slow push begins toward it.",
    "overlay": "4  one of them is waiting on you.  that one.",
    "note": "DO NOT use the Playground needsYou effect — that is only showNote: a 6s bubble and one hop while the crab keeps walking. Trigger a REAL permission prompt in one session (ask it to run a non-allowlisted command). Status flips to 'waiting', which sets slideRemaining=0 so the crab stops dead, scales to 1.02, holds the bubble indefinitely (for: nil) and hops every 2.2-3.4s (PetView.swift:718-724, 779-783, 863-867). No line lottery to worry about: all five English waiting quips read identically on camera. Shoot this and the next shot as ONE continuous locked-off 3024x1964 take and derive both framings by cropping in post."
   },
   {
    "t": "15.53-19.73",
    "visual": "Same take, continuing on the second drop. The mouse cursor travels to the waiting crab — the crab gives a startled little jump as the cursor arrives — the cursor clicks, the crab squashes and hops, and that session's terminal window snaps to the front of the whole screen. A bubble over the crab reads '→ Ghostty'. The crab stays visible on top of the terminal it just summoned.",
    "overlay": "5  click it and that session's terminal comes to the front",
    "note": "The only beat with zero debug triggers and the one that sells the install — give it the longest slot in the board (10 beats). Hover fires hoverPoke (8s cooldown, so do not rehearse the hover right before the take); mouseDown runs clickSquash then focusTerminal, which shows '→ AppName' for 1.6s (PetView.swift:1849-1893). Confirm TerminalFocus resolves YOUR terminal first — a failure shows a '?' bubble instead. The overlay sits above normal window level, so the crab correctly stays drawn over the terminal that just came forward: hold on that, it is the proof shot. Punch in from the same footage as shot 7 so the cut is a scale change, not a new setup."
   },
   {
    "t": "19.73-20.57",
    "visual": "Cut to a crab on the bottom edge. It swells, jumps, confetti bursts up over the Dock and rains down, bubble reads 'It's done, boss.'",
    "overlay": "small, low: every finished turn gets one of these",
    "note": "curl .../effect/celebrate. The hop keyframe is 0.85s and the crab scales to 1.3, so fire it ~0.2s before the cut and the jump is already rising on frame one. 'It's done, boss.' is 1-in-8 in the done list (Quips.swift:115) — the trigger is instant, so just re-fire until you get it; the bubble then holds 3.0s. Confetti birthRate is cut at +0.4s and the emitter is removed at +2.6s, velocity 240 with yAcceleration -420, so the densest cloud is +0.5 to +0.9s after the hop."
   },
   {
    "t": "20.57-23.09",
    "visual": "The frame freezes on the fullest confetti, crab still mid-air over the Dock. The lower two-thirds fades to near-black and the card stacks up over it.",
    "overlay": "large: your AI agents are a crime family   |   CLAUDME — free, open source, ~3 MB, no permissions   |   github.com/marekadvocate/claudme   |   full-width line: I built this with Claude Code. now it watches Claude Code.   |   tiny grey, very bottom: not affiliated with Anthropic",
    "note": "Freeze on the frame with the most confetti still airborne. 'I built this with Claude Code. now it watches Claude Code.' is the real hook and gets real type — it was 6pt on the old end card. Keep the URL and every line out of the right 15% and bottom 20% where TikTok's buttons and caption sit. No 'I didn't code this' claim anywhere in the video: the repo is public and the comments would take it apart."
   }
  ],
  "endCard": "Frozen on the confetti burst — a crab mid-jump over the Dock, bubble \"It's done, boss.\" Over the near-black lower two-thirds, in this order: \"your AI agents are a crime family\" in the largest type in the video; then CLAUDME — free, open source, ~3 MB, no permissions; then github.com/marekadvocate/claudme; then, full width and readable, \"I built this with Claude Code. now it watches Claude Code.\"; then one tiny grey line at the very bottom: \"not affiliated with Anthropic.\"",
  "soundIdea": "One trending instrumental at 143 BPM (or 71.5 half-time), cut so bar one of the video IS the drop — the shatter has to land at 1.26s, not fifteen seconds in. Tempo is not a taste call: the dance is driven by danceBeat = 0.42s, and although each crab re-rolls it ±0.05 every time it starts dancing so they are deliberately never in lockstep, 143 BPM makes the family read as locked to the track and anything else makes them look broken. Put the second lift or drop at 15.53s so the click-to-terminal beat gets the biggest moment in the track. Every cut sits on a 0.42s beat (shot lengths in beats: 3/2/6/6/8/4/8/10/2/6), so beat-cutting is just snapping to the grid. Claudme is completely silent — there is no app audio to capture — so add a short click or tape-stop on each numbered caption, a low riser under the rope descent, and let the drop carry the click beat. No voice-over: the captions are the read."
 },
 "anthropic": [
  {
   "careersUrl": "https://www.anthropic.com/careers",
   "howToApply": "Every Anthropic application goes through one path: the official job board, which hands off to Greenhouse. There is no other intake.\n\n1. Start at https://www.anthropic.com/careers (mission, FAQ, interview-process notes, AI-use policy) and click through to the job board at https://www.anthropic.com/careers/jobs. Filter by team and location. As of 2026-08-06 the board carries 395 live postings (confirmed via Anthropic's Greenhouse API, https://boards-api.greenhouse.io/v1/boards/anthropic/jobs).\n\n2. Clicking a role sends you to Anthropic's Greenhouse board: https://job-boards.greenhouse.io/anthropic/jobs/{id}. The full job description, the published salary band, and the application form all live on that page. Greenhouse is the system of record — anthropic.com/careers/jobs is only a front-end over it.\n\n3. Fill the Greenhouse form. Standard fields across roles: First/Last name, Email, Phone, Country, Resume/CV upload (PDF, DOC, DOCX, TXT, RTF), LinkedIn Profile, and a Website field. On most roles you must supply at least one of LinkedIn or resume. There is also an optional free-text box worded \"Add a cover letter or anything else you want to share.\"\n\n4. Answer the custom questions. Nearly every posting asks \"Why do you want to work at Anthropic?\" — the form itself flags it, and the evangelist posting states a 200-400 word preference while the Claude Design posting annotates it \"We value this response highly.\" Other recurring required questions: acknowledgment that you have read the candidate AI guidance, visa sponsorship needs, earliest start date, willingness to be in an office at least 25% of the time, relocation openness, and whether you have interviewed at Anthropic before. Some roles add hard requirements — e.g. Applied AI Technical Evangelist requires a link to a video of you speaking publicly (conference talk, podcast, demo, workshop, hackathon, or livestream), and Technical Specialist, Claude Code requires \"Briefly describe one LLM-powered application you've built — what it did, what model/API you used, and your role in shipping it.\"\n\n5. Submit. If your application is picked up, the first contact is a recruiter from Anthropic's talent team. Interviews run over Google Meet across timezones. Technical roles include live coding in Colab/CodeSignal — reference materials are allowed but Anthropic advises being fluent enough in basic syntax and standard libraries that lookups do not eat your time. Non-technical roles are conversational, probing problem-solving approach and mission alignment.\n\n6. Read https://www.anthropic.com/candidate-ai-guidance before writing anything. The rule is: \"Please create your first draft yourself, then use Claude to refine it.\" AI is encouraged for interview prep and research, prohibited on take-home assessments unless explicitly permitted, and prohibited during live interviews. Be transparent about how you used it.\n\nThere is no general or speculative application. Nothing on the board functions as a \"keep my resume on file\" submission, and there is no talent-pool or open-application posting. You apply to a specific requisition or you do not apply.",
   "relevantRoles": [
    {
     "title": "Applied AI Technical Evangelist, Startup Ecosystem",
     "location": "San Francisco, CA",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5116927008",
     "whyFit": "The single best fit for someone who ships polished, demo-able Claude Code artifacts. The posting explicitly wants \"production-quality code samples and demos\" and \"real builds that show how to solve a problem\" rather than polished presentations. Crucially, the form has a required field for a link to a video of you speaking publicly or demoing — a promo/demo video of a Claude Code side project is exactly the artifact this application is built to receive. Salary band $240,000-$315,000. Requires 7+ years combined founding/building/technical experience and regular travel."
    },
    {
     "title": "Technical Specialist, Claude Code",
     "location": "London, UK",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5198999008",
     "whyFit": "Post-sale technical partner for Claude Code customers. The role literally involves building and deploying Claude Code plugins, agents, and integrations. Its application form carries a required verbatim question — \"Briefly describe one LLM-powered application you've built — what it did, what model/API you used, and your role in shipping it\" — which is a direct, sanctioned slot for a Claude Code project. Salary band £180,000-£225,000. Wants shipped software plus comfort presenting to senior developers; 2-3 days/week in the London office."
    },
    {
     "title": "Technical Documentation and Content Engineer, Claude Docs",
     "location": "San Francisco, CA | New York City, NY",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5370615008",
     "whyFit": "Sits in Technical Education and is about deep hands-on Claude Code expertise turned into docs and content. A well-documented public Claude Code project — README, docs site, working demo — is the closest possible proxy for the day job, and the Website field plus free-text box let you point at it."
    },
    {
     "title": "Full Stack Engineer, Education Labs",
     "location": "San Francisco, CA | New York City, NY",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5097186008",
     "whyFit": "Technical Education team, building things that teach people to use Claude. Rewards a builder who ships small complete products with visible polish rather than one who only works inside a large existing codebase — a self-contained shipped app with a live site reads directly against this."
    },
    {
     "title": "Staff Software Engineer, Claude Design",
     "location": "San Francisco, CA | New York City, NY | Seattle, WA",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5229345008",
     "whyFit": "Engineering role on the Claude product surface where craft and visual/interaction quality are the point. Salary band $320,000-$485,000. The form has no project-specific custom question, so the Website field and the \"anything else you want to share\" box are where a design-forward personal app has to go."
    },
    {
     "title": "Product Manager, Developer Productivity",
     "location": "San Francisco, CA | New York City, NY",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5220143008",
     "whyFit": "Developer-tooling PM work. Having built your own tooling on top of Claude Code — including instrumenting hooks and session state — is direct evidence of the taste this role screens for, and is more persuasive than a written product opinion."
    },
    {
     "title": "Enterprise Community Lead",
     "location": "San Francisco, CA",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5231468008",
     "whyFit": "Marketing & Brand role centered on building and running a practitioner community. Relevant if you want the community/advocacy side rather than the engineering side; a project with real users and a public repo is the credential."
    },
    {
     "title": "Model Performance Software Engineer, Claude Code",
     "location": "San Francisco, CA | New York City, NY",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5098025008",
     "whyFit": "Staff-level IC on the Claude Code team owning evaluation frameworks and experiment infrastructure. Salary band $405,000-$485,000. Listed for completeness because it is the deepest Claude Code engineering role, but the bar is explicit: 10+ years of software engineering at Staff or Principal level. Only worth applying to if that matches. Note its form has no project question — Website field only."
    }
   ],
   "showingAProject": "Yes, but only as a link — never as a file. The only upload slot on any Anthropic Greenhouse form is Resume/CV. There are four real places a personal project can land:\n\n1. The **Website field**. Present on every posting I checked (the evangelist role labels it \"Website/Portfolio URL\"; engineering roles list \"Website\" under optional personal preferences). This is the universal slot. Put the live, working thing there — a GitHub Pages site or a landing page beats a bare repo URL, because a recruiter clicks once and sees it run.\n\n2. The **free-text box** worded \"Add a cover letter or anything else you want to share.\" Unstructured and optional on most roles, but it is where you write the two or three sentences that explain what the project is and why it is evidence for this specific job. A link with no framing usually goes unclicked.\n\n3. **Role-specific custom questions**, which are the strongest signal that a project is wanted. Two concrete examples on the live board right now: Technical Specialist, Claude Code requires \"Briefly describe one LLM-powered application you've built — what it did, what model/API you used, and your role in shipping it.\" Applied AI Technical Evangelist, Startup Ecosystem requires \"Share a link to a video of yourself speaking publicly — a conference talk, podcast, demo, workshop, hackathon, livestream, or anything similar.\" A demo video of your own project satisfies that second one.\n\n4. **Research-template postings** carry a richer form: separate **GitHub URL** and **Publications URL** fields alongside Website, plus required questions asking for three projects you are excited about and a relevant work sample with a description. If you are applying to a research or research-adjacent role, the form is actively asking for exactly this.\n\nPractical shape: lead with a link that works on first click, keep the repo public and the README readable in under a minute, and if there is a video make it short. Where a custom question exists, answer it there rather than burying the link in the resume.",
   "otherChannels": [
    "Anthropic Fellows Program — the closest thing to an open-ended, non-requisition entry point. Six live tracks: the general program (https://job-boards.greenhouse.io/anthropic/jobs/5023394008), AI Safety (5183044008), AI Security (5030244008), ML Systems & Performance (5183051008), Reinforcement Learning (5183052008), and The Anthropic Institute / Economics & Policy (5183053008). All list London UK; Ontario CAN; Remote-Friendly United States; San Francisco CA. It is a research fellowship, not a backdoor into product or engineering roles, but it is a genuine alternative application surface.",
    "\"[Expression of Interest]\" postings — Anthropic uses this prefix for roles it will accept applications for without an active urgent opening. Only two are live: [Expression of Interest] Research Engineer / Scientist, Alignment - London (https://job-boards.greenhouse.io/anthropic/jobs/4610158008) and [Expression of Interest] Research Manager, Interpretability (https://job-boards.greenhouse.io/anthropic/jobs/4980436008). Read the disclaimer before spending time: the London one states plainly that \"you may not hear back on your application to the London team unless we see an unusually strong fit.\" These are research-only and are not a general application.",
    "Employee referral — a real and recognized route. Anthropic's own material describes candidates arriving via direct application, employee referral, or inbound recruiter contact, and all three converge on the same recruiter screen. There is no public referral form; it requires knowing someone inside who submits you through the internal system.",
    "Inbound recruiter contact — Anthropic recruiters do source directly. Nothing you can trigger on demand, but a public project and a findable GitHub/LinkedIn raise the odds. Verify any such contact against the @anthropic.com rule below.",
    "The job board itself as a monitoring channel — the board turns over fast (postings on the API show updated_at timestamps on 2026-08-04, 08-05, and 08-06). Developer-relations roles in particular have opened and closed: a \"Developer Relations, Claude Developer Platform\" role and a \"Developer Relations Lead\" role both existed and are now closed, the latter removed 2026-03-10. Checking https://www.anthropic.com/careers/jobs weekly is a legitimate strategy given the 12-month reapply rule makes a badly-timed application costly."
   ],
   "cautions": [
    "There is no general or speculative application. I checked all 395 live postings by title and there is no talent-pool, open-application, or \"submit your resume\" posting. Emailing a CV to a generic Anthropic address will not enter any pipeline. Apply to a specific requisition.",
    "The 12-month reapply rule makes spraying applications expensive. The FAQ states verbatim: \"Yes—you're welcome to re-apply after 12 months, or sooner if something materially changes about your experience or skills.\" Pick two or three roles you genuinely fit rather than a dozen.",
    "No feedback is given, ever. Verbatim from the FAQ: \"We're not able to provide feedback on resumes or interviews.\" Silence carries no diagnostic information — do not read into it.",
    "Follow the AI-use guidance literally. https://www.anthropic.com/candidate-ai-guidance says \"Please create your first draft yourself, then use Claude to refine it.\" AI is banned on take-home assessments unless Anthropic explicitly permits it, and banned during live interviews because they want to see \"how you think through problems in real time.\" Transparency about your usage is an expectation, and most forms make you acknowledge the policy. An application that reads as machine-generated works against you at the one company best positioned to notice.",
    "Third-party job boards carry stale listings. Built In, ZipRecruiter, Indeed, LinkedIn, and VC portfolio boards (Accel, General Catalyst) all mirror Anthropic postings and keep serving them after they close — I confirmed two Developer Relations listings still live on aggregators that are dead on Anthropic's own board. Always verify a role at job-boards.greenhouse.io/anthropic before investing effort.",
    "Recruitment fraud is an active risk. From the careers page: \"Anthropic recruiters only contact you from @anthropic.com email addresses. Be cautious of emails from other domains. Legitimate Anthropic recruiters will never ask for money, fees, or banking information before your first day.\"",
    "In-person expectations are real and asked about on the form. Most roles require at least 25% office attendance and some require more; most staff are Bay Area based. The application asks directly about office availability and relocation openness, so decide your answer before you start.",
    "No internships are currently offered — the FAQ states this explicitly. Do not look for a student pipeline.",
    "Visa sponsorship is available but only for eligible roles, and every form asks whether you need it. Check the individual posting rather than assuming.",
    "Seniority bars are stated and enforced. Several of the most Claude-Code-adjacent engineering roles are Staff or Principal level with explicit multi-year requirements (the Model Performance role says 10+ years at Staff or Principal). A strong side project does not substitute for a stated years-of-experience floor; it strengthens an application that already clears it."
   ]
  },
  {
   "careersUrl": "https://www.anthropic.com/careers/jobs",
   "howToApply": "Everything goes through Anthropic's Greenhouse board — there is no email-a-resume path and no separate \"show us your project\" portal.\n\n1. Open the role's Greenhouse page (job-boards.greenhouse.io/anthropic/jobs/<id>) and click Apply. anthropic.com/careers/jobs is just a nicer front-end over the same reqs; both land on the same form.\n2. Fill the form. I pulled the actual field list from the Greenhouse API for these reqs — it is identical across them: First/Last name, Email (required); Phone, Resume/CV (file upload OR pasted text), Website, LinkedIn Profile, Additional Information (all optional).\n3. Answer the required screeners: \"Are you open to working in-person in one of our offices 25% of the time?\", \"Are you open to relocation for this role?\", \"Do you require visa sponsorship?\", \"Have you ever interviewed at Anthropic before?\", and an \"AI Policy for Application\" acknowledgment.\n4. Write the one required free-text answer: \"Why Anthropic?\" The rendered page indicates roughly 200-400 words. This is the single highest-leverage field in the whole application — it is the only place every applicant is forced to differentiate, and it is per-application, so a scattershot apply-to-twelve strategy costs twelve real essays.\n5. Submit. Applications are reviewed on a rolling basis; these reqs list no deadline.\n\nThere is no cover-letter upload field. The \"Additional Information\" textarea is the de facto cover letter.",
   "relevantRoles": [
    {
     "title": "Staff Software Engineer, Labs: Applied AI",
     "location": "San Francisco, CA | New York City, NY — hybrid, 25% in-office",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5304425008",
     "whyFit": "The closest match on the entire board, almost line-for-line. The listing asks for a 'generalist who can transition between different problem spaces', and names 'high agency, bias toward shipping, comfort with technical debt when it's the right tradeoff' as a qualification rather than a warning. It sits inside Anthropic Labs — the listing calls Labs 'the internal accelerator behind Claude Code, MCP, and Claude Design' — so it is the most direct organizational adjacency to Claude Code that is currently hiring an IC engineer. It explicitly says candidates need no ML/AI research background, which removes the research-strength gap. Salary $320k-$405k. Honest caveat: it asks for 8+ years of full-stack work with a track record of zero-to-one; one shipped side project is evidence, not a substitute for that history."
    },
    {
     "title": "Staff Software Engineer, Claude Design",
     "location": "San Francisco, CA | New York City, NY | Seattle, WA — hybrid, 25% in-office",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5229345008",
     "whyFit": "Also Anthropic Labs, and the listing describes itself as 'a craft-heavy, frontend-leaning role' where the bar is making AI-generated design 'feel like a tool people reach for first — not a demo'. That is a product-taste req, not a research req. Claude Design launched in research preview April 2026 and the listing says 'the engineers who join now will define what it becomes' — a small-surface, ship-fast setup. It also hands off to Claude Code for real builds, so being a heavy Claude Code user is directly relevant domain knowledge. Highest band of the set: $320k-$485k. Caveat: the canvas/real-time-editing work is web frontend, not AppKit — Swift experience transfers as craft and taste, not as stack."
    },
    {
     "title": "Staff Software Engineer, iOS",
     "location": "San Francisco, CA, New York City, NY, Seattle, WA — hybrid, 25% in-office",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/4572744008",
     "whyFit": "The only listing on the board where the Swift work itself is the qualification: 'Expertise in Swift, UIKit, SwiftUI, and iOS frameworks.' It lists 'Obsessive attention to detail and app experience' as a responsibility and '0-to-1 experience building successful products in early-stage environments' as a preferred qualification — both are exactly what a dependency-free native macOS app demonstrates. Salary $320k-$405k. Caveat: it is iOS/Claude mobile, not macOS, and it wants 'a track record of shipping impactful, high-adoption mobile applications' — App Store scale, which a desktop side project does not evidence. This is the role where the artifact speaks loudest and the résumé has to carry the volume."
    },
    {
     "title": "Senior Software Engineer, Full-stack (Product Engineering)",
     "location": "San Francisco, CA | New York City, NY | Seattle, WA — hybrid, 25% in-office",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5174743008",
     "whyFit": "This is the actual door into Claude Code and into Developer Experience. The listing is a Product Engineering org-wide req that says team placement happens after interviews, and it names the candidate teams outright: 'Claude.ai, the Anthropic API, enterprise deployments, Claude Code, or mission-driven applications.' Its Developer Experience track describes building 'console, SDKs, docs, and observability' and 'designing for both human and AI developers'. It asks for 'a product-oriented mindset' as a headline trait. Critically, this is the Senior band rather than Staff — the most realistic entry point of the set for someone whose strongest evidence is one shipped product rather than a decade of scaled systems."
    },
    {
     "title": "Staff+ Software Engineer, Full-stack (Product Engineering)",
     "location": "San Francisco, CA | New York City, NY | Seattle, WA — hybrid, 25% in-office",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5174747008",
     "whyFit": "Identical req text and identical team-matching mechanism to the Senior version above, at the Staff+ band. Worth knowing it exists so you pick one deliberately rather than applying to both — same posting, two levels, and applying to both signals uncertainty about your own level. Choose Senior unless you can point to multi-year ownership of a system at scale, not just a well-crafted app."
    },
    {
     "title": "Staff Software Engineer, Claude.ai",
     "location": "San Francisco, CA | New York City, NY | Seattle, WA — hybrid, 25% in-office",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5026097008",
     "whyFit": "The listing states 'This is a product engineering role first and foremost' and defines the job as obsessing over 'how something feels when you first land on it, how smoothly a new interaction flows'. It treats latency and responsiveness as 'first-class concerns rather than afterthoughts' — the exact argument for shipping native with no Electron and no dependencies. Lowest experience bar of the strong matches at 5+ years. Salary $320k-$405k. Caveat: the stack is explicitly React, Next.js, TypeScript, Node.js — you would be arguing that taste and performance instincts transfer, and you would need real web depth to back it."
    },
    {
     "title": "Full Stack Engineer, Education Labs",
     "location": "San Francisco, CA | New York City, NY — hybrid, 25% in-office",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5097186008",
     "whyFit": "The listing literally describes the job as operating 'as a one-person technical shop: prototyping new ideas, establishing technical direction, and shipping production-quality features' — the single-handed-shipper profile stated as a job description. It is the only role of the set that explicitly asks for a portfolio ('Portfolio demonstrating innovative designs and high-quality implementations'), so the side project is a first-class credential here rather than a footnote. It wants 'particular attention to the front-of-the-frontend: motion, polish, and interaction feel' and names developer-tool experience as a nice-to-have. Requires 6+ years. Salary $300k-$405k."
    },
    {
     "title": "Applied AI Technical Evangelist, Startup Ecosystem",
     "location": "San Francisco, CA — hybrid, 25% in-office",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5116927008",
     "whyFit": "The nearest thing Anthropic has to a public Developer Relations req, and the listing pre-empts the comparison itself: 'Unlike a traditional DevRel role, this is built for someone who has shipped products, lived the early-stage grind, and can speak to a technical co-founder as a peer. Someone who builds live demos and writes real code, not just talks about what Claude can do.' The Claude Code build story is the demo. Caveat: this is a GTM-attached role measured on developer sign-ups and activation, partnered with the Startups sales team — real quota-adjacent pressure. Take it only if audience-facing work genuinely appeals; it is not an engineering role with talks attached."
    },
    {
     "title": "Model Performance Software Engineer, Claude Code",
     "location": "San Francisco, CA | New York City, NY — hybrid, 25% in-office",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5098025008",
     "whyFit": "Included because it is the only IC engineering req on the whole board with 'Claude Code' in the title, so you should see it — but I'd rank it below the others for this profile. Despite the team, the work is evaluation infrastructure and research tooling: 'Architect eval frameworks that measure model capabilities', 'infrastructure that enables researchers to run experiments at scale'. It does ask for 'strong product intuition' as a bridge to research, which is the hook, but the listing wants 'someone who has already built and owned systems at significant scale' as a technical leader. That is the research-adjacent, systems-scale profile rather than the product-taste, ship-fast one."
    },
    {
     "title": "Technical Documentation and Content Engineer, Claude Docs",
     "location": "San Francisco, CA | New York City, NY — hybrid, 25% in-office",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5370615008",
     "whyFit": "A developer-experience role in disguise, and newly posted (2026-07-24). The listing is emphatic that it 'goes far beyond traditional technical writing' — it is 'a content + systems ownership role' where you build 'self-healing pipelines, AI-assisted review and maintenance' across Claude.ai, Cowork, Claude Tag and Claude Science docs. Someone who has driven a whole codebase through Claude Code has direct, hard-won intuition about what documentation agents and humans actually need. Fits if writing and tooling appeal as much as product surfaces do."
    },
    {
     "title": "Technical Specialist, Claude Code",
     "location": "London, UK — hybrid, 25% in-office",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5198999008",
     "whyFit": "The Europe-based option, and the only Claude Code role outside the US. Post-sale customer-facing: the listing describes running 'an advanced Claude Code hackathon for 1000 engineers at a global bank' one week and pair-building plugins the next, and it wants people who 'build and ship working software (Claude Code plugins, agents, sub-agents, MCP integrations)'. It says it is looking for 'technologists who could have been researchers or staff engineers, but who get the most energy from helping customers get unstuck' — no research strength required. Caveat: it also owns SSO/SCIM/CISO conversations, which is enterprise IT surface area, not product craft."
    }
   ],
   "showingAProject": "Yes, in three places — but note the form has no GitHub field and no portfolio upload, so this needs deliberate placement.\n\n1. **Website** (optional free-text field on every one of these reqs). This is the primary slot. Point it at one URL that shows the app working in under thirty seconds — a landing page with a screen recording beats a bare repo, because a reviewer skimming hundreds of applications will not clone and build a Swift project. Link the repo from there.\n\n2. **Additional Information** (optional textarea). The de facto cover letter, since there is no cover-letter upload. This is where the *interesting* claim goes — not \"I built a macOS app\" but the specific engineering decisions: no dependencies, no Electron, native AppKit/SwiftUI, and what that bought in binary size, memory, and launch time. Numbers, because taste claims without numbers read as taste claims.\n\n3. **Resume/CV**. Accepts a file upload or pasted text. The project belongs as a real line item with the same concrete detail, not in a \"side projects\" afterthought section.\n\nOn the \"built entirely with Claude Code\" angle: state it plainly and treat it as a strength — Anthropic's own careers page says it weighs demonstrated work like independent projects and open source over credentials. But make the *engineering judgment* the headline and the tooling the supporting detail. A reviewer at Anthropic is not impressed that Claude Code can write Swift; they already know. What is genuinely differentiating is evidence that you drove it well — how you decomposed the work, where you overrode it, what you rejected. Write a short public post on exactly that; for the Labs, Claude Design, and Education Labs roles it doubles as the portfolio artifact those listings want.\n\nTwo roles make the project count for more than usual: **Education Labs** explicitly asks for a portfolio, and **Claude Design** is described as \"craft-heavy\", so a polished demo carries real weight there.",
   "otherChannels": [
    "anthropic.com/careers/jobs — Anthropic's own board. Same Greenhouse reqs behind a better filter UI; use it for browsing, apply from either.",
    "job-boards.greenhouse.io/anthropic — the raw Greenhouse board, all 395 reqs on one page. Faster to scan and search than the marketing site.",
    "boards-api.greenhouse.io/v1/boards/anthropic/jobs — the public JSON feed behind both boards (it is what I used here). Poll it on a cron and diff by job id to get same-day notice of new reqs. Product Engineering roles for a profile like this appear and fill quickly; the Labs: Applied AI and Claude Design reqs are both from the last three months.",
    "Publishing the build. Anthropic's careers page states about half its technical staff had no prior ML experience and that it weighs demonstrated work — independent projects, technical writing, open source — over credentials. A well-argued public writeup on driving Claude Code to ship a real native app is genuinely read by the people building it, and gives a referrer something concrete to forward.",
    "Employee referral, if you have a real connection. Standard Greenhouse referral routing applies. Do not manufacture one — a cold LinkedIn ask converts worse than a strong application.",
    "Anthropic Labs product surfaces (Claude Code, MCP, Claude Design) have public issue trackers and community channels. Substantive contributions there are visible to the exact teams you are targeting. This is a slow channel, not an application shortcut — treat it as compounding, not tactical."
   ],
   "cautions": [
    "The AI-usage policy is the one to read before writing a word, and it cuts against the obvious instinct here. anthropic.com/candidate-ai-guidance says for the application: 'Please create your first draft yourself, then use Claude to refine it.' For take-homes: 'Complete these without Claude unless we indicate otherwise.' For live interviews: 'This is all you – no AI assistance unless we indicate otherwise.' The framing is 'Use AI to refine your ideas, not replace them.' There is a required acknowledgment checkbox on the form. Someone whose whole pitch is 'I built this with Claude Code' is exactly the person most likely to hand Claude the 'Why Anthropic?' essay — and a generic-sounding answer from that candidate reads worse than from anyone else.",
    "Interviews are unassisted. If the story is 'I ship fast with Claude Code', the interview loop will test what remains when the tool is removed. Be able to write and reason about Swift on a whiteboard at the level the app implies.",
    "Levels are high across the board. Of the eleven roles here, most are Staff or Staff+ asking 6-10+ years (Labs: Applied AI wants 8+, Education Labs 6+, Claude.ai 5+). The Senior Software Engineer, Full-stack req is the most realistic entry point. Applying to a Staff req on the strength of one polished side project is a low-probability shot — pick the level honestly.",
    "Hybrid is mandatory and asked as a required question: 'expect all staff to be in one of our offices at least 25% of the time. However, some roles may require more time.' Relocation openness is also a required field. Every strong fit here is SF, NYC, or Seattle; the only Europe-based option is the London Technical Specialist role.",
    "Visas are sponsored but not guaranteed. The listings say 'We do sponsor visas! However, we aren't able to successfully sponsor visas for every role and every candidate.' There are two separate required sponsorship questions on the form.",
    "Do not shotgun the board. 'Why Anthropic?' is required per application at ~200-400 words, so five applications is five real essays. Two or three genuinely targeted ones will outperform a spray, and Anthropic sees them all in one system.",
    "This snapshot is from 2026-08-06 against a board whose reqs were last refreshed 2026-08-03. Reqs get pulled and levels get retitled without notice — reconfirm each listing loads before investing in an essay for it.",
    "From the listings' own scam warning: 'Anthropic recruiters only contact you from @anthropic.com email addresses' and 'Legitimate Anthropic recruiters will never ask for money, fees, or banking information before your first day.' Anything arriving from another domain after you apply should be treated as fraudulent.",
    "There is currently no open IC product-engineering req titled 'Claude Code' — the only Claude Code engineering title on the board is the Model Performance one, which is eval and research infrastructure. The real route onto Claude Code product work is the Product Engineering full-stack req, which names Claude Code as one of its post-interview team placements. Do not wait for a 'Claude Code Product Engineer' posting that may never appear separately.",
    "Salary bands are published on each listing ($300k-$485k across this set). They are US bands tied to those hybrid locations, and reading them as a floor for a first Anthropic offer at a level you have not yet demonstrated would be a mistake."
   ]
  },
  {
   "careersUrl": "https://www.anthropic.com/careers/jobs",
   "howToApply": "Every Anthropic hire goes through one funnel — the Greenhouse board. There is no resume inbox, no referral form for outsiders, and no \"hire me\" DM path.\n\n1. Browse https://www.anthropic.com/careers/jobs (backed by the live feed at https://boards-api.greenhouse.io/v1/boards/anthropic/jobs — 395 open roles as of 2026-08-06). Each role resolves to job-boards.greenhouse.io/anthropic/jobs/<id>.\n2. Hit Apply on that job page. Standard Greenhouse form: resume, contact details, work authorization, and free-text fields. This is where a project link belongs — in the resume AND in the free-text \"why Anthropic / anything else\" field, with one sentence on what it does and one on what it proves about you.\n3. Anthropic's careers page explicitly invites non-traditional evidence: \"We care about what you can do, not where you learned to do it,\" and it encourages applicants to highlight independent research, technical writing, or open-source contributions. About half their technical staff had no prior ML experience. A shipped, used, documented open-source tool is exactly the artifact they say they want to see.\n4. AI use is governed by https://www.anthropic.com/candidate-ai-guidance. Allowed: \"Please create your first draft yourself, then use Claude to refine it,\" plus using Claude to research the company and rehearse. Not allowed: Claude writing your application responses, any AI on take-home assessments unless they say otherwise, any AI during live interviews, and inventing experience.\n5. Interviews run on Google Meet. Technical rounds are live coding in Colab or CodeSignal, and you may reference materials. Non-technical rounds are conversational, focused on how you reason.\n6. Terms of the funnel: no internships currently; no feedback given on applications or interviews; you may reapply after 12 months (or sooner if circumstances change materially); visa sponsorship available on eligible roles; most staff are in the Bay Area regularly even on \"remote-friendly\" listings.",
   "relevantRoles": [
    {
     "title": "Applied AI Technical Evangelist, Startup Ecosystem",
     "location": "San Francisco, CA",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5116927008",
     "whyFit": "The closest thing Anthropic currently has to a developer-relations role — there is no open role literally titled Developer Advocate or DevRel anywhere on the 395-role board. This one is about building demos and working alongside startup builders, which is precisely what a polished, publicly-used Claude Code ecosystem tool demonstrates. SF-based."
    },
    {
     "title": "Technical Documentation and Content Engineer, Claude Docs",
     "location": "San Francisco, CA | New York City, NY",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5370615008",
     "whyFit": "Under Technical Education. Wants someone who can build the thing and then explain it well. A well-written README plus a real Claude Code integration (hooks, session state, plugin packaging) is a direct work sample for this job."
    },
    {
     "title": "Staff+ Software Engineer, Developer Acceleration",
     "location": "San Francisco, CA | Seattle, WA",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5290360008",
     "whyFit": "Builds tooling that makes engineers faster. A side project whose entire thesis is reducing the cognitive load of running many agents at once is on-thesis for this team's mandate."
    },
    {
     "title": "Model Performance Software Engineer, Claude Code",
     "location": "San Francisco, CA | New York City, NY",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5098025008",
     "whyFit": "Core Claude Code product engineering. Deep hands-on familiarity with Claude Code internals — hooks, settings.json, session lifecycle — is table stakes here and is exactly what building on top of it produces."
    },
    {
     "title": "Staff Software Engineer, Claude Design",
     "location": "San Francisco, CA | New York City, NY | Seattle, WA",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5229345008",
     "whyFit": "Design-engineering craft role. A native Swift app with deliberate visual identity, no Electron, ~3MB, no permissions, is a craft argument rather than a feature list — the kind of evidence this role reads for."
    },
    {
     "title": "Full Stack Engineer, Education Labs",
     "location": "San Francisco, CA | New York City, NY",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5097186008",
     "whyFit": "Technical Education org — builds learning tools and demos that teach people to use Claude. Ships-fast generalist profile with a public portfolio is the fit signal."
    },
    {
     "title": "Technical Specialist, Claude Code",
     "location": "London, UK",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5198999008",
     "whyFit": "The only Claude Code role outside the US on the board right now. Sits in Sales, so it is customer-facing, but it is the realistic Claude Code entry point for anyone Europe-based who doesn't want to relocate."
    },
    {
     "title": "Staff+ Software Engineer, Developer Productivity",
     "location": "London, UK",
     "url": "https://job-boards.greenhouse.io/anthropic/jobs/5254803008",
     "whyFit": "Second Europe-based option, engineering rather than sales. Internal DX tooling — same instinct as building agent-observability for yourself, applied to Anthropic's own engineers."
    }
   ],
   "showingAProject": "Yes, and there are three genuinely distinct places, each with a different job.\n\n1. INSIDE THE APPLICATION (primary). Greenhouse gives you a resume upload and free-text fields. Put the repo link and the live site in the resume, and use the free-text field for two sentences: what it does, and what building it taught you about Claude Code. Do not attach a deck. Anthropic's careers page states outright that open-source contributions are what they want to see, so this is not a stretch — it's the intended slot.\n\n2. THE OFFICIAL PROJECT SUBMISSION FORM (parallel track, not hiring). https://form.typeform.com/to/VIUAjxNi — titled \"Project submission\", linked directly from https://claude.com/community. Its welcome screen reads: \"Share what you built with Claude! Projects you submit will be considered for a feature on Claude's social channels and marketing.\" Verified live. Required fields: name/contact, city, project name, what it is, how Claude contributed, project link, and screenshots or video (file upload, mandatory). Optional but high-leverage: social handles, inspiration/collaborators, additional media, preferred attribution, and \"Already posted about it? Share the links — we love to amplify.\" The rules are documented at https://support.claude.com/en/articles/15485501-submit-your-build-how-it-works-and-what-you-re-agreeing-to — no prize, no deadline, no judging; Anthropic tries to read every submission but guarantees nothing; you may get featured with no advance notice; builds made with Claude or other AI tools are explicitly welcome. This is the single most on-target, unambiguously sanctioned \"notice my thing\" channel that exists.\n\n3. PACKAGE IT AS A CLAUDE CODE PLUGIN AND SUBMIT IT (distribution, and the strongest passive signal). Per https://code.claude.com/docs/en/plugins, Anthropic runs two marketplaces. `claude-community` (repo: anthropics/claude-plugins-community) takes third-party submissions after review — individual authors submit at https://platform.claude.com/plugins/submit; Team/Enterprise orgs use https://claude.ai/admin-settings/directory/submissions/plugins/new. Run `claude plugin validate ./your-plugin` first, since the review pipeline runs the identical check plus automated safety screening. Approved plugins are pinned to a commit SHA in the community catalog and CI bumps the pin as you push. The curated `claude-plugins-official` marketplace is separate: \"Anthropic decides which plugins to include at its discretion. There is no application process, and the submission form does not add plugins to the official marketplace.\" Anything that installs hooks into settings.json is already 80% of a plugin — shipping a plugin wrapper turns a personal tool into something with install counts, which is far better evidence than a GitHub star count.\n\nSequence that works: ship publicly → post it once in the right community venues → submit the typeform with those post links in the \"already posted about it\" field → apply to roles with the project in the resume. The typeform is explicitly an amplification loop, not a cold pitch.",
   "otherChannels": [
    "CLAUDE DISCORD — https://www.anthropic.com/discord (307-redirects to https://discord.com/invite/6PPFFzqPDZ). Server is literally named \"Claude\", invite issued by the \"Claude Official\" account, ~119,500 members with ~20,400 online at time of checking. Anthropic's own description on claude.com/community: \"Real-time help, project sharing, and active discussions with thousands of developers.\" VERDICT: project sharing is explicitly sanctioned here — this is the main welcome venue. Post once in the sharing/showcase area, not in help channels, and never DM staff. Onboarding gate and member verification are enabled, so read the server guide before posting.",
    "PROJECT SUBMISSION FORM — https://form.typeform.com/to/VIUAjxNi. Anthropic's own intake for builds to be featured on Claude social channels, the monthly newsletter, and marketing. VERDICT: not just welcome, it is the purpose-built channel. Zero spam risk. Terms at https://support.claude.com/en/articles/15485501-submit-your-build-how-it-works-and-what-you-re-agreeing-to",
    "CLAUDE COMMUNITY AMBASSADORS — https://claude.com/community/ambassadors. Run meetups, workshops and hackathons in your city with Anthropic's backing. Process: Typeform application → screening interview → sign Ambassador Agreement → private Slack. You get event sponsorship and funding, monthly API credits, pre-release feature access, Builders Council sessions that feed product input, swag, and promotion through Anthropic's channels. No direct payment. Eligibility, quoted: \"You should have meaningful experience with Claude Code or Claude Cowork and a track record of community involvement, but a developer title isn't required.\" Applications open, no stated deadline. VERDICT: welcome, and this is the highest-leverage long game — it puts you in a private Slack with Anthropic staff and on a first-name basis with the community team. Not a hiring channel, but it is how you stop being a stranger.",
    "CLAUDE COMMUNITY EVENTS CALENDAR — https://luma.com/claudecommunity. Ambassador-run global events: Claude Impact Labs, Claude Code Workshops, meetups, plus social formats (Claude & Coffee, Claude Hike). Live listings span San Diego, Chicago, Wellington, Bhopal, Austin. Has a Submit Event flow gated on calendar-admin approval. VERDICT: demoing your project at a local Claude meetup is welcome and is the highest-signal, lowest-spam way to show a thing to actual Anthropic-adjacent people. Submitting an event that is really just an ad for your product would not clear admin approval.",
    "CLAUDE CODE PLUGIN MARKETPLACES — docs https://code.claude.com/docs/en/plugins; community catalog https://github.com/anthropics/claude-plugins-community (339 stars, description reads \"Read-only mirror — submit plugins at clau.de/plugin-directory-submission\"); official curated directory https://github.com/anthropics/claude-plugins-official (33,199 stars, 891 open issues, Discussions disabled). VERDICT: submitting is welcome and is the designed distribution path. The official marketplace cannot be applied to — it is curated at Anthropic's discretion. Getting picked up there is the strongest possible third-party endorsement, and per the docs an official listing lets your CLI prompt Claude Code users to install it (https://code.claude.com/docs/en/plugin-hints).",
    "anthropics/claude-code ON GITHUB — https://github.com/anthropics/claude-code. 140,498 stars, 15,106 OPEN ISSUES, GitHub Discussions DISABLED (has_discussions: false, /discussions returns 404), and `blank_issues_enabled: false` in .github/ISSUE_TEMPLATE/config.yml. Only four templates exist: bug_report, documentation, feature_request, model_behavior. There is no CONTRIBUTING.md. The config file routes conversation away to Discord and the docs. VERDICT: posting a project here is SPAM and it will be closed — you cannot even open a free-form issue. What IS welcome: a genuinely good bug report (or `/bug` from inside Claude Code), a documentation fix, and a feature request grounded in real usage. A single sharp, well-reproduced issue on a real Claude Code bug you hit while building is worth more attention than any showcase post would have been.",
    "modelcontextprotocol/modelcontextprotocol ON GITHUB — https://github.com/modelcontextprotocol/modelcontextprotocol. 8,876 stars, 153 open issues, and Discussions ARE enabled here (unlike the Claude Code repo). VERDICT: if your project ever exposes an MCP server, this is a legitimate venue for technical discussion and spec feedback. Still a working repo, not an ad board — contribute to a thread, don't start one that's a link drop.",
    "r/ClaudeAI — https://www.reddit.com/r/ClaudeAI/. Linked from claude.com/community as a recommended space, described by Anthropic as \"Long-form discussions, project showcases, and community knowledge that sticks around.\" VERDICT: showcase posts are on-topic by Anthropic's own framing, but the subreddit is independently moderated, NOT run by Anthropic, and has its own self-promotion rules. I could not read the rules page directly — both www.reddit.com and old.reddit.com blocked automated fetches — so read r/ClaudeAI's sidebar rules yourself before posting, and expect a flair or frequency limit on self-promo.",
    "OFFICIAL SOCIAL ACCOUNTS — https://x.com/claudeai, https://x.com/AnthropicAI, https://www.linkedin.com/showcase/claude/, https://www.youtube.com/@anthropic-ai (all verified live, all linked from claude.com/community's footer). VERDICT: these are broadcast accounts, not intake. Posting your own build on your own timeline and tagging it appropriately is fine and is actively encouraged — the official submission form asks for those links verbatim (\"Already posted about it? Share the links — we love to amplify\"). Replying with the same link under every Anthropic post is the textbook spam pattern and is the one behaviour that will actively cost you.",
    "MONTHLY NEWSLETTER — subscribe at https://claude.com/community (\"Get monthly highlights: featured projects, upcoming events, and tips from expert problem solvers\"). VERDICT: not a submission channel, but reading it tells you which projects get featured and in what format, which is direct intel for framing your own typeform submission.",
    "CODE WITH CLAUDE — https://claude.com/code-with-claude and https://www.anthropic.com/events/code-with-claude. Anthropic's developer conference series: hands-on workshops, live demos of new capabilities, and sessions with the teams behind Claude, run across San Francisco, London and Tokyo, each with an Extended day and a livestream. In-person attendance is by application, not open registration. VERDICT: attending is legitimate and puts you in a room with the Claude Code team. I found NO public call for speakers or demo showcase on the official page — reports of hackathon-winner panel slots come from partner university hackathons (e.g. the Anthropic x USC Devpost event), not from an open CFP. Check the page for the next cycle's application window rather than assuming one exists.",
    "CLAUDE FOR STARTUPS — https://claude.com/programs/startups. Community side (hackathons, Founder Days, meetups in six cities, AMAs, livestreams, early access to launches) is open to any early-stage founder. Credits are gated: institutional equity funding, founded within the last four years, no prior Anthropic startup credits. Application takes ~2 minutes via a Claude Console account. VERDICT: welcome and relevant if you already run a company — the Founder Day and hackathon formats are legitimate in-person exposure. Not a route for a hobby project on its own.",
    "HACKERONE BUG BOUNTY — https://hackerone.com/anthropic. Went fully public in May 2026 after running application-only under NDA. Two tracks: Product Security (Claude.ai, the API, and Claude Code — unauthorized command execution, invisible tool usage, permission bypasses, sandbox escapes) and Model Safety (novel universal jailbreaks defeating Constitutional Classifiers in CBRN and cyber domains, see https://support.claude.com/en/articles/12119250-model-safety-bug-bounty-program). Up to $15,000 per finding. VERDICT: a real, paid, extremely high-signal way to get noticed by Anthropic engineers — a good report is read by the people who own the code. Completely irrelevant as a place to show a side project; only go here with an actual finding.",
    "CLAUDE CAMPUS PROGRAM / BUILDER CLUBS — https://claude.com/programs/campus. Student-led chapters, 75+ schools, 15,000+ students, free Claude Pro and API credits for clubs, workshops and demo days. Spring 2026 applications have closed. VERDICT: welcome but students only — not applicable unless you're university-affiliated.",
    "CLAUDE MARKETPLACE — https://claude.com/platform/marketplace, and POWERED BY CLAUDE — https://claude.com/partners/powered-by-claude. The former is enterprise procurement (organizations spend down their Anthropic commitment on partner solutions; entry via a partner waitlist at https://claude.com/marketplace-partners). The latter is a curated list of businesses building on Claude — Databricks, Snowflake, JetBrains, Bolt.new. VERDICT: both are partner/sales motions gated on a business relationship and enterprise readiness. Approaching either with a free MIT side project goes nowhere and burns a first impression with the partnerships team. Skip."
   ],
   "cautions": [
    "TRADEMARK IS THE REAL RISK, not spam. Anthropic's Trademark Guidelines (https://www.anthropic.com/legal/trademark-guidelines, effective 2024-08-01) state: \"You may only use our trademarks as specifically permitted by us and only in materials we approve beforehand\", \"You may not use our trademarks in a manner that implies Anthropic's sponsorship or endorsement, or a relationship or affiliation with Anthropic\", and \"No alterations of our trademarks (changes to color, font, proportion, or otherwise) are permitted.\" CLAUDE is a registered mark (filed 2023-02-10, registered 2025-01-07). A project whose name is built on \"Claud\" sits squarely in this zone. The README's existing \"An independent community project — not affiliated with Anthropic\" notice is exactly the right instinct — keep it above the fold in the README, repeat it on the website and in any app About panel, never ship Anthropic logos or logo-derived artwork, and never restyle their wordmark. The marketing@anthropic.com contact in the guidelines is explicitly for parties who already have a business relationship, so it is not a permission line for an outside dev.",
    "THE PROJECT SUBMISSION CONSENT IS HEAVY — read it before you submit. The form requires agreeing to a \"non-exclusive, royalty-free, worldwide, perpetual, and irrevocable license\" covering your description, links, screenshots, video, the content reachable through those links, plus your name, handle, trademarks, likeness, image and voice, in any and all media. Anthropic may edit and publish \"without getting my approval on each specific use\", may pass the rights to partners and platforms, and the permission \"can't be withdrawn once given\"; anything already published may stay live after Anthropic removes it from its own channels. You keep ownership of the build and featuring is unpaid. Fine for promotion — just don't click through it blind, and use the 'anything we should know' field to flag any third-party assets or collaborators.",
    "DO NOT OPEN A GITHUB ISSUE TO SHOW YOUR PROJECT. anthropics/claude-code has Discussions disabled, blank issues disabled, only four narrow templates, and 15,106 already-open issues. A showcase issue is off-topic by construction, gets closed, and is the single clearest 'this person doesn't read before posting' signal you can send to the exact team you want to impress.",
    "THERE IS NO BACK CHANNEL. No cold email, no DMing Anthropic staff on X or Discord, no LinkedIn pitch to a hiring manager, no repeated @-tagging on official accounts. Hiring runs through Greenhouse and nothing else; showcasing runs through the typeform and the community venues. Attempting a shortcut converts a good project into a bad first impression.",
    "DO NOT LET CLAUDE WRITE YOUR APPLICATION. The candidate AI guidance is specific: draft it yourself first, then use Claude to refine; no AI on take-home assessments unless they say otherwise; no AI during live interviews; and \"creating fake experiences with AI assistance\" is called out as not allowed. Given who is reading it, an obviously model-generated application is worse than a plain one.",
    "THE FUNNEL IS UNFORGIVING AND SILENT. No internships currently offered. No feedback on applications or interviews, ever. You may only reapply after 12 months unless your circumstances change significantly. So do not spray applications across eight roles — pick the one or two where the project is real evidence.",
    "GEOGRAPHY IS A HARD CONSTRAINT ON MOST ROLES. Nearly all the relevant engineering and Applied AI roles are San Francisco, New York or Seattle, and the careers page notes most staff are in the Bay Area regularly, with some attending monthly. If relocation isn't on the table, the London listings (Technical Specialist, Claude Code; Staff+ Software Engineer, Developer Productivity) are the realistic targets. Visa sponsorship is available for eligible roles.",
    "ONE POST PER VENUE. The behaviour that actually reads as spam is the same link appearing in Discord help channels, across multiple subreddits, under unrelated Anthropic tweets, and in a GitHub issue within the same week. Post once where sharing is invited, then let the typeform and the plugin marketplace do the distribution — those are pull channels, and pull is what gets amplified.",
    "THE JOB BOARD MOVES. All eight role IDs above were pulled live from the Greenhouse API on 2026-08-06 and were open at that moment. Re-check each URL before writing anything tailored — Anthropic churns 395 listings and closes roles without notice.",
    "DON'T MISREAD PARTNER PROGRAMS AS BUILDER PROGRAMS. Claude Marketplace and Powered by Claude look like showcases but are enterprise procurement and a curated business list, both waitlist-gated and aimed at companies with enterprise security, scale and compliance stories. Applying as a solo dev with a free tool is a wasted approach to the partnerships team.",
    "THE AMBASSADOR ROUTE IS A COMMITMENT, NOT A CREDENTIAL. It involves an interview, a signed Ambassador Agreement, and an ongoing obligation to actually run events in your city — and it is explicitly unpaid. It is the best long-game channel, but only take it if you genuinely want to organize meetups, not as a line for a resume.",
    "I COULD NOT INDEPENDENTLY VERIFY TWO THINGS. (a) r/ClaudeAI's specific self-promotion rules — Reddit blocked automated fetching from both www and old.reddit.com; read the sidebar yourself. (b) The Claude Discord's internal channel names and posting rules, which require joining the server; my basis for saying project sharing is welcome there is Anthropic's own description of the server on claude.com/community, not a rules page I read."
   ]
  }
 ],
 "ranking": [
  {
   "p": "X",
   "n": "Six Spinners",
   "s": -1
  },
  {
   "p": "X",
   "n": "One Take: The Edge",
   "s": 0
  },
  {
   "p": "X",
   "n": "Made Man — \"It's done, boss.\"",
   "s": -2
  },
  {
   "p": "X",
   "n": "So I Gave Them Bodies — the dopamine confession",
   "s": -3
  },
  {
   "p": "TikTok",
   "n": "Six Made Men (POV cut)",
   "s": -1
  },
  {
   "p": "TikTok",
   "n": "CRAB WAVE (loop ×3)",
   "s": -3
  },
  {
   "p": "TikTok",
   "n": "5 Things I Didn't Code",
   "s": 18
  },
  {
   "p": "TikTok",
   "n": "\"Fuck This Work\" — the crab who quits his corner",
   "s": -1
  }
 ]
}