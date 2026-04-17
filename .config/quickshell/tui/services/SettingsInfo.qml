pragma Singleton

import qs.config
import qs.services

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    // Only those that has a submenu has an id 

    property var result: []

    property var palettes: Object.keys(Colors.colors)

    property var data: [
        {
            id: "Wallpapers",
            label: "Wallpapers >",
            description: "Changes how your wallpaper looks and behaves.",
            type: "function",
            value: () => {PopupManager.open("wallpaper")}
        },
        {
            id: "Color themes",
            label: "Color themes >",
            description: "Changes your shell's color palette that fit your vibe.",
            type: "submenu",
            value: resolvePalettes()
        },
        {
            id: "System checks",
            label: "System checks >",
            description: "Making sure that your shell is working normally.",
            type: "submenu",
            value: [
                {
                    label: "Notification check",
                    description: "Send a dummy notification.",
                    type: "exec",
                    value: ["notify-send", "Notification checker", "Check check check!"],
                },
                {
                    label: "Audio check",
                    description: "Play a random cute anime girl sound effect at MAX volume.",
                    type: "function",
                    value: () => {
                        const rng = Math.random()
                        const sound = Math.round(rng*4)
                        const sounds = ["hallo","mambo","mambo_tongye","mambo_wow"]
                        AudioInfo.playSound(sounds[sound], 1)
                    },
                },
                {
                    label: "Toggle grid",
                    description: "Show terminal cells grid making sure everything is aligned properly.",
                    type: "exec",
                    value: ["qs", "-c", "tui", "ipc", "call", "debug", "toggleGrid"],
                },
            ]
        },
    ]

    function resolvePalettes(): var {
        let result = []
        for (const palette of palettes) {
            result.push({
                label: palette,
                description: "",
                type: "function",
                value: () => {Colors.current = palette},
            })
        }
        return result
    }

    function reset() {
        result = []
    }

    function get(id: string) {
        return data.find(item => item.id == id)
    }

    function isValidPath(paths = []) {
        if (!paths) return false
        let data = SettingsInfo.data
        for (const path of paths) {
            const submenu = data.find(item => {return item.id == path})
            if (submenu) {
                data = submenu.value
                continue
            }
            return false
        }
        return true
    }

    function search(paths = [], query = "") {
        query = query.toLowerCase()
        let data = SettingsInfo.data
        for (const path of paths) {
            const submenu = data.find(item => {return item.id == path})
            if (submenu) {
                data = submenu.value
            }
        }
        const search = data.filter(category => {

            const matchesMain = category.label.toLowerCase().includes(query) || 
            category.description?.toLowerCase().includes(query) || query == ""

            return matchesMain;
        });
        result = search
    }

    function run(item: var): string {
        if (item.type == "exec") {
            exec.command = item.value
            exec.startDetached()
        } else if (item.type == "function") {
            item.value()
        } else if (item.type == "submenu") {
            return item.id
        }
        return "null"
    }

    Process {
        id: exec
    }

}
