pragma Singleton

import qs.components.floats
import qs.services

import Quickshell
import QtQuick

Singleton {
    id: root

    property var active_floats: []

    signal opened(name: string)
    signal closed(name: string)

    signal sig(name: string, sig: string)

    signal sigClose(name: string)

    function sendSig(name = "", sig: string) {
        root.sig(name, sig);
    }

    function isOpen(name: string): bool {
        return active_floats.includes(name);
    }

    function open(name: string) {
        active_floats = [...active_floats, name];
        opened(open);
    }

    function close(name = "") {
        if (name == "") {
            active_floats = [];
        }
        active_floats = active_floats.filter(item => item != name);
        closed(name);
    }

    Connections {
        target: SettingsInfo
        function onDebugSig() {
            root.open("pacman");
        }
    }
}
