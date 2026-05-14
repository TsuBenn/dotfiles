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
                    }

                }

            }

        }

    }


}
