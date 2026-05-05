pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Item {

    id: root

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

        active: root.visible || !SettingsInfo.optimizeMemory

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

            }

        }
    }

    Loader {
        active: root.visible || !SettingsInfo.optimizeMemory

        sourceComponent: ColumnLayout {

            visible: root.vertical

            spacing: 0

            Repeater {

                model: root.h

                delegate: CellText {

                    required property int index

                    clip: true

                    text: {

                        if (index <= root.padding-1 || index >= root.h-root.padding) {
                            return " "
                        }
                        switch (root.type) {
                            case 0: return "│"
                            case 1: return "┃"
                            case 2: return "║"
                            case 3: return "|"
                        }
                        return "│"

                    }

                }

            }

        }
    }

}
