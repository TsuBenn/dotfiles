pragma Singleton 

import qs.config
import qs.services

import Quickshell
import QtQuick

Singleton {

    id: root

    property bool visible: false
    property int x: 0
    property int y: 0
    property int w: 20
    property int margins: 0
    property int timer: 0
    property string header: ""
    property Component hint

    signal opened()
    signal closed()

    function show(mx, my, mg = 2, mheader = "", timer = 0) {
        x = Cell.wCount(mx - HyprInfo.focusedMonitor.x, "floor")
        y = Cell.hCount(my - HyprInfo.focusedMonitor.y, "floor")
        root.timer = timer
        margins = mg
        header = mheader
        visible = true
        root.opened()
    }

    Timer {

        running: root.visible && root.timer > 0
        interval: root.timer
        onTriggered: {
            root.hide()
        }

    }

    function hide() {
        visible = false
        header = ""
        hint = null
        root.closed()
    }

}
