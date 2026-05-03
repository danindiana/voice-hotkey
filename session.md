# Session: Push-to-Talk Hotkey for Claude Code
**Date:** 2026-05-03  
**Status:** COMPLETE  
**Repo:** https://github.com/danindiana/voice-hotkey

## Goal
Wire up a global keyboard shortcut to trigger push-to-talk voice input into Claude Code, with a clean xterm UI, on-device GPU transcription, and no auto-submit (user reviews before pressing Enter).

## Hardware
- **Headset:** UC03 USB (ALSA card 3, native 32 kHz mono)
- **Audio server:** PipeWire
- **Speech engine:** whisper.cpp large-v3 via whisper-rs (GPU CUDA 13, CPU fallback)
- **Machine:** worlock (RTX 5080 + RTX 3080, dual GPU)

## What was set up

| Component | Path | Notes |
|-----------|------|-------|
| Push-to-talk binary | `/usr/local/bin/voice-input` | Rust binary, pre-existing |
| Hotkey wrapper | `/usr/local/bin/voice-hotkey` | New — see below |
| xbindkeys config | `~/.xbindkeysrc` | Ctrl+Alt+V binding |
| xbindkeys autostart | `~/.zshrc` | `pgrep xbindkeys \|\| xbindkeys` |
| MOTD status block | `/etc/update-motd.d/96-voice-hotkey-status` | Shows on every login |

## How it works

```
Ctrl+Alt+V pressed
  → xbindkeys fires voice-hotkey
  → focused window ID saved via xdotool getactivewindow
  → small xterm opens (64x8, top-right corner)
  → voice-input --mode print runs inside xterm:
      stderr → shows in xterm ("Recording… press Enter to stop")
      stdout → captured to /tmp/voice-XXXXXX.txt
  → user speaks, presses Enter in xterm
  → whisper.cpp transcribes (~1-3s GPU)
  → xterm closes
  → xdotool refocuses original window
  → transcript typed into Claude Code prompt
  → user reviews and presses Enter to submit
```

## Workflow (final)
1. Claude Code terminal focused, cursor at empty prompt
2. Press **Ctrl+Alt+V**
3. Small xterm appears — `[voice-input] Recording… press Enter to stop (auto-stop at 65s)`
4. Speak your prompt
5. Press **Enter** in xterm to stop
6. `[voice-input] Transcribing…` → `[closing in 1s]`
7. xterm closes, Claude Code regains focus
8. Spoken words appear in the prompt — **press Enter yourself to submit**

## Usability change made during session
Auto-submit was removed after first successful test. The `xdotool key Return` line was deleted
from `voice-hotkey` so the user can review/edit the transcript before submitting.

## Files created

### Scripts & config
- `/usr/local/bin/voice-hotkey` — orchestrator script
- `~/.xbindkeysrc` — xbindkeys hotkey config
- `/etc/update-motd.d/96-voice-hotkey-status` — MOTD status fragment

### Repo contents (https://github.com/danindiana/voice-hotkey)
- `voice-hotkey` — the script
- `install.sh` — one-command installer
- `.xbindkeysrc.example` — hotkey config template
- `README.md` — full docs with logo and diagrams embedded
- `assets/logo.svg` / `logo.png` — dark neon logo (mic + waveform)
- `assets/flow.dot/png/svg` — data flow: keypress → Claude Code
- `assets/arch.dot/png/svg` — component architecture: hardware → inference → target

## Key design decisions
- **`--mode print` not `--mode type`**: stdout-only transcript captured to tmpfile; xdotool
  types it after refocusing. `--mode type` would have typed into xterm (wrong window).
- **XDG_RUNTIME_DIR=/run/user/1000** needed in MOTD script for `pactl` to reach PipeWire
  session when running as root.
- **No auto-submit**: removed `xdotool key Return` — user reviews transcript first.

## Gotchas
- 32 kHz sample rate: UC03 native. Forcing 16 kHz causes near-silence.
- xbindkeys must be running: `pgrep xbindkeys || xbindkeys` in ~/.zshrc handles reboots.
- MOTD runs as root — hardcoded `/home/jeb` paths and `XDG_RUNTIME_DIR=/run/user/1000`.
