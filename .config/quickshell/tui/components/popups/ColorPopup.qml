pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick
import Qt5Compat.GraphicalEffects

CellPopup {

    id: root

    w: Cell.wCount(popup.implicitWidth)
    h: Cell.hCount(popup.implicitHeight)

    property var result: Object.keys(Colors.colors)
    property var colors: Object.keys(Colors.colors)

    RowLayout {

        id: popup

        spacing: Cell.w(2)

        Item {

            id: color

            property bool edit: false

            property var buffer: Colors.dummy

            property var color: Colors.colors[root.result[selected]] ?? Colors.dummy

            property int selected: 0

            property int h: 28

        }

        CellBox {

            w: 38
            h: color.h+2

            CellScrollView {

                id: list

                w: 36
                h: color.h-3

                ColumnLayout {

                    spacing: 0

                    Repeater {

                        model: root.result

                        delegate: Cells {

                            id: theme

                            required property int index
                            required property string modelData

                            property var source: Colors.colors[modelData]

                            property bool isCurrent: modelData == Colors.current
                            property bool selected: color.selected == index

                            w: list.contentW
                            h: 2

                            color: isCurrent ? theme.source.accentStrong : (theme_mouse.hovered ? theme.source.bgOverlay : Colors.bgSurface)

                            ColumnLayout {

                                spacing: 0

                                CellText {

                                    Layout.leftMargin: Cell.w(1)

                                    text: (theme.selected ? "> " : "  ") + theme.source.name
                                    color: theme.isCurrent ? theme.source.onAccent : (theme_mouse.hovered ? theme.source.fgBase : Colors.fgBase)
                                    font: theme.isCurrent ? Cell.fontB : Cell.font

                                    preferedW: theme.w - 4

                                }

                                CellSeparator {
                                    w: theme.w
                                    type: 0
                                    color: Colors.bgOverlay
                                }

                            }

                            MouseControl {

                                id: theme_mouse

                                anchors.fill: parent

                                onReleased: (button) => {
                                    if (button == "L") {
                                        color.selected = theme.index
                                    }
                                }

                            }

                        }

                    }


                }

            }

        }

        CellBox {

            w: 56
            h: 30

            border {
                type: 4
                color: color.color.accentStrong
            }

            color: color.color.bgSurface

            Cells {

                id: preview

                w: 54
                h: 28

                color: "transparent"

                ColumnLayout {

                    spacing: 0

                    CellText {

                        Layout.leftMargin: Cell.w(Math.floor(preview.w/2 - w/2))

                        text: "Previews"

                        color: color.color.secondary
                        font: Cell.fontB
                    }

                    CellSeparator {
                        w: preview.w
                        type: 2
                        color: color.color.accentStrong
                        bg: "transparent"
                    }

                    CellText {
                        Layout.leftMargin: Cell.w(1)
                        text: "Name: "
                        color: color.color.fgDim
                    }

                    CellText {
                        Layout.leftMargin: Cell.w(1)
                        text: color.color.name
                        color: color.color.fgBase
                        preferedW: preview.w-2
                        font: Cell.fontB
                    }

                    CellText {
                        Layout.leftMargin: Cell.w(1)
                        text: "Description: "
                        color: color.color.fgDim
                    }

                    CellText {
                        Layout.leftMargin: Cell.w(1)
                        text: color.color.description
                        color: color.color.fgBase
                        preferedW: preview.w-2
                        preferedH: 3
                        wrap: true
                        font: Cell.fontB
                    }

                    CellSeparator {
                        w: preview.w
                        type: 0
                        color: color.color.accentDim
                        bg: "transparent"
                    }

                    CellTabs {

                        id: preview_tab

                        w: preview.w

                        items: [
                            "Widgets",
                            "Color list",
                        ]

                        color {
                            bg: color.color.bgSurface
                            fg: color.color.bgOverlay
                            base: color.color.fgBase
                            inactive: color.color.fgSubtle
                            active: color.color.accentStrong
                        }
                    }

                    ColumnLayout {

                        id: preview_widgets

                        Layout.leftMargin: Cell.w(1)

                        property int label_width: 14
                        property int widgets_width: preview.w - 2 - label_width

                        spacing: 0

                        component PreviewWidget: RowLayout {

                            spacing: 0

                            property string label: "Buttons"
                            property int label_width: 14

                            CellText {
                                Layout.alignment: Qt.AlignTop
                                text: parent.label
                                color: color.color.secondary
                                preferedW: parent.label_width
                            }

                        }

                        component WidgetSep: CellSeparator {

                            w: preview.w - 2
                            color: color.color.bgOverlay

                        }

                        PreviewWidget {

                            label: "Text"

                            CellText {
                                text: "Normal <b>Bold</b> <i>Italic</i> <i><b>Bold and Italic</b><i/>"
                                color: color.color.fgBase
                            }

                        }

                        WidgetSep {}

                        PreviewWidget {

                            label: "Buttons"

                            RowLayout {

                                spacing: Cell.w(1)

                                CellButton {
                                    text: "Click me!"
                                    color: [color.color.accentStrong, color.color.bgOverlay]
                                    fg: [color.color.onAccent, color.color.fgBase]
                                }

                                CellButton {
                                    text: "Disabled!"
                                    clickable: false
                                    color: color.color.bgOverlay
                                    fg: color.color.fgSubtle
                                }

                            }

                        }

                        WidgetSep {}

                        PreviewWidget {

                            label: "Text field"

                            Cells {

                                w: preview_widgets.widgets_width
                                h: 2

                                color: color.color.bgOverlay

                                CellTextField {

                                    placeholder: "Write something here!"

                                    focusOnVisible: false
                                    wrap: true

                                    w: parent.w
                                    h: parent.h

                                }

                            }

                        }

                        WidgetSep {}

                        PreviewWidget {

                            label: "Dropdown"

                            CellDropdown {

                                menu {
                                    color: color.color.bgOverlay
                                    fg: color.color.fgBase
                                    active: color.color.accentStrong
                                    active_invert: color.color.onAccent
                                }

                                button {
                                    color: color.color.bgOverlay
                                    fg: color.color.fgBase
                                    active: color.color.bgOverlay
                                    active_invert: color.color.fgBase
                                }

                                w: 12

                                text: ""

                                items: [
                                    { label: "Item 1", action: () => {selected = 0} },
                                    { label: "Item 2", action: () => {selected = 1} },
                                    { label: "Item 3", action: () => {selected = 2} },
                                ]

                            }

                        }

                    }

                }

            }

        }

    }


}
