pragma Singleton

import qs.config

import QtQuick
import Quickshell

Singleton {

    id: root

    property var shortcuts: []

    Connections {
        target: PopupManager
        function onClosed(name: string) {
            // When no popup is topmost, clear shortcuts so we don't
            // hold references to destroyed popup closures.
            if (PopupManager.getTop() === "") {
                root.shortcuts = []
            }
        }
    }
}
