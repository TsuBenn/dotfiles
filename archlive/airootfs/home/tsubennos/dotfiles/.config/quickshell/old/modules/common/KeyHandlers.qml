pragma Singleton 

import Quickshell
import QtQuick

Singleton {

    signal pressed(key: int, modifiers: int, auto: bool)
    signal released(key: int, modifiers: int, auto: bool)

    function signalPressed(key:int, modifiers: int, auto: bool) {
        pressed(key, modifiers, auto)
    }

    function signalReleased(key:int, modifiers: int, auto: bool) {
        released(key, modifiers, auto)
    }

}

