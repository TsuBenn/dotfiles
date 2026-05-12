pragma Singleton

import Quickshell
import QtQuick

Singleton {

    id: root

    property var active_popups: []

    signal opened(name: string)
    signal closed(name: string)

    signal signalSent(id: string, sig: string)

    function sendSignal(id = "", sig = "") {
        root.signalSent(id, sig)
    }

    function open(name, isolate) {
        // Handle optional argument explicitly if engine is older
        if (isolate === undefined) isolate = true;

        if (isolate) {
            // If isolating, we need to notify that everything else closed
            let old_popups = active_popups;
            close()
            active_popups = [name];
            old_popups.forEach(p => { if(p !== name) root.closed(p) });
        } else if (!isOpen(name)) {
            active_popups = [...active_popups, name];
        }

        root.opened(name);
    }

    function toggle(name: string, isolate = true) {
        isOpen(name) ? close(name) : open(name,isolate)
    }

    function close(name = "") {
        if (name == "") active_popups = [] 
        else active_popups = active_popups.filter(p => p != name)
        root.closed(name)
    }

    function isOpen(name: string): bool {
        return active_popups.includes(name)
    }

}
