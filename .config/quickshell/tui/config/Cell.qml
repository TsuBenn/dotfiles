pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property real pointSize: 11

    property int border_width: 2

    readonly property font font: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: root.pointSize
    })

    readonly property font fontE: Qt.font({
        family: "Apple Color Emoji",
        pointSize: root.pointSize
    })

    readonly property font fontB: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: root.pointSize,
        weight: Font.Bold
    })
    readonly property font fontBB: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: root.pointSize,
        weight: Font.Black
    })

    readonly property int cellWidth: metrics.averageCharacterWidth
    readonly property int cellHeight: cellWidth * 2
    readonly property int realCellHeight: metrics.height
    readonly property real cellRatio: cellWidth / cellHeight

    function centerWCell(item: double, container: double): double {
        return Cell.toW(container / 2 - item / 2);
    }

    function alignRightWCell(item: double, container: double): double {
        return Cell.toW(container - item);
    }

    function centerHCell(item: double, container: double): double {
        return Cell.toH(container / 2 - item / 2);
    }

    function alignRightHCell(item: double, container: double): double {
        return Cell.toH(container - item);
    }

    function w(n: real): real {
        return Math.round(cellWidth) * n;
    }

    function h(n: real): real {
        return Math.round(cellHeight) * n;
    }

    function toW(n: int): int {
        return w(Math.floor(n / cellWidth));
    }
    function toH(n: int): int {
        return h(Math.floor(n / cellHeight));
    }

    function wCount(n: int, mode = ""): int {
        if (mode == "ceil") {
            return Math.ceil(n / cellWidth);
        } else if (mode == "floor") {
            return Math.floor(n / cellWidth);
        }
        return Math.round(n / cellWidth);
    }
    function hCount(n: int, mode = ""): int {
        if (mode == "ceil") {
            return Math.ceil(n / cellHeight);
        } else if (mode == "floor") {
            return Math.floor(n / cellHeight);
        }
        return Math.round(n / cellHeight);
    }

    FontMetrics {
        id: metrics
        font: root.font
    }
}
