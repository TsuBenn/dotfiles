pragma ComponentBehavior: Bound

import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

Item {
    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

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

    property bool flipped: false

    property var sections_data: root.sections(root.w, root.percent)

    property int cellInterval: 1

    property bool hovered: false

    property real wheelInterval: 5
    property int adjustInterval: 100
    property int syncDelay: 5000 // recommend 5s

    property bool purify: SettingsInfo.purify

    transform: Scale {
        origin.x: !root.vertical && root.flipped ? Cell.w(root.w) / 2 : 0
        origin.y: root.vertical && root.flipped ? Cell.h(root.h) / 2 : 0
        xScale: !root.vertical && root.flipped ? -1 : 1
        yScale: root.vertical && root.flipped ? -1 : 1
    }

    Behavior on percent {
        NumberAnimation {
            duration: root.percentSmoother
            easing.type: Easing.OutCubic
        }
    }

    signal entered
    signal exited
    signal pressed(button: string)
    signal released(button: string)
    signal adjusted(percent: real)
    signal synced

    function sync() {
        root.raw_percent = Qt.binding(() => root.percent);
        root.synced();
    }

    function sections(n, percent) {
        const filled = percent / 100 * n;
        let result = [];
        for (let i = 0; i < n; i++) {
            if (i < Math.floor(filled)) {
                result.push(1);
            } else if (i === Math.floor(filled)) {
                result.push(filled - Math.floor(filled));
            } else {
                result.push(0);
            }
        }
        return result;
    }

    Loader {

        active: root.type == 0 && (root.visible || !root.optimizeMemory) && !root.purify

        sourceComponent: Item {

            implicitWidth: Cell.w(root.w)
            implicitHeight: Cell.h(root.h)

            Rectangle {

                visible: root.type == 0

                implicitWidth: Cell.w(root.w)
                implicitHeight: Cell.h(root.h)

                color: root.color
            }

            Rectangle {

                visible: root.type == 0

                anchors.bottom: parent.bottom
                implicitWidth: root.vertical ? Cell.w(root.w) : Math.min(Cell.w(Math.round(root.w * (root.raw_percent / 100) * 8) / 8), Cell.w(root.w))
                implicitHeight: root.vertical ? Math.min(Cell.h(Math.round(root.h * (root.raw_percent / 100) * 8) / 8), Cell.h(root.h)) : Cell.h(root.h)
                color: root.fg
            }
        }
    }

    Loader {

        active: root.type == 1 && (root.visible || !root.optimizeMemory) && !root.purify

        sourceComponent: Cells {
            h: 1
            w: root.w

            color: "transparent"

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Cell.w(root.w)
                implicitHeight: Cell.w(1)
                color: root.color
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Cell.w(Cell.wCount(root.implicitWidth * (root.percent / 100), "floor"))
                implicitHeight: Cell.w(1)
                color: root.fg
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Cell.w(Cell.wCount(root.implicitWidth * (root.percent / 100), "ceil"))
                implicitHeight: Cell.w(1)
                color: Colors.transparent(root.fg, ((root.percent / 100 * root.w) - Math.floor((root.percent / 100) * root.w)))
            }
        }
    }

    Loader {

        active: root.type == 2 && (root.visible || !root.optimizeMemory) && !root.purify

        sourceComponent: Cells {
            h: 1
            w: root.w

            color: "transparent"

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Cell.w(root.w)
                implicitHeight: 2 * Cell.border_width
                color: root.color
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Cell.w(Cell.wCount(root.implicitWidth * (root.percent / 100), "floor"))
                implicitHeight: 2 * Cell.border_width
                color: root.fg
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: Cell.w(Cell.wCount(root.implicitWidth * (root.percent / 100), "ceil"))
                implicitHeight: 2 * Cell.border_width
                color: Colors.transparent(root.fg, ((root.percent / 100 * root.w) - Math.floor((root.percent / 100) * root.w)))
            }
        }
    }

    Loader {

        active: root.purify && !root.vertical

        sourceComponent: Cells {
            h: 1
            w: root.w

            color: "transparent"

            CellText {
                text: "#".repeat(root.w)
                color: root.color
            }
            CellText {
                text: "#".repeat(Cell.wCount(root.implicitWidth * (root.percent / 100), "floor"))
                color: root.fg
                font: Cell.fontB
            }
            CellText {
                text: "#".repeat(Cell.wCount(root.implicitWidth * (root.percent / 100), "ceil"))
                color: Colors.transparent(root.fg, ((root.percent / 100 * root.w) - Math.floor((root.percent / 100) * root.w)))
                font: Cell.fontB
            }
        }
    }

    Loader {

        active: root.purify && root.vertical

        sourceComponent: Cells {
            h: root.h
            w: 1

            color: "transparent"

            CellText {
                text: "#\n".repeat(root.w)
                color: root.color
            }
            CellText {
                text: "#\n".repeat(Cell.wCount(root.implicitWidth * (root.percent / 100), "floor"))
                color: root.fg
                font: Cell.fontB
            }
            CellText {
                text: "#\n".repeat(Cell.wCount(root.implicitWidth * (root.percent / 100), "ceil"))
                color: Colors.transparent(root.fg, ((root.percent / 100 * root.w) - Math.floor((root.percent / 100) * root.w)))
                font: Cell.fontB
            }
        }
    }

    function clamp(n: real): real {
        return Math.max(Math.min(n, max), min);
    }

    MouseControl {
        id: mouse

        visible: root.interactive

        anchors.fill: parent

        holdEnabled: root.adjustOnHold
        holdInterval: root.adjustInterval

        onEntered: {
            root.entered();
            root.hovered = true;
        }
        onExited: {
            root.exited();
            root.hovered = false;
        }
        onPressed: (button, event) => {
            if (!root.drag) {
                root.pressed(buttonDown);
                return;
            }
            if (buttonDown != "L")
                return;
            if (!root.adjustOnPress)
                sync.restart();
            if (!root.vertical) {
                root.raw_percent = event.x / Cell.w(root.w) * 100;
            } else {
                root.raw_percent = 100 - event.y / Cell.h(root.h) * 100;
            }
            root.raw_percent = root.clamp(root.raw_percent);
            root.adjusted(root.raw_percent);
        }
        onMoved: (x, y, event) => {
            if (!root.drag)
                return;
            if (buttonDown != "L")
                return;
            if (!root.vertical) {
                root.raw_percent = event.x / Cell.w(root.w) * 100;
            } else {
                root.raw_percent = 100 - event.y / Cell.h(root.h) * 100;
            }
            root.raw_percent = root.clamp(root.raw_percent);
            root.adjusted(root.raw_percent);
            sync.restart();
        }
        onHeld: {
            if (!root.drag && !root.adjustOnHold)
                return;
            if (buttonDown != "L")
                return;
            root.raw_percent = root.clamp(root.raw_percent);
            root.adjusted(root.raw_percent);
            sync.restart();
        }
        onReleased: button => {
            if (!root.drag) {
                if (!root.safeRelease) {
                    root.released(button);
                } else if (hovered) {
                    root.released(button);
                }
                return;
            }
            root.released(button);
            root.raw_percent = root.clamp(root.raw_percent);
            root.adjusted(root.raw_percent);
            sync.restart();
        }
        onWheel: delta => {
            if (!root.wheel)
                return;
            root.raw_percent = Math.round(root.raw_percent / root.wheelInterval) * root.wheelInterval + root.wheelInterval * delta;
            root.raw_percent = root.clamp(root.raw_percent);
            root.adjusted(root.raw_percent);
            sync.restart();
        }
    }

    Timer {
        id: sync
        interval: root.syncDelay
        onTriggered: {
            root.sync();
        }
    }
}
