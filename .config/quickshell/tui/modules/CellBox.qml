pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory && false

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
        color: Colors.accentStrong
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

    property bool isolate: true

    Component.onCompleted: {
        x += Cell.w(1);
        y += Cell.h(1);
    }

    default property alias content: content.data

    property bool optimize: true

    Loader {

        active: (root.visible || !root.optimizeMemory) && !root.optimize

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
                pure: false
                lockPure: true
                cellIsolated: root.isolate
                color: root.border.color

                // Clean, safe helper to prevent negative repeat counts
                function safeRepeat(str, count) {
                    return str.repeat(Math.max(0, Math.floor(count)));
                }

                text: {
                    if (root.border.type === 0) {
                        return " ";
                    }

                    // 1. Pick our borders based on type
                    var chars;
                    switch (root.border.type) {
                    case 1:
                        chars = {
                            tl: "┌",
                            tr: "┐",
                            bl: "└",
                            br: "┘",
                            h: "─",
                            v: "│"
                        };
                        break;
                    case 2:
                        chars = {
                            tl: "┏",
                            tr: "┓",
                            bl: "┗",
                            br: "┛",
                            h: "━",
                            v: "┃"
                        };
                        break;
                    case 3:
                        chars = {
                            tl: "╔",
                            tr: "╗",
                            bl: "╚",
                            br: "╝",
                            h: "═",
                            v: "║"
                        };
                        break;
                    case 4:
                        chars = {
                            tl: "╭",
                            tr: "╮",
                            bl: "╰",
                            br: "╯",
                            h: "─",
                            v: "│"
                        };
                        break;
                    default:
                        return "";
                    }

                    // 2. Calculate inside width (accounting for left and right borders)
                    var innerW = Math.max(0, root.w - 2);
                    var innerH = Math.max(0, root.h - 2);

                    // 3. Build Top Border (Header)
                    var topBorder = chars.tl;
                    if (header.w > 0) {
                        var headOffset = Math.max(0, root.header.offset);
                        var leftFill = Math.min(innerW, headOffset);
                        var rightFill = Math.max(0, innerW - leftFill - header.w);

                        topBorder += safeRepeat(chars.h, leftFill) + safeRepeat(" ", Math.min(innerW - leftFill, header.w)) + safeRepeat(chars.h, rightFill);
                    } else {
                        topBorder += safeRepeat(chars.h, innerW);
                    }
                    topBorder += chars.tr + "\n";

                    // 4. Build Middle Rows
                    var middleRow = chars.v + safeRepeat(" ", innerW) + chars.v + "\n";
                    var middleSection = safeRepeat(middleRow, innerH);

                    // 5. Build Bottom Border (Footer)
                    var bottomBorder = chars.bl;
                    if (footer.w > 0) {
                        var footOffset = Math.max(0, root.footer.offset);
                        var leftFillFoot = Math.min(innerW, footOffset);
                        var rightFillFoot = Math.max(0, innerW - leftFillFoot - footer.w);

                        bottomBorder += safeRepeat(chars.h, leftFillFoot) + safeRepeat(" ", Math.min(innerW - leftFillFoot, footer.w)) + safeRepeat(chars.h, rightFillFoot);
                    } else {
                        bottomBorder += safeRepeat(chars.h, innerW);
                    }
                    bottomBorder += chars.br;

                    return topBorder + middleSection + bottomBorder;
                }
            }

            CellText {
                id: header
                x: Cell.w(Math.max(root.header.offset, 0) + 1)
                anchors.top: parent.top
                text: root.header.text
                preferedW: text == "" || text.length < root.w - 2 - Math.max(root.header.offset, 0) ? 0 : root.w - 2 - Math.max(root.header.offset, 0)
                font: root.header.font
            }
            CellText {
                id: footer
                x: Cell.w(Math.max(root.footer.offset, 0) + 1)
                anchors.bottom: parent.bottom
                text: root.footer.text
                preferedW: text == "" || text.length < root.w - 2 - Math.max(root.footer.offset, 0) ? 0 : root.w - 2 - Math.max(root.footer.offset, 0)
                font: root.footer.font
            }
        }
    }

    Loader {

        active: (root.visible || !root.optimizeMemory) && root.optimize

        sourceComponent: Cells {
            id: border_optimize

            w: root.w
            h: root.h

            x: -Cell.w(1)
            y: -Cell.h(1)

            grid: root.grid

            color: root.color

            layer.enabled: true

            Rectangle {

                implicitWidth: Cell.w(root.w - 1) + border.width
                implicitHeight: Cell.h(root.h - 1) + border.width

                x: (Cell.w(1) - border.width) / 2
                y: (Cell.h(1) - border.width) / 2

                border {
                    width: {
                        switch (root.border.type) {
                        case 1:
                            return 1 * Cell.border_width;
                        case 2:
                            return 2 * Cell.border_width;
                        case 3:
                            return 3 * Cell.border_width;
                        case 4:
                            return 1 * Cell.border_width;
                        }
                        return 1;
                    }
                    color: root.border.color
                }

                color: "transparent"
            }

            Rectangle {

                visible: root.border.type == 3

                implicitWidth: Cell.w(root.w - 1) + border.width
                implicitHeight: Cell.h(root.h - 1) + border.width

                x: (Cell.w(1) - border.width) / 2
                y: (Cell.h(1) - border.width) / 2

                border {
                    width: Cell.border_width
                    color: root.color
                }

                color: "transparent"
            }

            CellText {
                visible: root.header.text.trim() != ""
                x: Cell.w(Math.max(root.header.offset, 0) + 1)
                text: root.header.text
                color: root.header.color
                font: root.header.font
                preferedW: Math.min(root.contentW - Math.abs(root.header.offset), text.length)
                bg: root.color
            }

            CellText {
                visible: root.footer.text.trim() != ""
                x: Cell.w(Math.max(root.footer.offset, 0) + 1)
                y: Cell.h(root.h - 1)
                text: root.footer.text
                color: root.footer.color
                font: root.footer.font
                preferedW: Math.min(root.contentW - Math.abs(root.footer.offset), text.length)
                bg: root.color
            }
        }
    }

    Rectangle {
        id: content

        anchors.fill: parent

        color: "transparent"
    }
}
