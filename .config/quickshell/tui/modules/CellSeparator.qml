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

    implicitWidth: Cell.w(vertical ? 1 : w)
    implicitHeight: Cell.h(vertical ? h : 1)

    Loader {

        active: (root.visible || !root.optimizeMemory) && !root.vertical

        sourceComponent: CellText {

            visible: !root.vertical

            color: root.color

            clip: true

            text: {
                let char = " "
                switch (root.type) {
                    case 0: char = "─"; break;
                    case 1: char = "━"; break;
                    case 2: char = "═"; break;
                    case 3: char = "-"; break;
                    case 4: char = "="; break;
                }
                return " ".repeat(root.padding) + char.repeat(root.w - root.padding*2) + " ".repeat(root.padding)
            }

            bg: root.bg

            CellText {

                x: root.title.centered ? Cell.centerWCell(implicitWidth, parent.implicitWidth) : Cell.w(root.title.offset)

                text: root.title.text == "" ? "" : " ".repeat(root.title.padding) + root.title.text + " ".repeat(root.title.padding)
                font: root.title.font
                bg: root.bg
                color: root.title.color
                clip: true

            }

        }
    }

    Loader {

        active: (root.visible || !root.optimizeMemory) && root.vertical

        sourceComponent: CellText {

            clip: true

            text: {

                let type = "│"

                switch (root.type) {
                    case 0: type = "│"; break;
                    case 1: type = "┃"; break;
                    case 2: type = "║"; break;
                    case 3: type = "|"; break;
                }

                const lines = [..." ".repeat(root.padding), ...type.repeat(root.h - root.padding*2), ..." ".repeat(root.padding)]

                return lines.join("\n")

            }
            bg: root.bg
            color: root.color

        }

    }

}
