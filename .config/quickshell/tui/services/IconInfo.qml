pragma Singleton 

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property var icons: []

    function fetch(queries) {
        cache.reload()
        for (let query of queries) {
            if (!query) continue
            const parts = query.split('.')
            if (parts.length > 1) {
                parts.pop()
            }
            query = parts.join('.')
            const result = root.icons.find((item) => {
                const match = item.name.toLowerCase().includes(query.toLowerCase()) ||
                              item.icon.toLowerCase().includes(query.toLowerCase())
                return match
            })
            if (result) {
                return result.icon
            }
        }
        return ""
    }

    function reload() {
        cache.reload()
    }

    FileView {
        id: cache

        path: SystemInfo.homedir + "/dotfiles/.config/quickshell/tui/scripts/icon_cache.json"

        onLoaded: {
            root.icons = JSON.parse(text())
        }

    }

}
