pragma Singleton

import qs.config
import qs.services

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    /*

     binds:
     [
         {
             binds: ["W"],
             actions: "open_power"
         },
         {
             binds: ["Q"],
             actions: "open_wallpaper"
         }
     ]

     actions:
     {
         "open_power": {
             "label": "Open power menu",
             "action": function() {

             }
         }
     }

     */

    property var shortcuts: []

    property string path: SystemInfo.configdir + "/scripts/quickmenu_config.json"

    property var blacklist: ["esc", "print",]

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
        loader.setText(JSON.stringify(binds, null, 2));
    }

    function decodeBinds(binds: var): var {
        let usage = [];
        let display = [];
        let special = {
            "print": "print",
            "ret": "return",
            "bs": "backspace",
            "pup": "pgup",
            "pdown": "pgdown",
            "end": "end",
            "tab": "tab",
            "f1": "f1",
            "f2": "f2",
            "f3": "f3",
            "f4": "f4",
            "f5": "f5",
            "f6": "f6",
            "f7": "f7",
            "f8": "f8",
            "f9": "f9",
            "f10": "f10",
            "f11": "f11",
            "f12": "f12",
            "f13": "f13",
            "f14": "f14",
            "f15": "f15",
            "f16": "f16",
            "f17": "f17",
            "f18": "f18",
            "f19": "f19",
            "f20": "f20",
            "f21": "f21",
            "f22": "f22",
            "f23": "f23",
            "f24": "f24",
            "f25": "f25",
            "f26": "f26",
            "f27": "f27",
            "f28": "f28",
            "f29": "f29",
            "f30": "f30",
            "f31": "f31",
            "f32": "f32",
            "f33": "f33",
            "f34": "f34",
            "f35": "f35",
            "up": "up",
            "left": "left",
            "right": "right",
            "down": "down"
        };
        for (const bind of binds) {
            const regex = /^((c|ctrl|control)[-+])?((s|shift)[-+])?((a|alt)[-+])?(\S+)(!)?$/i;
            let match = bind.match(regex);
            let combo = "";
            let revised = "";
            if (match) {
                if (match[2]) {
                    combo += "ctrl+";
                    revised += "C-";
                }
                if (match[4]) {
                    combo += "shift+";
                    revised += "S-";
                }
                if (match[6]) {
                    combo += "alt+";
                    revised += "A-";
                }
                if (match[7]) {
                    let key = match[7].toLowerCase();
                    if (key.length > 1) {
                        if (!key.endsWith("!")) {
                            if (Object.keys(special).includes(key)) {
                                key = special[key];
                            } else {
                                key = "";
                            }
                        }
                    } else {
                        key = match[7];
                    }
                    if (key) {
                        combo += key.toLowerCase();
                        revised += match[7].toUpperCase();
                    } else {
                        combo = "";
                        revised += match[7].toUpperCase() + "!";
                    }
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
                binds[i].action = "no_op";
                success = false;
            }
            let eval_binds = decodeBinds(binds[i].binds);
            let eval_action = actions[binds[i].action].action;
            for (const j in eval_binds.display) {
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
            root.binds = JSON.parse(text());
        }

        printErrors: false
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                setText(JSON.stringify(root.binds, null, 2));
            }
        }
    }

    property var binds: [
        {
            binds: ["W"],
            action: "open_power"
        },
        {
            binds: ["Q"],
            action: "open_wallpaper"
        }
    ]

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
            action: "no_op"
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
        customs = customs[customs.length - 1];
        console.log(customs);
        editCustom(customs + "_copy", custom_actions[customs].label + " copy", custom_actions[customs].cmd);
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
        let actions = default_actions;
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

    /*

    {
        "label": "Open ghostty",
        "cmd": "ghostty"
    }

    */

    property var custom_actions: ({
            "open_ghostty": {
                "label": "Open ghostty",
                "cmd": "ghostty"
            }
        })

    property var default_actions: {
        "no_op": {
            "label": "No operation",
            "action": function () {}
        },
        "open_power": {
            "label": "Open power menu",
            "action": function () {
                PopupManager.open("power");
            }
        },
        "open_wallpaper": {
            "label": "Open wallpaper menu",
            "action": function () {
                PopupManager.open("wallpaper");
            }
        },
        "open_calendar": {
            "label": "Open calendar",
            "action": function () {
                PopupManager.open("calendar");
            }
        },
        "open_media": {
            "label": "Open media player",
            "action": function () {
                PopupManager.open("media_player");
            }
        },
        "open_notification": {
            "label": "Open notification",
            "action": function () {
                PopupManager.signalSent("control_panel", "notif");
                PopupManager.open("control_panel");
            }
        },
        "open_mixer": {
            "label": "Open audio mixer",
            "action": function () {
                PopupManager.signalSent("control_panel", "mixer");
                PopupManager.open("control_panel");
            }
        },
        "open_system": {
            "label": "Open system info",
            "action": function () {
                PopupManager.open("system");
            }
        },
        "open_pacman": {
            "label": "Open pacman",
            "action": function () {
                PopupManager.open("pacman");
            }
        },
        "open_color": {
            "label": "Open color menu",
            "action": function () {
                PopupManager.open("color");
            }
        },
        "open_launcher": {
            "label": "Open app launcher",
            "action": function () {
                PopupManager.open("launcher");
            }
        }
    }
}
