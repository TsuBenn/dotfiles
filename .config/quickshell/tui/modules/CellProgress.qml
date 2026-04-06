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

    property int raw_percent: percent

    property int min: 0
    property int max: 100

    property bool vertical: true
    property bool adjustOnHold: false
    property bool drag: true
    property bool wheel: true

    property int adjustInterval: 100
    property int syncDelay: 100

    Behavior on percent {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

    signal adjusted(percent: int)

    Rectangle {
        anchors.bottom: parent.bottom
        implicitWidth: root.vertical ? Cell.w(root.w) : Cell.w(Math.round(root.w*(root.raw_percent/100)*8)/8)
        implicitHeight: root.vertical ? Cell.h(Math.round(root.h*(root.raw_percent/100)*8)/8) : Cell.h(root.h) 
        color: root.fg
    }

    function clamp(n) {
        return Math.max(Math.min(n,max),min)
    }

    MouseControl {

        id: mouse

        anchors.fill: parent

        holdEnabled: root.adjustOnHold
        holdInterval: root.adjustInterval

        onPressed: {
            if (!drag) return
            if (buttonDown != "L") return
            root.raw_percent = mouseX/Cell.w(root.w)*100
        }
        onMoved: (x, y) => {
            if (!drag) return
            if (buttonDown != "L") return
            if (!root.vertical) {
                root.raw_percent = x/Cell.w(root.w)*100
            }
        }
        onHeld: {
            if (!drag) return
            if (buttonDown != "L") return
            root.adjusted(clamp(root.raw_percent))
        }
        onReleased: {
            if (!drag) return
            root.adjusted(clamp(root.raw_percent))
            sync.restart()
        }
        onWheel: (delta) => {
            root.raw_percent = Math.round(raw_percent/10)*10 + 10*delta
            root.adjusted(clamp(root.raw_percent))
            sync.restart()
        }

    }

    Timer {
        id: sync
        interval: root.syncDelay
        onTriggered: {
            root.raw_percent = Qt.binding(()=>root.percent)
        }
    }

}
