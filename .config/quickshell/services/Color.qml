pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string current: "hutao"

    property color accentStrong
    property color accentSoft
    property color bgBase
    property color bgSurface
    property color bgMuted
    property color textPrimary
    property color textSecondary
    property color textDisabled

    property color info
    property color error
    property color warn
    property color success

    function saturate(c, factor) {
        return Qt.hsla(
            c.hslHue,
            Math.min(c.hslSaturation * factor, 1.0),
            c.hslLightness,
            c.a
        )
    }

    function mix(c1, c2, t) {
        if (t > 1) {t = 1}
        return blend(c1, c2, t)
    }

    function blend(c1, c2, t) {
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * t,
            c1.g + (c2.g - c1.g) * t,
            c1.b + (c2.b - c1.b) * t,
            c1.a + (c2.a - c1.a) * t
        )
    }

    function apply() {
        switch (current) {
            case "hutao": {
                accentStrong  = "#8B1E2D"
                accentSoft    = "#E6A6B0"   
                bgBase        = "#151214"   
                bgSurface     = "#1D191C"   
                bgMuted       = "#2A2428"   
                textPrimary   = "#EDE6E8"
                textSecondary = "#B8AEB2"
                textDisabled  = "#7A6F74"

                info          = "#2fbcf0"
                error         = "#ec2727"
                warn          = "#eea022"
                success       = "#38de31"
            }

        }
    }

    Component.onCompleted: apply()

}

