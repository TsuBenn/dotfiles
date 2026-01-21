pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string current: ""

    //Neutral
    property color text
    property color text_sink
    property color invert_text
    property color icon
    property color icon_sink
    property color invert_icon

    //Primary
    property color accent
    property color primary
    property color secondary

    //Semantic
    property color info
    property color success
    property color error
    property color warn

    function saturate(c, factor) {
        return Qt.hsla(
            c.hslHue,
            Math.min(c.hslSaturation * factor, 1.0),
            c.hslLightness,
            c.a
        )
    }

    function blendHsl(c1, c2, t) {
        return Qt.hsla(
            c1.hslHue + (c2.hslHue - c1.hslHue) * t,
            c1.hslSaturation + (c2.hslSaturation - c1.hslSaturation) * t,
            c1.hslLightness + (c2.hslLightness - c1.hslLightness) * t,
            c1.a + (c2.a - c1.a) * t
        )
    }

    function apply() {
        switch (current) {
            default:
            accent = "#26cae1"
            primary = "#2d2d2e"
            secondary = "#1c1c1d"

            text = "white"
            text_sink = "#8c8c92"
            invert_text = secondary
            icon = text
            icon_sink = text_sink
            invert_icon = invert_text

            info = "#2fbcf0"
            success = "#38de31"
            error = "#ec2727"
            warn = "#eea022"
        }
    }

    Component.onCompleted: apply()

}

