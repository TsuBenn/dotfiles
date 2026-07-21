pragma Singleton

import qs.config

import QtQuick
import Quickshell

Singleton {
    id: root

    function handleShortcuts(event, shortcuts) {
        for (const shortcut of shortcuts) {
            for (const bind of normalizeBinds(shortcut.binds)) {
                if (matchShortcut(event, bind)) {
                    if (shortcut.action())
                        event.accepted = true;
                    return true;
                }
            }
        }
        return false;
    }

    function normalizeBinds(binds) {
        if (typeof binds != "string") {
            return binds;
        } else {
            return [binds];
        }
    }

    function matchShortcut(event, shortcutStr) {
        let parts = shortcutStr.split("+");
        let rawKey = parts.pop().trim().toLowerCase();

        // 1. Build the target modifiers mask first
        let targetModifiers = 0;
        let hasShift = false;

        parts.forEach(mod => {
            mod = mod.trim().toLowerCase();
            if (mod === "ctrl" || mod === "control")
                targetModifiers |= Qt.ControlModifier;
            if (mod === "shift") {
                targetModifiers |= Qt.ShiftModifier;
                hasShift = true; // Flag that Shift is active
            }
            if (mod === "alt")
                targetModifiers |= Qt.AltModifier;
            if (mod === "meta" || mod === "super")
                targetModifiers |= Qt.MetaModifier;
        });

        // 2. Map common friendly names to official Qt names
        const aliasMap = {
            "esc": "Escape",
            "enter": "Return",
            "backspace": "Backspace",
            "delete": "Delete",
            "up": "Up",
            "down": "Down",
            "left": "Left",
            "right": "Right",
            "space": "Space",
            // TRAPDOOR FIX: If Shift is held, Tab changes its identity to Backtab
            "tab": hasShift ? "Backtab" : "Tab"
        };

        let targetKeyStr = "";
        if (aliasMap[rawKey]) {
            targetKeyStr = aliasMap[rawKey];
        } else {
            targetKeyStr = rawKey.charAt(0).toUpperCase() + rawKey.slice(1);
        }

        let targetKeyCode = Qt["Key_" + targetKeyStr];
        if (targetKeyCode === undefined)
            return false;

        let modifiersMatch = (event.modifiers & targetModifiers) === targetModifiers;
        let keyMatch = event.key === targetKeyCode;

        return modifiersMatch && keyMatch;
    }
}
