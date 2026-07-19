pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

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

    implicitWidth: Cell.w(vertical ? 1 : w)
    implicitHeight: Cell.h(vertical ? h : 1)

    Loader {

        active: (root.visible || !root.optimizeMemory) && !root.vertical

        sourceComponent: CellText {

            visible: !root.vertical

            color: root.color

            pure: false
            lockPure: true

            cellIsolated: true

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

                visible: root.connectStart || root.connectEnd

                x: -Cell.w(1)

                cellIsolated: true

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
                cellIsolated: true
            }
        }
    }

    Loader {

        active: (root.visible || !root.optimizeMemory) && root.vertical

        sourceComponent: CellText {

            pure: false
            lockPure: true
            cellIsolated: true

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

                visible: root.connectStart || root.connectEnd

                y: -Cell.h(1)

                pure: false
                lockPure: true
                cellIsolated: true

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
}
