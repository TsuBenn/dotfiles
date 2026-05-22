pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property var emojis: []

    property var recent: []

    function search(query: string, max: int): var {
        query = query.toLowerCase()
        let result = []
        for (const emoji of emojis) {
            if (
                emoji.label.toLowerCase().includes(query)
                || emoji.description.toLowerCase().includes(query)
                || emoji.keywords.some(item => item.toLowerCase().includes(query))
                || emoji.group.toLowerCase().includes(query)
            ) {
                result.push(emoji)
            }
            if (result.length >= max) {
                break
            }
        }
        return result
    }

    function select(emoji: var) {
        // 1. Create a clean list by filtering out the duplicate if it exists
        const filtered = root.recent.filter(item => item.label !== emoji.label);

        // 2. Put the newly selected emoji at the front of the filtered list
        root.recent = [emoji, ...filtered];

        // 3. Keep the list from growing infinitely (optional cap, e.g., max 20 items)
        if (root.recent.length > 20) {
            root.recent = root.recent.slice(0, 20);
        }

        saveRecent()
        SystemInfo.runDetached(["bash", "-c", "wtype \"" + emoji.label + "\""]);
    }

    function saveRecent() {
        SystemInfo.runDetached(["bash", "-c", "echo '" + JSON.stringify(root.recent) + "' > " + SystemInfo.configdir + "/scripts/emojis_recent.json"])
    }

    FileView {

        id: recent_loader

        path: SystemInfo.configdir + "/scripts/emojis_recent.json"

        onLoaded: {
            if (text()) {
                root.recent = JSON.parse(text())
            }
        }

    }

    FileView {

        id: loader

        path: SystemInfo.configdir + "/scripts/emojis.json"

        onLoaded: {
            if (text()) {
                root.emojis = JSON.parse(text())
            }
        }

    }

}
