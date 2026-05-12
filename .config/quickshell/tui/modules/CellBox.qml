pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property int w: 3
    property int h: 3

    readonly property int contentW: w - 2
    readonly property int contentH: h - 2

    component Border: Item {
        property int type: 1
        property color color: Colors.fgBase
    }
    component Header: Item {
        property string text: ""
        property int offset: 0
        property font font: Cell.font
        property color color: Colors.fgBase
    }

    property Border border: Border {
        type: 1
        color: Colors.fgBase
    }

    property Header header: Header {
        text: ""
        offset: 0
        font: Cell.font
        color: Colors.fgBase
    }

    property Header footer: Header {
        text: ""
        offset: 0
        font: Cell.font
        color: Colors.fgBase
    }

    property color color: Colors.bgSurface

    implicitWidth: Cell.w(w) - Cell.w(2)
    implicitHeight: Cell.h(h) - Cell.h(2)

    property bool grid: false

    Component.onCompleted: {
        x += Cell.w(1)
        y += Cell.h(1)
        for (const i in children) {
            if (i >= 2) {
                children[i].parent = content
            }
        }
    }

    Loader {

        active: root.visible || !SettingsInfo.optimizeMemory

        sourceComponent: Cells {

            id: border_cells

            w: root.w
            h: root.h

            x: -Cell.w(1)
            y: -Cell.h(1)

            grid: root.grid

            color: root.color

            CellText {

                clip: true

                bg: root.border.type == 0 ? root.border.color : "transparent"

                text: {
                    switch (root.border.type) {
                        case 0: return " ";
                        case 1: {
                            return "┌"
                            +(header.w > 0 ? "─".repeat(Math.max(root.header.offset,0))+" ".repeat(header.w)+"─".repeat(root.w - 2 - Math.max(root.header.offset,0) - header.w) : "─".repeat(root.w-2))
                            +"┐\n"
                            +("│"+" ".repeat(root.w-2)+"│\n").repeat(root.h-2)
                            +"└"
                            +(footer.w > 0 ? "─".repeat(Math.max(root.footer.offset,0))+" ".repeat(footer.w)+"─".repeat(root.w - 2 - Math.max(root.footer.offset,0) - footer.w) : "─".repeat(root.w-2))
                            +"┘";
                        }

                        case 2: {
                            return "┏"
                            +(header.w > 0 ? "━".repeat(Math.max(root.header.offset,0))+" ".repeat(header.w)+"━".repeat(root.w - 2 - Math.max(root.header.offset,0) - header.w) : "━".repeat(root.w-2))
                            +"┓\n"
                            +("┃"+" ".repeat(root.w-2)+"┃\n").repeat(root.h-2)
                            +"┗"
                            +(footer.w > 0 ? "━".repeat(Math.max(root.footer.offset,0))+" ".repeat(footer.w)+"━".repeat(root.w - 2 - Math.max(root.footer.offset,0) - footer.w) : "━".repeat(root.w-2))
                            +"┛";
                        }

                        case 3: {
                            return "╔"
                            +(header.w > 0 ? "═".repeat(Math.max(root.header.offset,0))+" ".repeat(header.w)+"═".repeat(root.w - 2 - Math.max(root.header.offset,0) - header.w) : "═".repeat(root.w-2))
                            +"╗\n"
                            +("║"+" ".repeat(root.w-2)+"║\n").repeat(root.h-2)
                            +"╚"
                            +(footer.w > 0 ? "═".repeat(Math.max(root.footer.offset,0))+" ".repeat(footer.w)+"═".repeat(root.w - 2 - Math.max(root.footer.offset,0) - footer.w) : "═".repeat(root.w-2))
                            +"╝";
                        }

                        case 4: {
                            return "╭"
                            +(header.w > 0 ? "─".repeat(Math.max(root.header.offset,0))+" ".repeat(header.w)+"─".repeat(root.w - 2 - Math.max(root.header.offset,0) - header.w) : "─".repeat(root.w-2))
                            +"╮\n"
                            +("│"+" ".repeat(root.w-2)+"│\n").repeat(root.h-2)
                            +"╰"
                            +(footer.w > 0 ? "─".repeat(Math.max(root.footer.offset,0))+" ".repeat(footer.w)+"─".repeat(root.w - 2 - Math.max(root.footer.offset,0) - footer.w) : "─".repeat(root.w-2))
                            +"╯";
                        }
                    }
                }
                color: root.border.color

            }

            CellText {
                id: header
                x: Cell.w(Math.max(root.header.offset,0)+1)
                anchors.top: parent.top
                text: root.header.text
                preferedW: text == "" || text.length < root.w-2-Math.max(root.header.offset,0) ? 0 : root.w-2-Math.max(root.header.offset,0)
                font: root.header.font
            }
            CellText {
                id: footer
                x: Cell.w(Math.max(root.footer.offset,0)+1)
                anchors.bottom: parent.bottom
                text: root.footer.text
                preferedW: text == "" || text.length < root.w-2-Math.max(root.footer.offset,0) ? 0 : root.w-2-Math.max(root.footer.offset,0)
                font: root.footer.font
            }

        }

    }

    Rectangle {

        id: content

        anchors.fill: parent

        clip: true

        color: "transparent"

    }

}
