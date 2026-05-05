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
                            +(root.header.text.length > 0 ? "─".repeat(root.header.offset)+(root.header.text)+"─".repeat(root.w - 2 - root.header.offset - root.header.text.length) : "─".repeat(root.w-2))
                            +"┐\n"
                            +("│"+" ".repeat(root.w-2)+"│\n").repeat(root.h-2)
                            +"└"
                            +(root.footer.text.length > 0 ? "─".repeat(root.footer.offset)+(root.footer.text)+"─".repeat(root.w - 2 - root.footer.offset - root.footer.text.length) : "─".repeat(root.w-2))
                            +"┘";
                        }

                        case 2: {
                            return "┏"
                            +(root.header.text.length > 0 ? "━".repeat(root.header.offset)+(root.header.text)+"━".repeat(root.w - 2 - root.header.offset - root.header.text.length) : "━".repeat(root.w-2))
                            +"┓\n"
                            +("┃"+" ".repeat(root.w-2)+"┃\n").repeat(root.h-2)
                            +"┗"
                            +(root.footer.text.length > 0 ? "━".repeat(root.footer.offset)+(root.footer.text)+"━".repeat(root.w - 2 - root.footer.offset - root.footer.text.length) : "━".repeat(root.w-2))
                            +"┛";
                        }

                        case 3: {
                            return "╔"
                            +(root.header.text.length > 0 ? "═".repeat(root.header.offset)+(root.header.text)+"═".repeat(root.w - 2 - root.header.offset - root.header.text.length) : "═".repeat(root.w-2))
                            +"╗\n"
                            +("║"+" ".repeat(root.w-2)+"║\n").repeat(root.h-2)
                            +"╚"
                            +(root.footer.text.length > 0 ? "═".repeat(root.footer.offset)+(root.footer.text)+"═".repeat(root.w - 2 - root.footer.offset - root.footer.text.length) : "═".repeat(root.w-2))
                            +"╝";
                        }

                        case 4: {
                            return "╭"
                            +(root.header.text.length > 0 ? "─".repeat(root.header.offset)+(root.header.text)+"─".repeat(root.w - 2 - root.header.offset - root.header.text.length) : "─".repeat(root.w-2))
                            +"╮\n"
                            +("│"+" ".repeat(root.w-2)+"│\n").repeat(root.h-2)
                            +"╰"
                            +(root.footer.text.length > 0 ? "─".repeat(root.footer.offset)+(root.footer.text)+"─".repeat(root.w - 2 - root.footer.offset - root.footer.text.length) : "─".repeat(root.w-2))
                            +"╯";
                        }
                    }
                }
                color: root.border.color

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
