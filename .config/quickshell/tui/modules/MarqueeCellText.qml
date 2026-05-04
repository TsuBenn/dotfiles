import qs.config
import qs.modules

import Quickshell.Widgets
import QtQuick

Cells {

    id: root

    property int cellw: 1
    property string text: "Sample of super long text"
    property font font: Cell.font
    property color fg: Colors.fgBase
    property int interval: 300
    property int pause: 2000

    property int offset: 0
    property int excess: 0
    property bool paused: true

    readonly property string displayed: {
        const padded = text + "    "
        const doubled = padded + padded
        return doubled.slice(offset, offset + cellw)
    }

    color: "transparent"

    w: cellw
    h: 1

    CellText {
        visible: false
        id: buffer
        text: root.text
        font: parent.font
        color: parent.fg
    }

    CellText {
        text: buffer.w > root.cellw ? root.displayed : root.text
        preferedW: root.cellw
        font: root.font
        color: root.fg
    }

    onTextChanged: {
        offset = 0
        pauseTimer.restart()
    }

    Timer {
        interval: parent.interval
        running: buffer.w > root.cellw && !parent.paused && root.visible
        repeat: true
        onTriggered: {
            parent.offset = (parent.offset + 1) % (parent.text.length + 4)
            if (parent.offset === 0) {
                parent.paused = true
                pauseTimer.restart()
            }
        }
    }
    Timer {
        id: pauseTimer
        interval: root.pause
        repeat: false
        onTriggered: parent.paused = false
    }
}
