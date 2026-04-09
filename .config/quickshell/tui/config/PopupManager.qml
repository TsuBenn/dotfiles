pragma Singleton

import Quickshell
import QtQuick

Singleton {

    id: root

    property bool bruh: true

    property var active_popups: []

    function open(name: string, isolate = true) {
        if (isolate) close()
        active_popups = [...active_popups, name]
    }

    function toggle(name: string, isolate = true) {
        isOpen(name) ? close(name) : open(name)
    }

    function close(name = "") {
        if (name == "") active_popups = [] 
        else active_popups = active_popups.filter(p => p != name)
    }

    function isOpen(name: string): bool {
        return active_popups.includes(name)
    }

}
