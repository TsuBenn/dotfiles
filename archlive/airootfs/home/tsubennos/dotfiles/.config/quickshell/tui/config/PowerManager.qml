pragma Singleton

import Quickshell
import QtQuick

Singleton {

    signal called(mode: string, countdown: int)

    function call(mode: string, countdown = 3) {

        if (!mode) return

        called(mode, countdown)

    }

}
