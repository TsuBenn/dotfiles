pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property var emojis: []

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
