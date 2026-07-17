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
        FloatsManager.close(name);
    }

    function close() {
        FloatsManager.close(name);
    }

    property string name

    property int w: 20
    property int h: 10

    implicitWidth: Cell.w(w + 1)
    implicitHeight: Cell.h(h + 1)

    Timer {
        id: adjustTransform
        interval: 100
        onTriggered: {
            root.preferredW = Cell.wCount(root.width, "floor") - 1;
            root.preferredH = Cell.hCount(root.height, "floor") - 1;
            // root.implicitWidth = Cell.wCount(root.width, "floor");
            // root.implicitHeight = Cell.hCount(root.height, "floor");
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

    property int preferredW: w
    property int preferredH: h

    maximumSize: noMax ? undefined : (Qt.size(maxW > 0 ? Cell.w(maxW) : Cell.w(w + 1), maxH > 0 ? Cell.h(maxH) : Cell.h(h + 1)))
    minimumSize: noMin ? undefined : (Qt.size(minW > 0 ? Cell.w(minW) : Cell.w(w + 1), minH > 0 ? Cell.h(minH) : Cell.h(h + 1)))

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

    Cells {
        id: cell
        visible: root.visible

        w: root.preferredW
        h: root.preferredH

        x: Cell.w(0.5)
        y: Cell.h(0.5)

        color: root.color

        Keys.onPressed: event => {
            if (root.shortcuts.length > 0)
                ShortcutInfo.handleShortcuts(event, root.shortcuts);
        }
    }

    Cells {
        id: size

        SequentialAnimation {
            id: show_size
            NumberAnimation {
                target: size
                property: "opacity"
                duration: 100
                to: 1
                easing.type: Easing.OutCubic
            }
            PauseAnimation {
                duration: 400
            }
            NumberAnimation {
                target: size
                property: "opacity"
                duration: 500
                to: 0
                easing.type: Easing.OutCubic
            }
        }

        w: Cell.wCount(root.width)
        h: Cell.hCount(root.height)

        color: Colors.transparent(Colors.bgBase, 0.5)

        opacity: 0

        CellText {
            x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
            y: Cell.centerHCell(implicitHeight, parent.implicitHeight)
            text: ` ${parent.w} x ${parent.h} `
            bg: Colors.bgSurface
        }
    }
}
