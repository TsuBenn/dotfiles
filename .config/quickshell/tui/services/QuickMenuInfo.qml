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
        let abbriviate = {
            "pageup": "pup",
            "pagedown": "pdown",
            "return": "ret",
            "backspace": "bs",
            "delete": "del",
            "up": "↑",
            "left": "←",
            "down": "↓",
            "right": "→",
            "plus": "+",
            "minus": "-",
            "equal": "=",
            "semicolon": ";",
            "colon": ":",
            "comma": ",",
            "period": ".",
            "slash": "/",
            "pipe": "|",
            "backslash": "\\",
            "singlequote": "'",
            "quote": '"',
            "tick": '`',
            "dot": ".",
            "doublequote": '"',
            "grave": "`",
            "tilde": "~",
            "exclamation": "!",
            "at": "@",
            "hashtag": "#",
            "tag": "#",
            "dollar": "$",
            "money": "$",
            "percent": "%",
            "percentage": "%",
            "caret": "^",
            "ampersand": "&",
            "amp": "&",
            "and": "&",
            "asterisk": "*",
            "multiply": "*",
            "star": "*"
        };
        let special = {
            "print": "print",
            "ret": "return",
            "bs": "backspace",
            "pup": "pgup",
            "pdwn": "pgdown",
            "end": "end",
            "tab": "tab",
            "del": "delete",
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
            "↑": "up",
            "←": "left",
            "↓": "down",
            "→": "right"
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
                    let abb = abbriviate[key];
                    key = abb ?? key;
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
                        revised += abb?.toUpperCase() ?? match[7].toUpperCase();
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
                binds[i].action = "no_operation";
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

    /*

    {
        "label": "Open ghostty",
        "cmd": "ghostty"
    }

    */

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
        }
    }
}

/*

I want you to write a document/guide of a utility I'm currently building.
It's called a Quick Menu.
My goal of this utility is for the user to quickly do certain things using keybinds.
When they activate this utility, a popup shows up and disable almost every keyboard binds of the desktop, giving the user every possible keybinds mapped to a certain action, *any action*.
The UI of this popup includes a list of actions that the user can add or remove. Each items includes a drop down menu including the action and a text field including the keybinds that the user can type in which activate the action selected by the drop down menu.
For the text field, there are rules to how you type in the keybinds.

* No duplicate binds, if opening the app launcher was mapped to W above and below has opening the calendar mapped to also W, it will ignore the latter and throw an exclamation marks on the duplicated one and only keep the first one with the bind.
* No Meta/Super key nor Escape, this is the desktop exclusive key so it's forbidden to use it.
* Modifiers should be properly or the first char with those modifiers (e.g control can be written as "c", "ctrl" or "control") written and joined with final key using either a "-" or a "+" (e.g control + C can be written as "C-c").
* The key can be of the following value:
   * ret, return: Return
   * tab: Tab
   * pup, pageup: Page up
   * pdown, pagedown: Page down
   * backspace, bs: Backspace
   * end: End
   * f1 - f35: F1-F35
   * up/down/left/right: Up/Down/Left/Right
   * a-z: A-Z
   * 0-9: 0-9
   * Any sorts of brackets, open or closed
   * tick, `, plus, +, minus, -, equal, =, slash, /, backslash, \, quote, ", singlequote, ', pipe, |, dot, period, ".", comma, ",", exclamation,!, at, @, hashtag, tag, #, dollar, $, percent, percentage, %, caret, hat, ^, ampersand, amp, and, &, asterisk, multiply, star, *, tilde,~.
* Which ever key that is not supported would be thrown an error indicated by a exlamation mark next to the bind and be colored red or simply be ignored.

For the actions provided in the drop down menu, by default will include things that the desktop can do, but you can add your custom action by pressing the "Manage custom actions" and it will lead you to a menu of custom actions.
Each custom actions needs a label and a shell command, yes the custom actions can only execute 1 line of command, so if you wanna have a more complex command please call your custom script from here via "sh -c path/to/your/script" or as a binary if available.
Custom actions shall not be labeled similar to the default as it will override the default actions if it has similar label. The label will be converted into snake case as its id for look up.
Custom actions can be added or removed.
If a keybinds is being mapped to a non-existence action (maybe it's because you'be removed it), it will be set back to "No operation" by default.

Please write the document in plain text with some uses of tags like <b></b> or <i></i>. Try not to use tables, just bullet points and pure lists. Try your best to make it pleasing to read and not too cramped
This text will be rendered inside of a small TUI window with a size of 46 by 18 will scroll view on the vertical and not horizontal. Also the renderer has its own way of handling wrapping so no needs wrapping it yourself.

*/
