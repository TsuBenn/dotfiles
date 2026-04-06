pragma ComponentBehavior: Bound

import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

Cells {

    id: root

    w: 1
    h: 1

    color: Colors.bgOverlay

    property color fg: Colors.fgBase 
    property int percent: SystemInfo.cpuusage

    Behavior on percent {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

    property bool vertical: true

    Rectangle {
        anchors.bottom: parent.bottom
        implicitWidth: root.vertical ? Cell.w(root.w) : Cell.w(Math.round(root.w*(root.percent/100)*8)/8)
        implicitHeight: root.vertical ? Cell.h(Math.round(root.h*(root.percent/100)*8)/8) : Cell.h(root.h) 
        color: root.fg
    }

}
