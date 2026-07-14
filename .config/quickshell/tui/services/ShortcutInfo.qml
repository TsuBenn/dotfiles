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
                    return;
                }
            }
        }
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
        let rawKey = parts.pop().trim().toLowerCase(); // Use lowercase first to clean it up

        // 1. Map common friendly names to official Qt names (matching Qt's exact case)
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
            "tab": "Tab"
        };

        let targetKeyStr = "";
        if (aliasMap[rawKey]) {
            targetKeyStr = aliasMap[rawKey];
        } else {
            // Fallback: PascalCase formatting (e.g., "a" -> "A", "home" -> "Home")
            targetKeyStr = rawKey.charAt(0).toUpperCase() + rawKey.slice(1);
        }

        // 2. Build the target modifiers mask
        let targetModifiers = 0;
        parts.forEach(mod => {
            mod = mod.trim().toLowerCase();
            if (mod === "ctrl" || mod === "control")
                targetModifiers |= Qt.ControlModifier;
            if (mod === "shift")
                targetModifiers |= Qt.ShiftModifier;
            if (mod === "alt")
                targetModifiers |= Qt.AltModifier;
            if (mod === "meta" || mod === "super")
                targetModifiers |= Qt.MetaModifier;
        });

        // 3. Dynamic lookup now matches Qt.Key_Escape, Qt.Key_A, etc.
        let targetKeyCode = Qt["Key_" + targetKeyStr];
        if (targetKeyCode === undefined) {
            console.warn("Invalid key name resolved in lookup: Qt.Key_" + targetKeyStr);
            return false;
        }

        let modifiersMatch = (event.modifiers & targetModifiers) === targetModifiers;
        let keyMatch = event.key === targetKeyCode;

        return modifiersMatch && keyMatch;
    }
}
