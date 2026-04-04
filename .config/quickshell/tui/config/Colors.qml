pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string current: "hutao"

    onCurrentChanged: apply()

    // Background
    property color bgBase
    property color bgSurface
    property color bgOverlay

    // Foreground
    property color fgBase
    property color fgDim
    property color fgSubtle

    // Accent
    property color accentStrong
    property color accentDim
    property color secondary
    property color info

    // Semantic
    property color success
    property color warning
    property color danger

    // Border
    property color borderActive
    property color borderInactive

    // Helpers
    function transparent(c, factor) {
        return Qt.rgba(c.r, c.g, c.b, factor)
    }

    function blend(c1: color, c2: color, t: real): color {
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * t,
            c1.g + (c2.g - c1.g) * t,
            c1.b + (c2.b - c1.b) * t,
            c1.a + (c2.a - c1.a) * t
        )
    }

    function apply() {
        const theme = colors[current] ?? colors["hutao"]

        bgBase         = theme.bgBase
        bgSurface      = theme.bgSurface
        bgOverlay      = theme.bgOverlay

        fgBase         = theme.fgBase
        fgDim          = theme.fgDim
        fgSubtle       = theme.fgSubtle

        accentStrong   = theme.accentStrong
        accentDim      = theme.accentDim
        secondary      = theme.secondary
        info           = theme.info

        success        = theme.success
        warning        = theme.warning
        danger         = theme.danger

        borderActive   = theme.borderActive
        borderInactive = theme.borderInactive
    }

    Component.onCompleted: apply()

    property var colors: ({
        hutao: {
            bgBase:         "#151214",
            bgSurface:      "#1D191C",
            bgOverlay:      "#2A2428",

            fgBase:         "#EDE6E8",
            fgDim:          "#A89BA0",
            fgSubtle:       "#7A6F74",

            accentStrong:   "#a32435",
            accentDim:      "#6B1825",
            secondary:      "#f59b75",
            info:           "#8ba3b0",

            success:        "#98BB6C",
            warning:        "#eea022",
            danger:         "#ec2727",

            borderActive:   "#a32435",
            borderInactive: "#2A2428",
        }
    })
}
