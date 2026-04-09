pragma Singleton

import Quickshell
import QtQuick

Singleton {

    id: root

    property real pointSize: 11

    readonly property font font: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: root.pointSize,
    })
    readonly property font fontB: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: root.pointSize,
        weight: Font.Bold,
    })
    readonly property font fontBB: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: root.pointSize,
        weight: Font.Black,
    })

    readonly property real cellWidth: metrics.averageCharacterWidth
    readonly property real cellHeight: metrics.height

    function centerWCell(item: double, container: double) : double {
        return Cell.toW(container/2 - item/2)
    }

    function alignRightWCell(item: double, container: double) : double {
        return Cell.toW(container - item)
    }

    function centerHCell(item: double, container: double) : double {
        return Cell.toH(container/2 - item/2)
    }

    function alignRightHCell(item: double, container: double) : double {
        return Cell.toH(container - item)
    }

    function w(n: real): real {
        return Math.round(cellWidth)*n
    }

    function h(n: real): real {
        return Math.round(cellHeight)*n
    }

    function toW(n: real): real {
        return w(Math.round(n/cellWidth))
    }
    function toH(n: real): real {
        return h(Math.round(n/cellHeight))
    }

    function wCount(n: real): real {
        return Math.round(n/cellWidth)
    }
    function hCount(n: real): real {
        return Math.round(n/cellHeight)
    }

    FontMetrics {
        id: metrics
        font: root.font
    }
}
