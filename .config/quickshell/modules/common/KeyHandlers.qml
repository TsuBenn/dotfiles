pragma Singleton 

import Quickshell
import QtQuick

Singleton {

    signal pressed(key: int, modifiers: int)
    signal released(key: int, modifiers: int)

    function signalPressed(key:int, modifiers: int) {
        pressed(key, modifiers)
    }

    function signalReleased(key:int, modifiers: int) {
        released(key, modifiers)
    }

}

