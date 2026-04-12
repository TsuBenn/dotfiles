import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property int w: 1

    property int type: 0
    property int padding: 0

    component Type: Item {
        property string text: ""
        property int padding: 1
        property int offset: 0
        property bool centered: true
        property color color: Colors.fgBase
    }

    property Type title: Type {}

    property color color: Colors.fgSubtle
    property color bg: Colors.bgSurface

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(1)

    CellText {

        color: root.color

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
            bg: root.bg
            color: root.title.color

        }

    }

}
