pragma Singleton 

import Quickshell
import QtQuick

Singleton {

    signal pressed(key: int)
    signal released(key: int)

    function signalPressed(key:int) {
        pressed(key)
    }

    function signalReleased(key:int) {
        released(key)
    }

}

