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

    property var blacklist: [
        "esc",
        "meta",
        "print",
    ]

    property var faultyIndex: []

    onBindsChanged: {
        evalShortcuts()
        let fixed = false
        for (const i in binds) {
            if (!actions[binds[i].action]) {
                binds[i].action = "no_op"
                fixed = true
            }
        }
        if (fixed) {
            bindsChanged()
            return
        }
        if (loader.preload) {
            saveConfig()
        } else {
            loader.preload = true
        }
    }

    function saveConfig() {
        loader.setText(JSON.stringify(binds,null,2))
    }

    function evalShortcuts() {
        faultyIndex = []
        let result = []
        let dup = []
        for (const i in binds) {
            let eval_binds = binds[i].binds
            for (const j of eval_binds) {
                for (const k of blacklist) {
                    if (j.toLowerCase().includes(k)) {
                        dup.push(j)
                        break
                    }
                }
                if (dup.includes(j)) {
                    root.faultyIndex.push(i)
                    break
                } else {
                    dup.push(j)
                }
            }
            console.log(faultyIndex.includes(i))
            result.push({
                "binds": faultyIndex.includes(i) ? [""] : eval_binds,
                "action": actions[binds[i].action].action,
            })
        }
        root.shortcuts = result
    }

    FileView {

        id: loader

        path: root.path

        preload: false

        onLoaded: {
            root.binds = JSON.parse(text())
        }

        printErrors: false
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                setText(JSON.stringify(root.binds,null,2))
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
        binds[index].action = new_action
        bindsChanged()
    }

    function setBinds(index: int, new_binds: var) {
        binds[index].binds = new_binds
        bindsChanged()
    }

    function removeBinds(index: int) {
        binds.splice(index,1)
        bindsChanged()
    }

    function addBinds() {
        binds.push({
            binds: [""],
            action: "no_op",
        })
        bindsChanged()
    }

    property var action_index: {
        let result = {}
        let keys = Object.keys(actions)
        for (let i = 0; i < keys.length; i++) {
            result[keys[i]] = i
        }
        return result
    }

    property var actions: Object.assign(default_actions,custom_actions)

    property var custom_actions: ({
    })

    property var default_actions: {
        "no_op": {
            "label": "No operation",
            "action": function() {
            },
        },
        "open_power": {
            "label": "Open power menu",
            "action": function() {
                PopupManager.open("power")
            },
        },
        "open_wallpaper": {
            "label": "Open wallpaper menu",
            "action": function() {
                PopupManager.open("wallpaper")
            },
        },
        "open_calendar": {
            "label": "Open calendar",
            "action": function() {
                PopupManager.open("calendar")
            },
        },
        "open_media": {
            "label": "Open media player",
            "action": function() {
                PopupManager.open("media_player")
            },
        },
        "open_notification": {
            "label": "Open notification",
            "action": function() {
                PopupManager.signalSent("control_panel", "notif")
                PopupManager.open("control_panel")
            },
        },
        "open_mixer": {
            "label": "Open audio mixer",
            "action": function() {
                PopupManager.signalSent("control_panel", "mixer")
                PopupManager.open("control_panel")
            },
        },
        "open_system": {
            "label": "Open system info",
            "action": function() {
                PopupManager.open("system")
            },
        },
        "open_pacman": {
            "label": "Open pacman",
            "action": function() {
                PopupManager.open("pacman")
            },
        },
        "open_color": {
            "label": "Open color menu",
            "action": function() {
                PopupManager.open("color")
            },
        },
        "open_launcher": {
            "label": "Open app launcher",
            "action": function() {
                PopupManager.open("launcher")
            },
        }
    }

}

