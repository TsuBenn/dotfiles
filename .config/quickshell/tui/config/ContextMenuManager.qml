pragma Singleton 

import Quickshell
import QtQuick

Singleton {

    property bool visible: false
    property int x: 0
    property int y: 0
    property int w: 20
    property string header: ""
    property var items: []

    function show(itemList, mx, my, mw = 20, mheader = "") {
        items = itemList
        w = mw
        x = mx
        y = my
        header = mheader
        visible = true
    }

    function hide() {
        visible = false
        items = []
        header = ""
    }

}
