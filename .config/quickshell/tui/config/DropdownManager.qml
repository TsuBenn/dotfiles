pragma Singleton 

import qs.config

import Quickshell
import QtQuick

Singleton {

    id: root

    property bool visible: false
    property int x: 0
    property int y: 0
    property int padding: 0
    property int selected: 0
    property color color
    property color fg
    property color active
    property color active_invert
    property int w: 0
    property int h: 0
    property var items: []

    signal opened()
    signal closed()

    function show(itemList, mx, my, mw, mh, selected = 0, padding = 1, color = Colors.bgOverlay, fg = Colors.fgBase, active = Colors.accentStrong, active_invert = Colors.onAccent) {
        items = itemList
        w = mw
        h = mh
        x = Cell.wCount(mx)
        y = Cell.hCount(my,"floor")
        root.selected = selected
        root.padding = padding
        root.color = color
        root.fg = fg
        root.active = active
        root.active_invert = active_invert
        visible = true
        root.opened()
    }

    function hide() {
        visible = false
        items = []
        root.closed()
    }

}
