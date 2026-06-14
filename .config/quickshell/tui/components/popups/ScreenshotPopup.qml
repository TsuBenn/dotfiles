pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

CellPopup {

    id: root

    implicitWidth: monitor.width
    implicitHeight: monitor.height

    property bool edit: false
    property bool fullscreen: false

    escapeToClose: false

    onVisibleChanged: {
        if (visible) {
            // console.log(`${root.implicitHeight} ${root.implicitWidth}`)
            if (fullscreen) {
                mask.visible = true
                mouse.x1 = 0
                mouse.y1 = 0
                mouse.x2 = root.monitor.width
                mouse.y2 = root.monitor.height
                ScreenshotInfo.screenshot(0, 0, root.monitor.width, root.monitor.height)
                snapAndCloseAnim.restart()
                fullscreen = false
            }
        } else {
            ScreenshotInfo.clear_cache()
            namer.visible = false
            root.edit = false
            mask.visible = false
            mouse.x1 = 0
            mouse.x2 = 0
            mouse.y1 = 0
            mouse.y2 = 0
        }
    }

    Component.onCompleted: {
        ScreenshotInfo.cached.connect(() => {
            if (!HyprInfo.isCurrentMonitor(root.monitor.name)) return
            if (root.visible) return
            cache.source = ""
            cache.source = ScreenshotInfo.cache_path
            PopupManager.open("screenshot")
        })
        SettingsInfo.screenshotCursorChanged.connect(() => {
            if (!HyprInfo.isCurrentMonitor(root.monitor.name)) return
            cache.source = ""
            cache.source = ScreenshotInfo.cache_path
        })
        PopupManager.signalSent.connect((id, sig) => {
            if (!HyprInfo.isCurrentMonitor(root.monitor.name)) return
            if (id == "screenshot" && sig == "full") {
                root.fullscreen = true
            }
            if (id == "screenshot" && sig == "full_now") {
                if (snapAndCloseAnim.running) return
                PopupManager.open("screenshot")
                mask.visible = true
                mouse.x1 = 0
                mouse.y1 = 0
                mouse.x2 = root.monitor.width
                mouse.y2 = root.monitor.height
                ScreenshotInfo.screenshot(0, 0, root.monitor.width, root.monitor.height)
                snapAndCloseAnim.restart()
                fullscreen = false
            }
        })
    }

    function screenshot() {
        ScreenshotInfo.screenshot(screenshot_region.x, screenshot_region.y, screenshot_region.implicitWidth, screenshot_region.implicitHeight)
    }

    SequentialAnimation {
        id: snapAndCloseAnim
        ColorAnimation {
            target: overlay
            property: "color"
            from: Colors.transparent(Colors.fgDim,0)
            to: Colors.fgDim
            duration: 0
            easing.type: Easing.OutCubic
        }
        ColorAnimation {
            target: overlay
            property: "color"
            from: Colors.fgDim
            to: Colors.transparent(Colors.fgDim,0)
            duration: 300
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: mask
            property: "opacity"
            to: 0
            duration: 300
            easing.type: Easing.OutCubic
        }
        ScriptAction {
            script: {
                root.close()
                mask.opacity = 1
            }
        }
    }

    SequentialAnimation {
        id: snapAnim
        ColorAnimation {
            target: overlay
            property: "color"
            from: Colors.transparent(Colors.fgDim,0)
            to: Colors.fgDim
            duration: 0
            easing.type: Easing.OutCubic
        }
        ColorAnimation {
            target: overlay
            property: "color"
            from: Colors.fgDim
            to: Colors.transparent(Colors.fgDim,0)
            duration: 300
            easing.type: Easing.OutCubic
        }
        ParallelAnimation {
            NumberAnimation {
                target: overlay
                property: "opacity"
                to: 0
                duration: 300
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: screenshot_region
                property: "opacity"
                to: 0
                duration: 300
                easing.type: Easing.OutCubic
            }
            ScriptAction {
                script: {
                    root.edit = false
                }
            }
        }
        ScriptAction {
            script: {
                overlay.opacity = 1
                screenshot_region.opacity = 1
                mouse.x1 = 0
                mouse.x2 = 0
                mouse.y1 = 0
                mouse.y2 = 0
            }
        }
    }

    ShortcutHandler {
        shortcuts: [
            {
                binds: "Ctrl+A",
                action: () => {
                    root.edit = true
                    full_select.restart()
                }
            },
            {
                binds: "Return",
                active: root.edit && !namer.visible,
                action: () => {
                    if (snapAndCloseAnim.running) return
                    root.screenshot()
                    stay.yes ? snapAnim.restart() : snapAndCloseAnim.restart()
                }
            },
            {
                binds: "C",
                action: () => {
                    SettingsInfo.toggle("screenshotCursor")
                }
            },
            {
                binds: "Escape",
                action: () => {
                    if (namer_textfield.focus) {
                        namer.visible = false
                    } else {
                        root.close()
                    }
                }
            }
        ]
    }

    SequentialAnimation {
        id: full_select
        ScriptAction {
            script: {
                if (overlay.implicitWidth-2 == 0 || overlay.implicitHeight-2 == 0) {
                    mouse.x1 = root.monitor.width/2
                    mouse.y1 = root.monitor.height/2
                    mouse.x2 = root.monitor.width/2
                    mouse.y2 = root.monitor.height/2
                }
                if (mouse.x1 > mouse.x2) {
                    [mouse.x2, mouse.x1] = [mouse.x1,mouse.x2]
                }
                if (mouse.y1 > mouse.y2) {
                    [mouse.y2, mouse.y1] = [mouse.y1,mouse.y2]
                }
            }
        }
        ParallelAnimation {
            NumberAnimation {target: mouse; property: "x1"; to: 0; duration: 200; easing.type: Easing.OutCubic}
            NumberAnimation {target: mouse; property: "y1"; to: 0; duration: 200; easing.type: Easing.OutCubic}
            NumberAnimation {target: mouse; property: "x2"; to: root.monitor.width; duration: 200; easing.type: Easing.OutCubic}
            NumberAnimation {target: mouse; property: "y2"; to: root.monitor.height; duration: 200; easing.type: Easing.OutCubic}
        }
    }

    Item {

        id: mask

        anchors.fill: parent

        visible: false

        Image {

            id: cache

            anchors.fill: parent

            source: ""

            cache: false

            onStatusChanged: {
                if (status == Image.Ready && !root.fullscreen) {
                    mask.visible = true
                }
            }

        }

        Rectangle {

            anchors.fill: parent

            opacity: mask.visible

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

            color: !root.edit
            ? Colors.transparent(Qt.darker(Colors.bgBase,1.5),0.5)
            : Colors.transparent(Qt.darker(Colors.bgBase,1.5),0.9)

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: region
                invert: true
            }

        }

        CellText {

            id: hints

            property real real_opacity: 1

            opacity: (( overlay.implicitWidth-2 == 0 || overlay.implicitHeight-2 == 0) && mask.visible && !root.fullscreen && SettingsInfo.hints)*real_opacity

            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

            x: Cell.centerWCell(implicitWidth,root.monitor.width)
            y: Cell.centerHCell(implicitHeight,root.monitor.height)

            text: [
                "      <b>Drag</b> <i>to select screenshot region</i>      ",
                "                                            ",
                "     <b>Shift Drag</b> <i>to select region & edit</i>     ",
                "                                            ",
                "<b>End</b> <i>or</i> <b>Print</b> <i>to screenshot the whole monitor</i>",
                "                                            ",
                "     <b>Ctrl+A</b> <i>to select the whole monitor</i>     ",
                "                                            ",
                "      <b>C</b> <i>to toggle cursor capture <b>(" + (SettingsInfo.screenshotCursor ? "ON " : "OFF") + ")</b></i>      ",
            ].join("\n")


        }

        Rectangle {

            id: region

            visible: false

            anchors.fill: parent

            color: "transparent"

            Rectangle {

                id: screenshot_region

                x: Math.min(mouse.x1,mouse.x2)
                y: Math.min(mouse.y1,mouse.y2)

                implicitWidth:  Math.abs(mouse.x1-mouse.x2)
                implicitHeight: Math.abs(mouse.y1-mouse.y2)

            }

        }

        Rectangle {

            id: overlay

            opacity: !(
                overlay.implicitWidth-2 == 0
                || overlay.implicitHeight-2 == 0
            )

            x: Math.min(mouse.x1,mouse.x2) - 1
            y: Math.min(mouse.y1,mouse.y2) - 1

            implicitWidth:  Math.abs(mouse.x1-mouse.x2) + 2
            implicitHeight: Math.abs(mouse.y1-mouse.y2) + 2

            color: "transparent"

            border.width: 1
            border.color: Colors.transparent(Colors.fgBase, 0.5)

        }


        CellText {

            opacity: !(
                overlay.implicitWidth-2 == 0
                || overlay.implicitHeight-2 == 0
            ) && !snapAnim.running

            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            x: Math.max(Cell.toW(overlay.x),0)
            y: {
                if (Cell.toH(overlay.y) - Cell.h(1) < 0) {
                    if (Cell.toH(overlay.y + overlay.implicitHeight-2,"ceil") + Cell.h(1) >= Cell.toH(root.monitor.height,"floor")) {
                        return Cell.toH(overlay.y+overlay.implicitHeight,"floor") - Cell.h(1)
                    } else {
                        return Cell.toH(overlay.y+overlay.implicitHeight,"floor") + Cell.h(1)
                    }
                } else {
                    if (Cell.toH(overlay.y + overlay.implicitHeight-2,"ceil") + Cell.h(1) >= Cell.toH(root.monitor.height,"floor")) {
                        return Cell.toH(overlay.y+overlay.implicitHeight,"floor") - Cell.h(1)
                    } else {
                        return Cell.toH(overlay.y - Cell.h(0.5),"floor") - Cell.h(1)
                    }
                }
            }

            bg: Colors.bgSurface

            text: `${overlay.implicitWidth.toFixed(0)-2}x${overlay.implicitHeight.toFixed(0)-2}`

        }


        Timer {
            id: drag_delay
            running: mouse.buttonDown == "L" || mouse.buttonDown == "SL" 
            repeat: true
            interval: SettingsInfo.frameTime*1000
            onTriggered: {
                mask.selectRegion()
            }
        }

        function selectRegion() {
            mouse.x2 = mouse.mouseX
            mouse.y2 = mouse.mouseY
        }

        MouseControl {

            id: mouse

            anchors.fill: parent

            property int x1: 0
            property int y1: 0

            property int x2: 0
            property int y2: 0

            onPressed: (button) => {
                if (buttonDown == "L" || buttonDown == "SL") {
                    root.edit = false
                    x1 = mouseX
                    y1 = mouseY
                    x2 = mouseX
                    y2 = mouseY
                }
            }

            onMoved: (x, y) => {
                if ((buttonDown == "L" || buttonDown == "SL") && (x-x1)%3==0 && (y-y1)%3==0 ) {
                    mask.selectRegion()
                }
            }

            onReleased: (button) => {
                if ( overlay.implicitWidth-2 == 0 || overlay.implicitHeight-2 == 0) return
                if (button == "L") {
                    mask.selectRegion()
                    root.screenshot()
                    snapAndCloseAnim.restart()
                } if (button == "SL") {
                    root.edit = true
                }
            }

        }

        RowLayout {

            visible: !(
                overlay.implicitWidth-2 == 0
                || overlay.implicitHeight-2 == 0
            ) && root.edit == true

            spacing: Cell.w(1)

            x: Math.max(Cell.toW(overlay.x + overlay.implicitWidth - implicitWidth),Cell.w(1))
            y: Cell.toH(overlay.y + overlay.implicitHeight,"ceil") + Cell.h(1) >= Cell.toH(root.monitor.height,"floor") ? Cell.toH(overlay.y + overlay.implicitHeight) - Cell.h(1) : Cell.toH(overlay.y + overlay.implicitHeight) + Cell.h(1)

            CellButton {

                id: stay

                property bool yes: SettingsInfo.screenshotStay

                text: "Lock"

                color: yes ? Colors.accentStrong : Colors.bgOverlay
                fg: yes ? Colors.onAccent : Colors.fgBase

                onReleased: (button) => {
                    if (button == "L") {
                        SettingsInfo.toggle("screenshotStay")
                    }
                }
            }

            CellButton {

                id: cursor

                property bool yes: SettingsInfo.screenshotCursor

                text: "Cursor"

                color: yes ? Colors.accentStrong : Colors.bgOverlay
                fg: yes ? Colors.onAccent : Colors.fgBase

                onReleased: (button) => {
                    if (button == "L") {
                        SettingsInfo.toggle("screenshotCursor")
                    }
                }
            }

            CellButton {

                text: "Save & Rename"

                color: [Colors.accentStrong, Colors.bgOverlay]
                fg: [Colors.onAccent, Colors.fgBase]

                onReleased: (button) => {
                    if (button == "L") {
                        namer.visible = true
                    }
                }
            }

            CellButton {
                text: "Save & Copy"

                color: [Colors.accentStrong, Colors.bgOverlay]
                fg: [Colors.onAccent, Colors.fgBase]

                onReleased: (button) => {
                    if (button == "L") {
                        ScreenshotInfo.screenshot(screenshot_region.x, screenshot_region.y, screenshot_region.implicitWidth, screenshot_region.implicitHeight)
                        stay.yes ? snapAnim.restart() : snapAndCloseAnim.restart()
                    }
                }
            }

            CellButton {

                text: "Copy & Delete"

                color: [Colors.accentStrong, Colors.bgOverlay]
                fg: [Colors.onAccent, Colors.fgBase]

                onReleased: (button) => {
                    if (button == "L") {
                        ScreenshotInfo.screenshot(screenshot_region.x, screenshot_region.y, screenshot_region.implicitWidth, screenshot_region.implicitHeight, "", true, false)
                        stay.yes ? snapAnim.restart() : snapAndCloseAnim.restart()
                    }
                }

            }

        }

        MouseControl {

            visible: namer.visible

            anchors.fill: parent

            onPressed: (button) => {
                namer.visible = false
            }

        }

        CellBox {

            x: Cell.centerWCell(implicitWidth, parent.width)
            y: Cell.centerHCell(implicitHeight, parent.height)

            id: namer

            visible: false

            w: 40
            h: 9

            ColumnLayout {

                y: Cell.h(1)

                spacing: Cell.h(1)

                CellText {

                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                    text: "Rename screenshot"

                }

                Cells {

                    Layout.leftMargin: Cell.w(1)

                    w: namer.contentW - 2
                    h: 1

                    color: Colors.bgOverlay

                    CellTextField {

                        id: namer_textfield

                        w: parent.w
                        h: parent.h

                        placeholder: "Screenshot name (No spaces allowed)"

                        onTextAdded: (input) => {
                            if (input == " ") {
                                set(text.replace(/ /g, ""))
                            }
                        }

                        onEntered: (input) => {
                            ScreenshotInfo.screenshot(screenshot_region.x, screenshot_region.y, screenshot_region.implicitWidth, screenshot_region.implicitHeight, namer_textfield.text, true, true)
                            namer.visible = false
                            stay.yes ? snapAnim.restart() : snapAndCloseAnim.restart()
                        }

                    }

                }

                RowLayout {

                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                    spacing: Cell.w(2)

                    CellButton {

                        text: "Save & Copy"

                        color: [Colors.accentStrong, Colors.bgOverlay]
                        fg: [Colors.onAccent, Colors.fgBase]

                        onReleased: (button) => {
                            if (button == "L") {
                                ScreenshotInfo.screenshot(screenshot_region.x, screenshot_region.y, screenshot_region.implicitWidth, screenshot_region.implicitHeight, namer_textfield.text, true, true)
                                namer.visible = false
                                stay.yes ? snapAnim.restart() : snapAndCloseAnim.restart()
                            }
                        }

                    }

                    CellButton {

                        text: "Save"

                        color: [Colors.accentStrong, Colors.bgOverlay]
                        fg: [Colors.onAccent, Colors.fgBase]

                        onReleased: (button) => {
                            if (button == "L") {
                                ScreenshotInfo.screenshot(screenshot_region.x, screenshot_region.y, screenshot_region.implicitWidth, screenshot_region.implicitHeight, namer_textfield.text, false, true)
                                namer.visible = false
                                stay.yes ? snapAnim.restart() : snapAndCloseAnim.restart()
                            }
                        }

                    }

                    CellButton {

                        text: "Cancel"

                        color: [Colors.accentStrong, Colors.bgOverlay]
                        fg: [Colors.onAccent, Colors.fgBase]

                        onReleased: (button) => {
                            if (button == "L") {
                                namer.visible = false
                            }
                        }

                    }

                }

            }


        }

    }

}

