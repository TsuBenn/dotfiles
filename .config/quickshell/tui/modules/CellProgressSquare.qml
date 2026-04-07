pragma ComponentBehavior: Bound

import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property int w: 10
    property int h: 10

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(h)

    property color color: Colors.bgOverlay

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

    property int cellInterval: 1

    property bool hovered: false

    property int wheelInterval: 5
    property int adjustInterval: 100
    property int syncDelay: 100

    Behavior on percent {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

    signal entered()
    signal exited()
    signal pressed(button: string)
    signal released(button: string)
    signal adjusted(percent: int)

    function sections(n, percent) {
        const filled = percent/100 * n
        let result = []
        for (let i = 0; i < n; i++) {
            if (i < Math.floor(filled)) {
                result.push(1)
            } else if (i === Math.floor(filled)) {
                result.push(filled - Math.floor(filled))
            } else {
                result.push(0)
            }
        }
        return result
    }

    RowLayout {

        spacing: 0

        Repeater {

            model: root.w

            delegate: CellText {

                required property real modelData

                text: "■"

                color: root.color

            }

        }

    }

    RowLayout {

        spacing: 0

        Repeater {

            model: root.sections(root.w, root.percent)

            delegate: CellText {

                required property real modelData

                text: "■"

                color: Colors.transparent(root.fg, Math.round(modelData*root.cellInterval)/root.cellInterval)

            }

        }

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
            root.adjusted(root.clamp(root.raw_percent))
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
            root.adjusted(root.clamp(root.raw_percent))
            sync.restart()
        }
        onWheel: (delta) => {
            if (!root.wheel) return
            root.raw_percent = Math.round(root.raw_percent/root.wheelInterval)*root.wheelInterval + root.wheelInterval*delta
            root.adjusted(root.clamp(root.raw_percent))
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
