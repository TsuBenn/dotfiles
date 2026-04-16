pragma Singleton

import qs.config
import qs.services

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    // Only those that has a submenu has an id 

    property var result: []

    property var data: [
        {
            id: "wallpaper",
            label: "Wallpapers",
            description: "Changes how your wallpaper looks and behaves",
            type: "function",
            value: () => {PopupManager.open("wallpaper")}
        },
        {
            label: "Notification check",
            description: "Check you notification",
            type: "exec",
            value: ["notify-send", "Notification", "check check check"]
        },
    ]

    function reset() {
        result = []
    }

    function get(id: string) {
        return data.find(item => item.id == id)
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
