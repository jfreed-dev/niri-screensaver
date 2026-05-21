# TODO

Open work, future features, and untested integration paths. Not exhaustive —
edit freely. Items with `[?]` need a real call before implementation; items
with `[bug]` are confirmed defects.

## Known issues

(none currently tracked)

### Resolved

- **[fixed] Launch/kill race under idle daemons (v0.5.1, #4).** Noctalia — and
  likely any idle daemon that pairs a `launchCommand` with a `resumeCommand` —
  fired the resume (`niri-screensaver-launch kill`) within ~1s of launch:
  spawning the fullscreen Alacritty triggers a Wayland focus/input event that
  `ext-idle-notify-v1` reports as activity, so the screensaver flashed and died
  before rendering. Fixed by debouncing in `niri-screensaver-launch` — a `kill`
  arriving within `NIRI_SCREENSAVER_KILL_DEBOUNCE_SECS` (default `3`) of `launch`
  is dropped (`kill_too_soon_after_launch()` checks the `launch.timestamp` stamp
  file; set the env var to `0` to disable).

## Untested integration paths

- **[?] Lock-screen interplay.** `Main.qml` already wires `screenLock` /
  `screenUnlock` hooks to `niri-screensaver-launch kill` so the screensaver
  tears down when Noctalia's lock fires. End-to-end behavior unverified:
  - Trigger lock while screensaver is running → screensaver should exit,
    lock UI appears.
  - Trigger lock while screensaver is *not* running → lock UI appears,
    screensaver stays dormant.
  - Unlock → screensaver should NOT auto-relaunch (idle timer should reset
    on unlock).
- **[?] Wake-from-sleep.** Behavior after the system suspends/resumes:
  - Does the `tte` process survive suspend, or get SIGTERM'd by systemd?
  - On resume, does the idle timer correctly re-arm so a fresh idle
    period triggers a fresh launch?
  - Does the screensaver come back on the right monitor (in case display
    config changed during suspend)?
- **[?] Multi-monitor coverage.** `niri-screensaver-launch`'s `count_outputs`
  loop spawns one alacritty per output, focus-cycling between spawns. Test
  on a real multi-output setup (Framework 13's HDMI output, or external
  monitor on USB-C). Edge cases:
  - Plug/unplug a monitor while the screensaver is running.
  - Outputs with very different DPIs.

## Feature backlog

- **Per-time-of-day logo.** Different logo at night vs day; cheap
  `if (date +%H) > 18` branch in the inner driver.
- **Per-monitor logo.** The launcher already iterates outputs; pass
  `LOGO_FILE` per-output so different screens show different art.
- **Effect playlists.** `EFFECT_PLAYLIST` env var that cycles a
  deterministic sequence of effects rather than `--random-effect`.
- **Min/max effect duration knobs.** TTE durations vary widely; expose
  `MIN_EFFECT_DURATION` / `MAX_EFFECT_DURATION` env keys to cap pacing
  without forking effect code.
- **Bar-widget enrichments.** Tooltip showing "minutes until idle"; a
  right-click submenu with quick logo / effect picks.

## Ops / packaging

(nothing open — AUR packages (`niri-screensaver` + `-git`) are shipped and
auto-publish on tag; registry submission and awesome-niri listing are tracked
in [docs/development/WORKFLOW.md](docs/development/WORKFLOW.md).)

## Notes for maintainers

- **Capturing demos for docs:** the niri window-rule for
  `app-id="niri-screensaver"` includes `block-out-from "screencast"`,
  which causes `grim` / `wf-recorder` / `niri msg action screenshot-screen`
  to record black frames where the screensaver should be. Workflow:
  1. Comment out the `block-out-from "screencast"` line in
     `~/.config/niri/cfg/rules.kdl` (or the equivalent in your niri config).
  2. `niri validate` — niri picks up rule changes live.
  3. Trigger the screensaver, capture, stop.
  4. Restore the line and re-validate. Don't ship a recording dance
     that leaves the rule disabled.
