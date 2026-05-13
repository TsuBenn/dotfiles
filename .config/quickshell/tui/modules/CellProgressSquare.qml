pragma ComponentBehavior: Bound

import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property int w: 10
    property int h: 1

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(h)

    property color color: Colors.bgOverlay

    property color fg: Colors.fgBase 
    property real percent: SystemInfo.cpuusage

    property int percentSmoother: 200

    property int type: 1

    property real raw_percent: percent

    property int min: 0
    property int max: 100

    property bool vertical: false
    property bool adjustOnHold: false
    property bool adjustOnPress: true
    property bool drag: true
    property bool wheel: true
    property bool safeRelease: true
    property bool interactive: false

    property int cellInterval: 1

    property bool hovered: false

    property int wheelInterval: 5
    property int adjustInterval: 100
    property int syncDelay: 5000 // recommend 5s

    Behavior on percent {NumberAnimation {duration: root.percentSmoother; easing.type: Easing.OutCubic}}

    signal entered()
    signal exited()
    signal pressed(button: string)
    signal released(button: string)
    signal adjusted(percent: int)
    signal synced()

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

    Loader {

        active: root.type == 0 && (root.visible || !SettingsInfo.optimizeMemory)

        sourceComponent: Rectangle {

            visible: root.type == 0

            anchors.bottom: parent.bottom
            implicitWidth: root.vertical ? Cell.w(root.w) : Math.min(Cell.w(Math.round(root.w*(root.raw_percent/100)*8)/8),Cell.w(root.w))
            implicitHeight: root.vertical ? Math.min(Cell.h(Math.round(root.h*(root.raw_percent/100)*8)/8),Cell.h(root.h)) : Cell.h(root.h) 
            color: root.fg

        }

    }


    Loader {

        active: root.type == 1 && (root.visible || !SettingsInfo.optimizeMemory)

        sourceComponent: Item {

            RowLayout {

                visible: root.type == 1

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

                visible: root.type == 1

                spacing: 0

                Repeater {

                    model: root.sections(root.w, root.raw_percent)

                    delegate: CellText {

                        required property real modelData

                        text: "■"

                        color: Colors.transparent(root.fg, Math.round(modelData*root.cellInterval)/root.cellInterval)

                    }

                }

            }


        }

    }

    Loader {

        active: root.type == 2 && (root.visible || !SettingsInfo.optimizeMemory)

        sourceComponent: Item {

            RowLayout {

                visible: root.type == 2

                spacing: 0

                Repeater {

                    model: root.w

                    delegate: CellText {

                        required property real modelData

                        text: "━"

                        color: root.color

                    }

                }

            }

            RowLayout {

                visible: root.type == 2

                spacing: 0

                Repeater {

                    model: root.sections(root.w, root.raw_percent)

                    delegate: CellText {

                        required property real modelData

                        text: "━"

                        color: Colors.transparent(root.fg, Math.round(modelData*root.cellInterval)/root.cellInterval)

                    }

                }

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
            if (!root.adjustOnPress) sync.restart()
            if (!root.vertical) {
                root.raw_percent = mouseX/Cell.w(root.w)*100
            } else {
                root.raw_percent = 100 - mouseY/Cell.h(root.h)*100
            }
        }
        onMoved: (x, y) => {
            if (!root.drag) return
            if (buttonDown != "L") return
            sync.restart()
            if (!root.vertical) {
                root.raw_percent = x/Cell.w(root.w)*100
            } else {
                root.raw_percent = 100 - y/Cell.h(root.h)*100
            }
        }
        onHeld: {
            if (!root.drag && !root.adjustOnHold) return
            if (buttonDown != "L") return
            root.adjusted(root.clamp(root.raw_percent))
            sync.restart()
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
            root.released(button)
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
            root.synced()
        }
    }

}
