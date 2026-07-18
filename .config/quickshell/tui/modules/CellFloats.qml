pragma ComponentBehavior: Bound

import qs.config
import qs.services
import qs.modules

import Quickshell
import QtQuick

FloatingWindow {
    id: root

    visible: FloatsManager.isOpen(name)

    onClosed: {
        TextFieldManager.unFocusAll();
        root.close();
    }

    Connections {
        target: FloatsManager
        function onSigClose(name) {
            if (root.name == name) {
                root.close();
            }
        }
    }

    function close() {
        onSigClose();
        forceClose();
    }

    function onSigClose() {
    }

    function forceClose() {
        FloatsManager.close(name);
    }

    function open() {
        FloatsManager.open(name);
    }

    property bool active: false

    property string name

    property int w: 20
    property int h: 10

    implicitWidth: Cell.w(w + 1)
    implicitHeight: Cell.h(h + 1)

    Timer {
        id: adjustTransform
        interval: 100
        onTriggered: {
            root.w = Cell.wCount(root.width, "floor") - 1;
            root.h = Cell.hCount(root.height, "floor") - 1;
        }
    }

    property bool showSize: true

    onWindowTransformChanged: {
        if (showSize)
            show_size.restart();
        adjustTransform.restart();
    }

    property bool noMax: false
    property bool noMin: false

    property size _maximum: noMax ? Qt.size(16777215, 16777215) : (Qt.size(maxW > 0 ? Cell.w(maxW) : Cell.w(w + 1), maxH > 0 ? Cell.h(maxH) : Cell.h(h + 1)))
    property size _minimum: noMin ? Qt.size(0, 0) : (Qt.size(minW > 0 ? Cell.w(minW) : Cell.w(w + 1), minH > 0 ? Cell.h(minH) : Cell.h(h + 1)))

    maximumSize: _maximum
    minimumSize: _minimum

    property int maxW: 0
    property int maxH: 0

    property int minW: 0
    property int minH: 0

    property var shortcuts: []

    // ShortcutHandler {
    //     shortcuts: root.shortcuts
    // }

    color: Colors.bgSurface

    default property alias content: cell.data

    property bool _faultySize: !((root.minW == 0 || root.w + 1 >= root.minW) && (root.maxH == 0 || root.w + 1 <= root.maxW) && (root.minH == 0 || root.h + 1 >= root.minH) && (root.maxH == 0 || root.h + 1 <= root.maxH))

    Cells {
        id: cell
        visible: root.visible && !root._faultySize

        w: root.w
        h: root.h

        x: Cell.w(0.5)
        y: Cell.h(0.5)

        color: root.color

        focus: !TextFieldManager.active && root.visible && root.active

        Keys.onPressed: event => {
            if (root.shortcuts.length > 0) {
                ShortcutInfo.handleShortcuts(event, root.shortcuts);
            }
        }
    }

    MouseControl {
        anchors.fill: parent

        propagateComposedEvents: true

        hoverEnabled: true

        onEntered: {
            root.active = true;
        }
        onExited: {
            root.active = false;
        }

        onPressed: (button, event) => {
            TextFieldManager.unFocusAll();
            event.accepted = false;
        }

        onReleased: (button, event) => {
            TextFieldManager.unFocusAll();
            event.accepted = false;
        }

        onWheel: (button, event) => {
            event.accepted = false;
        }
    }

    Cells {
        id: size

        SequentialAnimation {
            id: show_size
            NumberAnimation {
                target: size
                property: "prefered_opacity"
                duration: 100
                to: 1
                easing.type: Easing.OutCubic
            }
            PauseAnimation {
                duration: 400
            }
            NumberAnimation {
                target: size
                property: "prefered_opacity"
                duration: 500
                to: 0
                easing.type: Easing.OutCubic
            }
        }

        w: Cell.wCount(root.width)
        h: Cell.hCount(root.height)

        color: Colors.transparent(Colors.bgBase, 0.5)

        property int prefered_opacity: 0

        opacity: root._faultySize ? 1 : prefered_opacity

        CellText {
            x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
            y: Cell.centerHCell(implicitHeight, parent.implicitHeight)
            text: root._faultySize ? ` Unavailable size ` : ` ${parent.w} x ${parent.h} `
            bg: Colors.bgSurface
        }
    }
}
