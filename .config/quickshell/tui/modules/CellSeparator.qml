import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property int w: 1

    property int type: 0
    property int padding: 0

    property color color: Colors.fgSubtle

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

    }

}
