#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[voice-hotkey] Installing dependencies..."
sudo apt-get install -y xbindkeys xterm xdotool

echo "[voice-hotkey] Installing /usr/local/bin/voice-hotkey..."
sudo cp "$SCRIPT_DIR/voice-hotkey" /usr/local/bin/voice-hotkey
sudo chmod +x /usr/local/bin/voice-hotkey

echo "[voice-hotkey] Writing ~/.xbindkeysrc..."
if [[ -f ~/.xbindkeysrc ]]; then
    if grep -q "voice-hotkey" ~/.xbindkeysrc; then
        echo "  Already present in ~/.xbindkeysrc — skipping."
    else
        echo "" >> ~/.xbindkeysrc
        cat "$SCRIPT_DIR/.xbindkeysrc.example" >> ~/.xbindkeysrc
        echo "  Appended to existing ~/.xbindkeysrc."
    fi
else
    cp "$SCRIPT_DIR/.xbindkeysrc.example" ~/.xbindkeysrc
    echo "  Created ~/.xbindkeysrc."
fi

echo "[voice-hotkey] Starting xbindkeys daemon..."
pkill xbindkeys 2>/dev/null || true
sleep 0.2
xbindkeys
echo "  xbindkeys running (PID $(pgrep xbindkeys))."

# Detect shell RC file
SHELL_RC=""
if [[ -f ~/.zshrc ]]; then
    SHELL_RC=~/.zshrc
elif [[ -f ~/.bashrc ]]; then
    SHELL_RC=~/.bashrc
fi

if [[ -n "$SHELL_RC" ]]; then
    if grep -q "xbindkeys" "$SHELL_RC"; then
        echo "[voice-hotkey] Autostart already in $SHELL_RC — skipping."
    else
        echo "" >> "$SHELL_RC"
        echo "# voice-hotkey push-to-talk daemon" >> "$SHELL_RC"
        echo "pgrep xbindkeys >/dev/null || xbindkeys" >> "$SHELL_RC"
        echo "[voice-hotkey] Autostart added to $SHELL_RC."
    fi
fi

echo ""
echo "Done! Press Ctrl+Alt+V to start push-to-talk."
echo "Make sure voice-input is installed: https://github.com/danindiana/voice-input"
