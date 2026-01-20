pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string current: ""

    property color text
    property color text_sink
    property color invert_text

    property color surface
    property color bg

    property color accent
    property color primary
    property color primary_var
    property color secondary
    property color secondary_var

    property color success
    property color error
    property color warn

    function apply() {
        switch (current) {
            default:
                text = ""
                text_sink = ""
                invert_text = ""

                surface = ""
                bg = ""

                accent = ""
                primary = ""
                primary_var = ""
                secondary = ""
                secondary_var = ""

                success = ""
                error = ""
                warn = ""

        }
    }

    Component.onCompleted: apply()

}

