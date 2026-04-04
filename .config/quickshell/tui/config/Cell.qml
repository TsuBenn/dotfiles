pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property font font: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: 11,
        contextFontMerging: true,
    })
    readonly property font fontB: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: 11,
        weight: Font.Bold,
        contextFontMerging: true
    })
    readonly property font fontBB: Qt.font({
        family: "JetBrainsMono Nerd Font",
        pointSize: 11,
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

    FontMetrics {
        id: metrics
        font: root.font
    }
}
