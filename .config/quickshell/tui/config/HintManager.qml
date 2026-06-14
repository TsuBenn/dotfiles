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
    property string header: ""
    property Component hint

    signal opened()
    signal closed()

    function show(mx, my, mheader = "") {
        x = Cell.wCount(mx - HyprInfo.focusedMonitor.x, "floor")
        y = Cell.hCount(my - HyprInfo.focusedMonitor.y,"floor")
        header = mheader
        visible = true
        root.opened()
    }

    function hide() {
        visible = false
        header = ""
        hint = null
        root.closed()
    }

}
