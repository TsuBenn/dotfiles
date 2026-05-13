pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick
import Qt5Compat.GraphicalEffects

CellPopup {

    id: root

    w: 100
    h: Cell.hCount(layout.implicitHeight) + 1

    property var result: Object.keys(Colors.colors)
    property var colors: Object.keys(Colors.colors)

    escapeToClose: textfield.focus

    CellBox {

        w: root.w + 2
        h: root.h + 2

        ColumnLayout {

            id: layout

            property string current: Colors.current

            onVisibleChanged: {
                layout.edit = false
            }

            onSelectedChanged: {
                layout.edit = false
            }

            onEditChanged: {
                if (!layout.edit) {
                    textfield.disabled = false
                    textfield.grabFocus()
                }
            }

            property bool edit: false

            spacing: 0

            property int selected: 0
            property var color: Colors.colors[root.result[selected]] ?? {
                "name": "",
                "description": "",
                "bgBase": "",
                "bgSurface": "",
                "bgOverlay": "",
                "fgBase": "",
                "onAccent": "",
                "fgDim": "",
                "fgSubtle": "",
                "accentStrong": "",
                "accentDim": "",
                "secondary": "",
                "info": "",
                "success": "",
                "warning": "",
                "danger": "",
            }

            RowLayout {

                spacing: 0

                ColumnLayout {

                    Layout.alignment: Qt.AlignTop

                    spacing: 0

                    RowLayout {

                        spacing: 0

                        ColumnLayout {

                            spacing: 0

                            Cells {

                                Layout.alignment: Qt.AlignTop

                                w: 37
                                h: 23

                                color: "transparent"

                                CellScrollView {

                                    id: list

                                    w: parent.w
                                    h: parent.h

                                    onVisibleChanged: {
                                        reset()
                                    }

                                    ColumnLayout {

                                        spacing: 0

                                        Repeater {

                                            model: root.result

                                            delegate: Cells {

                                                id: color

                                                required property int index
                                                required property string modelData

                                                property var source: Colors.colors[modelData]

                                                property bool selected: Colors.current == modelData
                                                property bool highlighted: layout.selected == index

                                                w: list.contentW
                                                h: 2

                                                color: highlighted ? color.source.accentStrong : (color_mouse.hovered ? color.source.bgOverlay : "transparent")

                                                ColumnLayout {

                                                    spacing: 0

                                                    CellText {

                                                        Layout.leftMargin: Cell.w(1)

                                                        text: color.source.name
                                                        color: color.highlighted ? color.source.onAccent : (color_mouse.hovered ? color.source.fgBase : Colors.fgBase)
                                                        preferedW: color.w - 2
                                                        font: Cell.fontB
                                                    }

                                                    CellSeparator {
                                                        w: color.w
                                                        type: 2
                                                        color: Colors.bgOverlay
                                                    }

                                                }

                                                MouseControl {

                                                    id: color_mouse

                                                    anchors.fill: parent
                                                    anchors.topMargin: -Cell.h(0.5)
                                                    anchors.bottomMargin: Cell.h(0.5)

                                                    onReleased: (button) => {
                                                        if (button == "L") {
                                                            layout.selected = color.index
                                                        }
                                                    }

                                                }

                                            }

                                        }

                                    }

                                }

                            }


                        }

                        CellSeparator {

                            h: 23
                            type: 0
                            color: Colors.fgSubtle
                            vertical: true

                        }

                    }

                    CellSeparator {

                        w: 38
                        type: 2
                        color: Colors.bgOverlay

                    }

                }


                Cells {

                    Layout.alignment: Qt.AlignTop

                    visible: layout.color.name != "" && !layout.edit

                    id: preview

                    w: root.w - 38
                    h: 23

                    color: layout.color["bgSurface"]

                    property color label: layout.color["secondary"]

                    ColumnLayout {

                        spacing: 0

                        CellSeparator {

                            w: preview.w
                            type: 2
                            color: layout.color["accentStrong"]
                            bg: layout.color["bgSurface"]

                        }

                        CellText {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                            text: "Preview"
                            color: layout.color["secondary"]
                            font: Cell.fontB

                        }

                        CellSeparator {

                            w: preview.w
                            type: 2
                            color: layout.color["accentStrong"]
                            bg: layout.color["bgSurface"]

                        }

                        Cells {

                            Layout.leftMargin: Cell.w(1)

                            w: preview.w - 2
                            h: 1
                            color: "transparent"

                            CellText {

                                text: "Name:"
                                color: layout.color["fgDim"]

                            }

                            MarqueeCellText {

                                x: Cell.w(6)

                                text: layout.color["name"]
                                fg: layout.color["fgBase"]
                                font: Cell.fontB
                                cellw: preview.w - 14

                            }

                        }

                        ColumnLayout {

                            Layout.leftMargin: Cell.w(1)

                            spacing: 0

                            CellText {

                                text: "Description:"
                                color: layout.color["fgDim"]

                            }

                            Cells {

                                w: preview.w - 2
                                h: 3

                                color: "transparent"

                                CellText {

                                    text: layout.color["description"]
                                    color: layout.color["fgBase"]
                                    preferedW: preview.w - 2
                                    font: Cell.fontB
                                    wrap: true

                                }

                            }

                        }

                        CellSeparator {

                            w: preview.w
                            type: 0
                            color: layout.color["accentDim"]
                            bg: layout.color["bgSurface"]

                        }

                        CellTabs {

                            id: tab

                            w: preview.w

                            onVisibleChanged: {
                                selected = 0
                            }

                            items: [
                                "Widgets",
                                "Color list",
                            ]

                            color {
                                bg: layout.color["bgSurface"]
                                fg: layout.color["bgOverlay"]
                                base: layout.color["fgBase"]
                                inactive: layout.color["fgSubtle"]
                                active: layout.color["accentStrong"]
                            }

                        }

                        ColumnLayout {

                            visible: tab.selected == 0
                            spacing: 0

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Button       "
                                    color: preview.label

                                }

                                CellButton {

                                    text: "Click me!"

                                    fg: [layout.color["onAccent"], layout.color["fgBase"]]
                                    color: [layout.color["accentStrong"], layout.color["bgOverlay"]]

                                }

                                CellButton {

                                    text: "Click me!"

                                    fg: layout.color["fgSubtle"]
                                    color: layout.color["bgOverlay"]

                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: layout.color["bgOverlay"]
                                bg: layout.color["bgSurface"]

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Dropdown     "
                                    color: preview.label

                                }

                                CellDropdown {

                                    w: 12

                                    text: ""

                                    items: [
                                        {label: "First", action: () => {selected = 0}},
                                        {label: "Second", action: () => {selected = 1}},
                                        {label: "Third", action: () => {selected = 2}},
                                    ]

                                    button {
                                        color: layout.color["bgOverlay"]
                                        fg: layout.color["fgBase"]
                                        active: layout.color["bgOverlay"]
                                        active_invert: layout.color["fgBase"]
                                    }

                                    menu {
                                        color: layout.color["bgOverlay"]
                                        fg: layout.color["fgBase"]
                                        active: layout.color["accentStrong"]
                                        active_invert: layout.color["onAccent"]
                                    }

                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: layout.color["bgOverlay"]
                                bg: layout.color["bgSurface"]

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Textfield    "
                                    color: preview.label

                                }

                                Cells {

                                    w: preview.w-16
                                    h: 1

                                    color: layout.color["bgOverlay"]

                                    CellTextField {

                                        focusOnVisible: false

                                        w: parent.w
                                        h: 1

                                        placeholder: "Write something here"

                                        color: layout.color["fgBase"]
                                        invert: layout.color["bgSurface"]
                                        visual_color: layout.color["secondary"]
                                        disabled_color: layout.color["fgSubtle"]

                                        onFocusChanged: {
                                            if (!focus) {
                                                textfield.grabFocus()
                                            }
                                        }

                                    }

                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: layout.color["bgOverlay"]
                                bg: layout.color["bgSurface"]

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: Cell.w(1)

                                CellText {

                                    text: "Progress Bar "
                                    color: preview.label

                                }

                                CellProgressSquare {
                                    w: preview.w - 16
                                    fg: layout.color["accentStrong"]
                                    color: layout.color["bgOverlay"]
                                    percent: 50
                                    interactive: true
                                    onAdjusted: percent = raw_percent
                                }

                            }

                            CellSeparator {

                                w: preview.w

                                padding: 1
                                type: 0
                                color: layout.color["bgOverlay"]
                                bg: layout.color["bgSurface"]

                            }

                            GridLayout {

                                Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                                rowSpacing: Cell.h(0)
                                columnSpacing: Cell.w(2)
                                columns: 3

                                CellText {
                                    text: "[*] VALUE"
                                    color: layout.color["fgBase"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[i] INFO"
                                    color: layout.color["info"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[✓] SUCCESS"
                                    color: layout.color["success"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[-] LABEL"
                                    color: layout.color["fgDim"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[!] WARNING"
                                    color: layout.color["warning"]
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: "[✗] DANGER"
                                    color: layout.color["danger"]
                                    font: Cell.fontB
                                }

                            }

                        }

                        ColumnLayout {

                            visible: tab.selected == 1

                            spacing: 0

                            CellScrollView {

                                w: preview.w
                                h: 10

                                scrollbar {
                                    color: layout.color["fgDim"]
                                    bg_color: layout.color["bgOverlay"]
                                }

                                color: layout.color["bgSurface"]

                                GridLayout {

                                    Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                                    rowSpacing: Cell.h(0)
                                    columnSpacing: Cell.w(1)
                                    columns: 2

                                    Repeater {

                                        model: Object.keys(layout.color).slice(2)

                                        delegate: ColumnLayout {

                                            id: palette

                                            required property int index
                                            required property var modelData

                                            spacing: 0

                                            RowLayout {

                                                Layout.leftMargin: Cell.w(1)

                                                spacing: Cell.w(1)

                                                CellText {

                                                    text: palette.modelData.toString().padEnd(14, " ")
                                                    color: layout.color["fgDim"]

                                                }

                                                Cells {

                                                    w: 13
                                                    h: 1

                                                    color: layout.color[palette.modelData]

                                                }

                                            }

                                            CellSeparator {

                                                w: 30

                                                padding: 1
                                                type: 0
                                                color: layout.color["bgOverlay"]
                                                bg: layout.color["bgSurface"]

                                            }
                                        }

                                    }
                                }

                            }

                        }

                        CellSeparator {

                            w: preview.w

                            type: 0
                            color: layout.color["accentDim"]
                            bg: layout.color["bgSurface"]

                        }

                        CellButton {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, preview.implicitWidth)

                            text: "Apply"

                            fg: [layout.color["onAccent"], layout.color["fgBase"]]
                            color: [layout.color["accentStrong"], layout.color["bgOverlay"]]

                            onReleased: (button) => {
                                if (button == "L") {
                                    Colors.current = root.result[layout.selected]
                                }
                            }

                        }

                        CellSeparator {

                            w: preview.w
                            type: 2
                            color: layout.color["accentStrong"]
                            bg: layout.color["bgSurface"]

                        }


                    }

                }

                Cells {

                    id: empty

                    w: root.w - 38
                    h: 23

                    color: "transparent"

                    CellText {

                        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                        y: Cell.h(Math.round(parent.h*0.5 - 1))

                        text: "No themes found."
                        color: Colors.fgSubtle
                    }
                }

            }

            CellBox {

                id: text_box

                Layout.leftMargin: Cell.w(1)
                Layout.topMargin: Cell.h(1)

                border.type: 4

                w: root.w
                h: 3

                Item {

                    id: text_layout

                    CellTextField {

                        id: textfield

                        x: Cell.w(1)

                        w: text_box.contentW - 2
                        h: 1

                        placeholder: "Search colors"

                        disabled: layout.edit

                        onTextInput: (input) => {
                            layout.selected = 0
                            list.reset()
                            if (input.length == 0) {
                                root.result = Object.keys(Colors.colors)
                            } else {
                                let buffer = []
                                let color_buffer = ({})
                                buffer = Object.keys(Colors.colors).filter((item) => {
                                    if (Colors.colors[item].name.toLowerCase().replace(" ", "").includes(input.toLowerCase().replace(" ", ""))) {
                                        return true
                                    }
                                    else if (Colors.colors[item].description.toLowerCase().replace(" ", "").includes(input.toLowerCase().replace(" ", ""))) {
                                        return true
                                    }
                                    return false
                                })
                                root.result = buffer
                            }
                        }

                    }

                }

            }

        }

    }

}
