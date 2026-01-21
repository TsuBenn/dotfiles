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

    function apply() {
        switch (current) {
            default:
                text = "white"
                text_sink = "#8c8c92"
                invert_text = secondary
                icon = text
                icon_sink = text_sink
                invert_icon = invert_text

                accent = "#26cae1"
                primary = "#2d2d2e"
                secondary = "#212124"

                info = "#497aff"
                success = "#11d70e"
                error = "#ff3928"
                warn = "#e8f526"
        }
    }

    Component.onCompleted: apply()

}

