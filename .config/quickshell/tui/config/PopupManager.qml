pragma Singleton

import Quickshell
import QtQuick

Singleton {

    id: root

    property bool preventClosing: false

    property var active_popups: []

    signal opened(name: string)
    signal closed(name: string)

    function open(name: string, isolate = true) {
        if (isolate) close()
        active_popups = [...active_popups, name]
        root.opened(name)
    }

    function toggle(name: string, isolate = true) {
        isOpen(name) ? close(name) : open(name,isolate)
    }

    function close(name = "") {
        if (preventClosing) {
            preventClosing = false
            return
        }
        if (name == "") active_popups = [] 
        else active_popups = active_popups.filter(p => p != name)
        closed(name)
    }

    function isOpen(name: string): bool {
        return active_popups.includes(name)
    }

}
