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
    property bool safeRelease: true
    property bool interactive: false

    property bool hovered: false

    property int adjustInterval: 100
    property int syncDelay: 100

    Behavior on percent {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

    signal entered()
    signal exited()
    signal pressed(button: string)
    signal released(button: string)
    signal adjusted(percent: int)

    Rectangle {
        anchors.bottom: parent.bottom
        implicitWidth: root.vertical ? Cell.w(root.w) : Math.min(Cell.w(Math.round(root.w*(root.raw_percent/100)*8)/8),Cell.w(root.w))
        implicitHeight: root.vertical ? Math.min(Cell.h(Math.round(root.h*(root.raw_percent/100)*8)/8),Cell.h(root.h)) : Cell.h(root.h) 
        color: root.fg
    }

    function clamp(n) {
        return Math.max(Math.min(n,max),min)
    }

    MouseControl {

        id: mouse

        visible: root.interactive

        anchors.fill: parent

        holdEnabled: root.adjustOnHold
        holdInterval: root.adjustInterval

        onEntered: {
            root.entered()
            root.hovered = true
        }
        onExited: {
            root.exited()
            root.hovered = false
        }
        onPressed: {
            if (!root.drag) {
                root.pressed(buttonDown)
                return
            }
            if (buttonDown != "L") return
            root.raw_percent = mouseX/Cell.w(root.w)*100
        }
        onMoved: (x, y) => {
            if (!root.drag) return
            if (buttonDown != "L") return
            if (!root.vertical) {
                root.raw_percent = x/Cell.w(root.w)*100
            }
        }
        onHeld: {
            if (!root.drag) return
            if (buttonDown != "L") return
            root.adjusted(clamp(root.raw_percent))
        }
        onReleased: (button) => {
            if (!root.drag) {
                if (!root.safeRelease) {
                    root.released(button) 
                } else if (hovered) {
                    root.released(button)
                }
                return
            }
            root.adjusted(clamp(root.raw_percent))
            sync.restart()
        }
        onWheel: (delta) => {
            if (!root.wheel) return
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
