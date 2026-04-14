pragma Singleton 

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property var icons

    signal searched()

    function fetch(...queries): string {
        for (const query of queries) {
            if (!query) continue
            if (!icons || !icons[query]) {
                continue
            }
            console.log("Found icon: " + query)
            return root.icons[query]
        }
        console.log("No Icon found for: " + queries)
        find(...queries)
        return "nothing"
    }

    function find(...queries) {
        icon_search.queue = [...icon_search.queue, ...queries]
        icon_search.running = true
    }

    FileView {
        id: cache

        path: ".config/quickshell/tui/scripts/icon_cache.json"

        onLoaded: {
            const data = JSON.parse(text())
            root.icons = data
        }

    }

    Process {

        id: icon_search

        property var queue: [] 

        running: false
        command: ["python", ".config/quickshell/tui/scripts/launcher.py", "--icons", ...queue]

        stdout: StdioCollector {
            onStreamFinished: {
                console.log(text)
                const data = JSON.parse(text)
                if (!Object.values(data).every(v => v === null)) {
                    cache.reload()
                }
                root.searched()
            }
        }

    }

}
