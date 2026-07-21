pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    property int w: 1
    property int h: 1

    property int type: 0
    property int padding: 0

    property bool vertical: false

    component Type: Item {
        property string text: ""
        property int padding: 1
        property int offset: 0
        property bool centered: true
        property color color: Colors.fgBase
        property font font: Cell.font
    }

    property Type title: Type {}

    property color color: Colors.fgSubtle
    property color bg: Colors.bgSurface

    property bool connectStart: false
    property bool connectEnd: false

    property bool isolate: true

    implicitWidth: Cell.w(vertical ? 1 : w)
    implicitHeight: Cell.h(vertical ? h : 1)

    property bool optimize: !SettingsInfo.purify

    Loader {

        active: (root.visible || !root.optimizeMemory) && !root.vertical && !root.optimize

        sourceComponent: CellText {

            visible: !root.vertical

            color: root.color

            pure: false
            lockPure: true

            cellIsolated: root.isolate

            text: {
                let char = " ";
                switch (root.type) {
                case 0:
                    char = "─";
                    break;
                case 1:
                    char = "━";
                    break;
                case 2:
                    char = "═";
                    break;
                case 3:
                    char = "-";
                    break;
                case 4:
                    char = "=";
                    break;
                }
                return " ".repeat(root.padding) + char.repeat(root.w - root.padding * 2) + " ".repeat(root.padding);
            }

            bg: root.bg

            CellText {

                visible: (root.connectStart || root.connectEnd) && !SettingsInfo.purify

                x: -Cell.w(1)

                cellIsolated: root.isolate

                pure: false
                lockPure: true

                text: {
                    let charStart = " ";
                    let charEnd = " ";
                    switch (root.type) {
                    case 0:
                        charStart = "╶";
                        break;
                    case 1:
                        charStart = "╺";
                        break;
                    case 2:
                        charStart = " ";
                        break;
                    case 3:
                        charStart = " ";
                        break;
                    case 4:
                        charStart = " ";
                        break;
                    }
                    switch (root.type) {
                    case 0:
                        charEnd = "╴";
                        break;
                    case 1:
                        charEnd = "╸";
                        break;
                    case 2:
                        charEnd = " ";
                        break;
                    case 3:
                        charEnd = " ";
                        break;
                    case 4:
                        charEnd = " ";
                        break;
                    }
                    return (root.connectStart ? charStart : " ") + " ".repeat(Math.max(root.w, 0)) + (root.connectEnd ? charEnd : " ");
                }
                bg: root.bg
                color: root.color
            }

            CellText {

                x: root.title.centered ? Cell.centerWCell(implicitWidth, parent.implicitWidth) : Cell.w(root.title.offset)

                text: root.title.text == "" ? "" : " ".repeat(root.title.padding) + root.title.text + " ".repeat(root.title.padding)
                font: root.title.font
                bg: root.bg
                color: root.title.color
                clip: true
                cellIsolated: root.isolate
            }
        }
    }

    Loader {

        active: (root.visible || !root.optimizeMemory) && root.vertical && !root.optimize

        sourceComponent: CellText {

            pure: false
            lockPure: true
            cellIsolated: root.isolate

            text: {
                let type = "│";

                switch (root.type) {
                case 0:
                    type = "│";
                    break;
                case 1:
                    type = "┃";
                    break;
                case 2:
                    type = "║";
                    break;
                case 3:
                    type = "|";
                    break;
                }

                const lines = [..." ".repeat(root.padding), ...type.repeat(root.h - root.padding * 2), ..." ".repeat(root.padding)];

                return lines.join("\n");
            }
            bg: root.bg
            color: root.color

            CellText {

                visible: (root.connectStart || root.connectEnd) && !SettingsInfo.purify

                y: -Cell.h(1)

                pure: false
                lockPure: true
                cellIsolated: root.isolate

                text: {
                    let charStart = " ";
                    let charEnd = " ";
                    switch (root.type) {
                    case 0:
                        charStart = "╷";
                        break;
                    case 1:
                        charStart = "╻";
                        break;
                    case 2:
                        charStart = " ";
                        break;
                    case 3:
                        charStart = " ";
                        break;
                    case 4:
                        charStart = " ";
                        break;
                    }
                    switch (root.type) {
                    case 0:
                        charEnd = "╵";
                        break;
                    case 1:
                        charEnd = "╹";
                        break;
                    case 2:
                        charEnd = " ";
                        break;
                    case 3:
                        charEnd = " ";
                        break;
                    case 4:
                        charEnd = " ";
                        break;
                    }
                    return (root.connectStart ? charStart : " ") + "\n" + " \n".repeat(Math.max(root.h, 0)) + (root.connectEnd ? charEnd : " ");
                }
                color: root.color
            }
        }
    }

    Loader {
        active: (root.visible || !root.optimizeMemory) && !root.vertical && root.optimize

        sourceComponent: Cells {
            w: root.w
            h: 1

            color: root.bg

            ColumnLayout {

                x: (root.connectStart ? -Cell.w(1) / 2 : 0) + Cell.w(root.padding)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Repeater {

                    model: root.type == 2 ? 2 : 1

                    delegate: Rectangle {
                        implicitHeight: {
                            switch (root.type) {
                            case 0:
                                return 1 * Cell.border_width;
                            case 1:
                                return 2 * Cell.border_width;
                            case 2:
                                return 1 * Cell.border_width;
                            }
                        }
                        implicitWidth: Cell.w(root.w) + (root.connectStart ? Cell.w(1) / 2 : 0) + (root.connectEnd ? Cell.w(1) / 2 : 0) - Cell.w(root.padding * 2)
                        color: root.color
                    }
                }
            }

            CellText {
                visible: root.title.text.trim() != ""
                x: Math.max(root.title.centered ? Cell.centerWCell(implicitWidth, parent.implicitWidth) : Cell.w(root.title.offset), 0)
                text: " ".repeat(root.title.padding) + root.title.text + " ".repeat(root.title.padding)
                color: root.title.color
                font: root.title.font
                preferedW: Math.min(text.length, root.w - Math.abs(Cell.wCount(x)))
                bg: root.bg
            }
        }
    }

    Loader {
        active: (root.visible || !root.optimizeMemory) && root.vertical && root.optimize

        sourceComponent: Cells {
            w: 1
            h: root.h

            color: root.bg

            RowLayout {

                y: (root.connectStart ? -Cell.h(1) / 2 : 0) + Cell.h(root.padding)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                Repeater {

                    model: root.type == 2 ? 2 : 1

                    delegate: Rectangle {
                        implicitWidth: {
                            switch (root.type) {
                            case 0:
                                return 1 * Cell.border_width;
                            case 1:
                                return 2 * Cell.border_width;
                            case 2:
                                return 1 * Cell.border_width;
                            }
                        }
                        implicitHeight: Cell.h(root.h) + (root.connectStart ? Cell.h(1) / 2 : 0) + (root.connectEnd ? Cell.h(1) / 2 : 0) - Cell.h(root.padding * 2)
                        color: root.color
                    }
                }
            }
        }
    }
}
