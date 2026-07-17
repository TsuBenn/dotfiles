pragma Singleton

import qs.config
import qs.services

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var shortcuts: []

    property string path: SystemInfo.configdir + "/scripts/quickmenu_config.json"

    property string custom_path: SystemInfo.configdir + "/scripts/custom_actions.json"

    property var blacklist: ["esc", "print",]

    property var binds: [
        {
            binds: ["W"],
            action: "open_power_menu"
        },
        {
            binds: ["Q"],
            action: "open_wallpaper_menu"
        }
    ]

    property var custom_actions: ({
            "open_ghostty": {
                "label": "Open ghostty",
                "cmd": "ghostty"
            }
        })

    onBindsChanged: {
        if (!evalShortcuts()) {
            bindsChanged();
            return;
        }
        if (loader.preload) {
            saveConfig();
        } else {
            loader.preload = true;
        }
    }

    function saveConfig() {
        let config = {
            "binds": root.binds,
            "custom_actions": root.custom_actions
        };
        loader.setText(JSON.stringify(config, null, 2));
    }

    function decodeBinds(binds: var): var {
        let usage = [];
        let display = [];

        // Maps raw input characters/strings to Qt Key names for usage
        let qtKeyNames = {
            "pageup": "PageUp",
            "pagedown": "PageDown",
            "return": "Return",
            "enter": "Return",
            "backspace": "Backspace",
            "delete": "Delete",
            "escape": "Escape",
            "esc": "Escape",
            "space": "Space",
            "tab": "Tab",
            "up": "Up",
            "left": "Left",
            "down": "Down",
            "right": "Right",
            "plus": "Plus",
            "minus": "Minus",
            "equal": "Equal",
            "less": "Less",
            "greater": "Greater",
            "semicolon": "Semicolon",
            "colon": "Colon",
            "comma": "Comma",
            "period": "Period",
            "dot": "Period",
            "slash": "Slash",
            "pipe": "Bar",
            "backslash": "Backslash",
            "singlequote": "Apostrophe",
            "apostrophe": "Apostrophe",
            "quote": "QuoteLeft",
            "doublequote": "QuoteDbl",
            "tick": "QuoteLeft",
            "grave": "QuoteLeft",
            "tilde": "AsciiTilde",
            "exclamation": "Exclam",
            "!": "Exclam",
            "at": "At",
            "@": "At",
            "hashtag": "Numbersign",
            "tag": "Numbersign",
            "#": "Numbersign",
            "dollar": "Dollar",
            "money": "Dollar",
            "$": "Dollar",
            "percent": "Percent",
            "percentage": "Percent",
            "%": "Percent",
            "caret": "AsciiCaret",
            "^": "AsciiCaret",
            "ampersand": "Ampersand",
            "amp": "Ampersand",
            "and": "Ampersand",
            "&": "Ampersand",
            "asterisk": "Asterisk",
            "multiply": "Asterisk",
            "star": "Asterisk",
            "*": "Asterisk",
            "(": "ParenLeft",
            ")": "ParenRight",
            "_": "Underscore",
            "+": "Plus",
            "{": "BraceLeft",
            "}": "BraceRight",
            "[": "BracketLeft",
            "]": "BracketRight",
            "|": "Bar",
            ":": "Colon",
            ";": "Semicolon",
            "\"": "QuoteDbl",
            "'": "Apostrophe",
            "<": "Less",
            ">": "Greater",
            "?": "Question",
            "/": "Slash",
            "\\": "Backslash",
            "~": "AsciiTilde",
            "`": "QuoteLeft",
            "=": "Equal",
            "-": "Minus"
        };

        // Maps raw inputs or Qt names to clean display abbreviations
        let abbreviateDisplay = {
            "pageup": "PUP",
            "pagedown": "PDOWN",
            "return": "RET",
            "backspace": "BS",
            "delete": "DEL",
            "escape": "ESC",
            "esc": "ESC",
            "up": "↑",
            "left": "←",
            "down": "↓",
            "right": "→",
            "parenleft": "(",
            "parenright": ")",
            "exclam": "!",
            "at": "@",
            "numbersign": "#",
            "dollar": "$",
            "percent": "%",
            "asciicaret": "^",
            "ampersand": "&",
            "asterisk": "*",
            "bracketleft": "[",
            "bracketright": "]",
            "braceleft": "{",
            "braceright": "}",
            "bar": "|",
            "backslash": "\\",
            "colon": ":",
            "semicolon": ";",
            "quotedbl": "\"",
            "apostrophe": "'",
            "less": "<",
            "greater": ">",
            "question": "?",
            "slash": "/",
            "asciitilde": "~",
            "quoteleft": "`",
            "equal": "=",
            "minus": "-",
            "plus": "+"
        };

        for (const bind of binds) {
            // Regex to grab modifier prefixes and the base key/character
            const regex = /^((c|ctrl|control)[-+])?((s|shift)[-+])?((a|alt)[-+])?(\S+)(!)?$/i;
            let match = bind.match(regex);
            let combo = "";
            let revised = "";

            if (match) {
                // 1. Build Modifiers for Usage (Qt format: "Ctrl+Shift+Alt+")
                if (match[2]) combo += "Ctrl+";
                if (match[4]) combo += "Shift+";
                if (match[6]) combo += "Alt+";

                // 2. Build Modifiers for Display (Vim format: "C-S-A-")
                if (match[2]) revised += "C-";
                if (match[4]) revised += "S-";
                if (match[6]) revised += "A-";

                if (match[7]) {
                    let rawKey = match[7];
                    let rawKeyLower = rawKey.toLowerCase();

                    let qtKey = "";
                    let dispKey = "";

                    // Match base key
                    if (qtKeyNames[rawKeyLower] !== undefined) {
                        qtKey = qtKeyNames[rawKeyLower];
                    } else {
                        // Default fallback (e.g. letters, numbers, or unmapped keys)
                        // Capitalize for proper Qt usage format (e.g. "a" -> "A")
                        qtKey = rawKey.length === 1 ? rawKey.toUpperCase() : rawKey;
                    }

                    // Match display name
                    let qtKeyLower = qtKey.toLowerCase();
                    if (abbreviateDisplay[rawKeyLower] !== undefined) {
                        dispKey = abbreviateDisplay[rawKeyLower];
                    } else if (abbreviateDisplay[qtKeyLower] !== undefined) {
                        dispKey = abbreviateDisplay[qtKeyLower];
                    } else {
                        dispKey = rawKey.toUpperCase();
                    }

                    combo += qtKey;
                    revised += dispKey;
                }

                if (match[8]) {
                    combo = "";
                    revised += "!";
                }
            }

            usage.push(combo);
            display.push(revised);
        }

        return {
            usage: usage,
            display: display
        };
    }

    function evalShortcuts(): bool {
        let success = true;
        let result = [];
        let dup = [];
        for (const i in binds) {
            if (!actions[binds[i].action]) {
                binds[i].action = "no_operation";
                success = false;
            }
            let eval_binds = decodeBinds(binds[i].binds);
            let eval_action = actions[binds[i].action].action;
            for (const j in eval_binds.display) {
                if (eval_binds.display == "") continue;
                if (dup.includes(eval_binds.display[j])) {
                    eval_binds.display[j] += "!";
                    success = false;
                } else {
                    dup.push(eval_binds.display[j]);
                }
            }
            binds[i].binds = eval_binds.display;
            result.push({
                "binds": eval_binds.usage,
                "action": eval_action
            });
        }
        root.shortcuts = result;
        return success;
    }

    FileView {
        id: loader

        path: root.path

        preload: false

        onLoaded: {
            const data = JSON.parse(text());
            const keys = Object.keys(data);
            if (!keys.includes("binds"))
                data.binds = root.binds;
            if (!keys.includes("custom_actions"))
                data.custom_actions = root.custom_actions;
            root.custom_actions = data.custom_actions;
            root.binds = data.binds;
        }

        printErrors: false
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                root.saveConfig();
            }
        }
    }

    function setAction(index: int, new_action: string) {
        binds[index].action = new_action;
        bindsChanged();
    }

    function setBinds(index: int, new_binds: var) {
        binds[index].binds = new_binds;
        bindsChanged();
    }

    function removeBinds(index: int) {
        binds.splice(index, 1);
        bindsChanged();
    }

    function addBinds() {
        binds.push({
            binds: [""],
            action: "no_operation"
        });
        bindsChanged();
    }

    function identify(label: string): string {
        return label.trim().toLowerCase().split(" ").join("_").trim();
    }

    function editCustom(id: string, label: string, cmd: string) {
        let identity = identify(label);
        if (identity == id) {
            custom_actions[id] = {
                "label": label.trim(),
                "cmd": cmd
            };
        } else {
            delete custom_actions[id];
            custom_actions[identity] = {
                "label": label.trim(),
                "cmd": cmd.trim()
            };
        }
        custom_actionsChanged();
    }

    function addCustom() {
        let customs = Object.keys(custom_actions);
        if (customs.length > 0) {
            customs = customs[customs.length - 1];
            editCustom(customs + "_copy", custom_actions[customs].label + " copy", custom_actions[customs].cmd);
        } else {
            editCustom("custom_action", "Custom action", "echo \"Custom action\"");
        }
    }

    function removeCustom(id: string) {
        if (Object.keys(custom_actions).includes(id)) {
            delete custom_actions[id];
            custom_actionsChanged();
        }
    }

    property var action_index: {
        let result = {};
        let keys = Object.keys(actions);
        for (let i = 0; i < keys.length; i++) {
            result[keys[i]] = i;
        }
        return result;
    }

    property var actions: {
        let custom = custom_actions;
        let actions = Object.assign({}, default_actions);
        for (const i in custom) {
            actions[i] = {
                "label": custom[i].label,
                "action": function () {
                    SystemInfo.runDetached(["sh", "-c", custom[i].cmd]);
                }
            };
        }
        return actions;
    }

    function refresh() {
        let custom = custom_actions;
        let actions = Object.assign({}, default_actions);
        for (const i in custom) {
            actions[i] = {
                "label": custom[i].label,
                "action": function () {
                    SystemInfo.runDetached(["sh", "-c", custom[i].cmd]);
                }
            };
        }
        root.actions = actions;
        root.actionsChanged();
    }

    onCustom_actionsChanged: {
        if (loader.preload) {
            refresh();
            bindsChanged();
            saveConfig();
        }
    }

    property var default_actions: {
        "no_operation": {
            "label": "No Operation",
            "action": function () {}
        },
        "open_power_menu": {
            "label": "Open Power Menu",
            "action": function () {
                PopupManager.open("power");
            }
        },
        "open_wallpaper_menu": {
            "label": "Open Wallpaper Menu",
            "action": function () {
                PopupManager.open("wallpaper");
            }
        },
        "open_calendar": {
            "label": "Open Calendar",
            "action": function () {
                PopupManager.open("calendar");
            }
        },
        "open_media_player": {
            "label": "Open Media Player",
            "action": function () {
                PopupManager.open("media_player");
            }
        },
        "open_notification": {
            "label": "Open Notification",
            "action": function () {
                PopupManager.signalSent("control_panel", "notif");
                PopupManager.open("control_panel");
            }
        },
        "open_audio_mixer": {
            "label": "Open Audio Mixer",
            "action": function () {
                PopupManager.signalSent("control_panel", "mixer");
                PopupManager.open("control_panel");
            }
        },
        "open_system_info": {
            "label": "Open System info",
            "action": function () {
                PopupManager.open("system");
            }
        },
        "open_pacman": {
            "label": "Open Pacman",
            "action": function () {
                PopupManager.open("pacman");
            }
        },
        "open_color_menu": {
            "label": "Open Color Menu",
            "action": function () {
                PopupManager.open("color");
            }
        },
        "open_app_launcher": {
            "label": "Open App Launcher",
            "action": function () {
                PopupManager.open("launcher");
            }
        },
        "open_spell_checker": {
            "label": "Open Spell Checker",
            "action": function () {
                PopupManager.open("spell_checker");
            }
        }
    }
}
