pragma Singleton

import qs.config
import qs.services

import Quickshell

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
             "action": () => {

             }
         }
     }

     */

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

    property var action_index: {
        let result = {}
        let keys = Object.keys(actions)
        for (let i = 0; i < keys.length; i++) {
            result[keys[i]] = i
        }
        return result
    }

    property var actions: {
        "open_power": {
            "label": "Open power menu",
            "action": () => {
                PopupManager.open("power")
            },
        },
        "open_wallpaper": {
            "label": "Open wallpaper menu",
            "action": () => {
                PopupManager.open("wallpaper")
            },
        },
        "open_calendar": {
            "label": "Open calendar",
            "action": () => {
                PopupManager.open("calendar")
            },
        },
        "open_notification": {
            "label": "Open notification",
            "action": () => {
                PopupManager.signalSent("control_panel", "notif")
                PopupManager.open("control_panel")
            },
        },
        "open_mixer": {
            "label": "Open audio mixer",
            "action": () => {
                PopupManager.signalSent("control_panel", "mixer")
                PopupManager.open("control_panel")
            },
        },
        "open_system": {
            "label": "Open system info",
            "action": () => {
                PopupManager.open("system")
            },
        },
        "open_pacman": {
            "label": "Open pacman",
            "action": () => {
                PopupManager.open("pacman")
            },
        },
        "open_color": {
            "label": "Open color theme menu",
            "action": () => {
                PopupManager.open("color")
            },
        },
    }

}

