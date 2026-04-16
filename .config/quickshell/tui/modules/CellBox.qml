pragma ComponentBehavior: Bound

import qs.config
import qs.modules

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

    Cells {

        id: border_cells

        w: root.w
        h: root.h

        x: -Cell.w(1)
        y: -Cell.h(1)

        grid: root.grid

        color: root.color

        ColumnLayout {

            spacing: 0

            Cells {

                w: root.w
                h: 1
                color: "transparent"

                RowLayout {

                    spacing: 0

                    CellText {

                        clip: true

                        bg: root.border.type == 0 ? root.border.color : "transparent"

                        text: {
                            switch (root.border.type) {
                                case 0: return " ";
                                case 1: return "┌";
                                case 2: return "┏";
                                case 3: return "╔";
                                case 4: return "╭";
                            }
                        }
                        color: root.border.color

                    }

                    Repeater {

                        model: root.w - 2

                        delegate: CellText {

                            required property int index

                            bg: root.border.type == 0 ? root.border.color : "transparent"
                            clip: true

                            text: {
                                if (index >= root.header.offset && index < root.header.offset + root.header.text.length) return " "
                                switch (root.border.type) {
                                    case 0: return " ";
                                    case 1: return "─";
                                    case 2: return "━";
                                    case 3: return "═";
                                    case 4: return "─";
                                }
                            }
                        color: root.border.color

                        }

                    }

                    CellText {

                        bg: root.border.type == 0 ? root.border.color : "transparent"
                        clip: true

                        text: {
                            switch (root.border.type) {
                                case 0: return " ";
                                case 1: return "┐";
                                case 2: return "┓";
                                case 3: return "╗";
                                case 4: return "╮";
                            }
                        }
                        color: root.border.color

                    }

                }

                CellText {

                    x: Cell.w(1) + Cell.w(root.header.offset)

                    text: root.header.text
                    font: root.header.font
                    color: root.header.color

                    preferedW: root.w - 2

                    bg: root.color

                }
            }

            ColumnLayout {

                spacing: 0

                Repeater {

                    model: root.h - 2

                    delegate: RowLayout {

                        spacing: 0

                        CellText {

                            bg: root.border.type == 0 ? root.border.color : "transparent"
                            clip: true

                            text: {
                                switch (root.border.type) {
                                    case 0: return " ";
                                    case 1: return "│";
                                    case 2: return "┃";
                                    case 3: return "║";
                                    case 4: return "│";
                                }
                            }
                        color: root.border.color

                        }

                        Cells {
                            w: root.w - 2
                            color: "transparent"
                        }

                        CellText {

                            bg: root.border.type == 0 ? root.border.color : "transparent"
                            clip: true

                            text: {
                                switch (root.border.type) {
                                    case 0: return " "; 
                                    case 1: return "│"; 
                                    case 2: return "┃"; 
                                    case 3: return "║"; 
                                    case 4: return "│"; 
                                }
                            }
                        color: root.border.color

                        }

                    }

                }

            }

            Cells {

                w: root.w
                h: 1
                color: "transparent"

                RowLayout {

                    spacing: 0

                    CellText {

                        bg: root.border.type == 0 ? root.border.color : "transparent"
                        clip: true

                        text: {
                            switch (root.border.type) {
                                case 0: return " "; 
                                case 1: return "└"; 
                                case 2: return "┗"; 
                                case 3: return "╚"; 
                                case 4: return "╰"; 
                            }
                        }
                        color: root.border.color

                    }

                    Repeater {

                        model: root.w - 2

                        delegate: CellText {

                            required property int index

                            bg: root.border.type == 0 ? root.border.color : "transparent"
                            clip: true

                            text: {
                                if (index >= root.footer.offset && index < root.footer.offset + root.footer.text.length) return " "
                                switch (root.border.type) {
                                    case 0: return " "; 
                                    case 1: return "─"; 
                                    case 2: return "━"; 
                                    case 3: return "═"; 
                                    case 4: return "─"; 
                                }
                            }
                        color: root.border.color

                        }

                    }

                    CellText {

                        bg: root.border.type == 0 ? root.border.color : "transparent"
                        clip: true

                        text: {
                            switch (root.border.type) {
                                case 0: return " "; 
                                case 1: return "┘"; 
                                case 2: return "┛"; 
                                case 3: return "╝"; 
                                case 4: return "╯"; 
                            }
                        }
                        color: root.border.color

                    }

                }

                CellText {

                    x: Cell.w(1) + Cell.w(root.footer.offset)

                    text: root.footer.text
                    font: root.footer.font
                    color: root.footer.color

                    preferedW: root.w - 2

                    bg: root.color

                }
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
