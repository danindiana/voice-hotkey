# Session: Push-to-Talk Hotkey for Claude Code
**Date:** 2026-05-03  
**Goal:** Wire up a global keyboard shortcut to trigger push-to-talk voice input into Claude Code.

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
| xbindkeys config | `~/.xbindkeysrc` | New — Ctrl+Alt+V binding |
| xbindkeys daemon | running as user | Autostart via ~/.zshrc |

## How it works

```
Ctrl+Alt+V pressed
  → xbindkeys fires voice-hotkey
  → focused window ID saved via xdotool
  → small xterm opens (64x8, top-right corner)
  → voice-input --mode print runs:
      stderr → shows in xterm (status: "Recording... press Enter")
      stdout → captured to /tmp/voice-XXXXXX.txt
  → user speaks, presses Enter
  → whisper.cpp transcribes (GPU, ~1-3s)
  → xterm closes
  → xdotool refocuses original window
  → transcript typed in + Enter submitted
```

## Workflow
1. Claude Code terminal focused, cursor at empty prompt
2. Press **Ctrl+Alt+V**
3. Small xterm appears — you see: `[voice-input] Recording… press Enter to stop (auto-stop at 65s)`
4. Speak your prompt
5. Press **Enter** in xterm to stop recording
6. You see: `[voice-input] Transcribing…` then `[closing in 1s]`
7. xterm closes, Claude Code gets focus back
8. Your spoken words appear at the Claude Code prompt and are submitted

## Files created/modified
- `/usr/local/bin/voice-hotkey` — wrapper script
- `~/.xbindkeysrc` — xbindkeys binding
- `~/.zshrc` — autostart line appended (if done)

## Gotchas
- **32 kHz matters**: UC03 native rate is 32 kHz. The voice-input binary handles this correctly.
- **Focus window**: xdotool grabs window ID before xterm opens. If xterm fails to close cleanly, 
  re-focus may still work because the ID is captured upfront.
- **Error output**: `[voice-input] Error` lines in stdout would suppress typing (guard in script).
  All normal status messages go to stderr (shown in xterm, not captured).
- **xbindkeys autostart**: Add `pgrep xbindkeys >/dev/null || xbindkeys` to ~/.zshrc to
  survive reboots.

## Autostart (add to ~/.zshrc if not done)
```bash
# Push-to-talk hotkey daemon
pgrep xbindkeys >/dev/null || xbindkeys
```
