pragma Singleton 

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {

    id: root

    property var icons: []

    function fetch(...queries) {
        cache.reload()
        for (const query of queries) {
            const result = root.icons.find(item => 
            item.name.toLowerCase().includes(query.toLowerCase()) || 
            item.icon.toLowerCase().includes(query.toLowerCase()))
            if (result) {
                return result.icon
            }
        }
        return "exception"
    }

    function reload() {
        cache.reload()
    }

    FileView {
        id: cache

        path: ".config/quickshell/tui/scripts/icon_cache.json"

        onLoaded: {
            root.icons = JSON.parse(text())
        }

    }

    Timer {
        running: true
        interval: 1000
        repeat: true

        onTriggered: {
            root.reload()
        }
    }

}
