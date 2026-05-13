pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string current: "hutao"

    onCurrentChanged: {
        if (Object.keys(colors).includes(current)) {
            apply()
        } else {
            NotificationsInfo.send("System","","Colors",`Color palette "${current}" not found!`)
        }
    }

    function reload() {
        load.reload()
    }

    signal applied()

    // Background
    property color bgBase
    property color bgSurface
    property color bgOverlay

    // Foreground
    property color fgBase
    property color onAccent
    property color fgDim
    property color fgSubtle

    // Accent
    property color accentStrong
    property color accentDim
    property color secondary

    // Semantic
    property color info
    property color success
    property color warning
    property color danger

    // Border
    property color borderActive
    property color borderInactive

    Behavior on bgBase {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on bgSurface {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on bgOverlay {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on fgBase {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on onAccent {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on fgDim {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on fgSubtle {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on accentStrong {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on accentDim {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on secondary {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on info {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on success {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on warning {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}
    Behavior on danger {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}

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
        onAccent       = theme.onAccent
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

        root.applied()
    }

    property var colors: ({})

    FileView {

        id: load

        path: SystemInfo.configdir + "/scripts/colors.json"

        onLoaded: {
            root.colors = JSON.parse(text())
            root.apply()
        }


    }
}
