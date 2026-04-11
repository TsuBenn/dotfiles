pragma Singleton 

import qs.config

import Quickshell
import QtQuick

Singleton {

    id: root

    property bool visible: false
    property int x: 0
    property int y: 0
    property int w: 20
    property string header: ""
    property var items: []

    signal opened()
    signal closed()

    function show(itemList, mx, my, mw = 20, mheader = "") {
        items = itemList
        w = mw
        x = Cell.wCount(mx)
        y = Cell.hCount(my,"floor")
        header = mheader
        visible = true
        root.opened()
    }

    function hide() {
        visible = false
        items = []
        header = ""
        root.closed()
    }

}
