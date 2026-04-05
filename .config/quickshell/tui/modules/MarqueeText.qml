import qs.config
import qs.modules

import QtQuick

Cells {
    property int cellw: 10
    property string text: "Sample of super long text"
    property font font: Cell.font
    property color fg: Colors.fgBase
    property int interval: 300

    property int offset: 0
    property bool paused: false

    readonly property string displayed: {
        const padded = text.trim() + "    "
        const doubled = padded + padded
        return doubled.slice(offset, offset + cellw)
    }

    color: "transparent"

    w: cellw
    h: 1

    CellText {
        text: parent.text.length > parent.cellw ? parent.displayed : parent.text
        font: parent.font
        color: parent.fg
    }

    onTextChanged: {
        offset = 0
        pauseTimer.restart()
    }

    Timer {
        interval: parent.interval
        running: parent.text.length > parent.cellw && !parent.paused
        repeat: true
        onTriggered: {
            parent.offset = (parent.offset + 1) % (parent.text.length + 3)
            if (parent.offset === 0) {
                parent.paused = true
                pauseTimer.restart()
            }
        }
    }
    Timer {
        id: pauseTimer
        interval: 1500  // pause duration in ms
        repeat: false
        onTriggered: parent.paused = false
    }
}
