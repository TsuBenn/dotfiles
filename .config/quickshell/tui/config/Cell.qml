pragma Singleton

import Quickshell
import QtQuick

Singleton {

    id: root

    property real pointSize: 11

    readonly property font font: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: root.pointSize,
        contextFontMerging: true,
    })
    readonly property font fontB: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: root.pointSize,
        weight: Font.Bold,
        contextFontMerging: true
    })
    readonly property font fontBB: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: root.pointSize,
        weight: Font.Black,
        contextFontMerging: true
    })

    readonly property real cellWidth: metrics.averageCharacterWidth
    readonly property real cellHeight: metrics.height

    function w(n: real): real {
        return Math.round(cellWidth * n)
    }

    function h(n: real): real {
        return Math.round(cellHeight * n)
    }

    function toW(n: real): real {
        return w(Math.round(n/cellWidth))
    }
    function toH(n: real): real {
        return h(Math.round(n/cellWidth))
    }

    FontMetrics {
        id: metrics
        font: root.font
    }
}
