pragma ComponentBehavior: Bound

import qs.config 

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property real w
    property real h

    property bool grid: false
    property bool whole: true

    property color color: "white"
    property color color2: "lightgray"

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(h)

    Rectangle {
        implicitWidth: root.whole ? Cell.w(root.w) : Cell.w(root.w).toPrecision(1)
        implicitHeight: root.whole ? Cell.h(root.h) : Cell.h(root.h).toPrecision(1)

        color: root.color

        ColumnLayout {

            spacing: 0

            Repeater {
                model: root.h

                delegate: RowLayout {

                    id: yCell
                    required property int index

                    spacing: 0

                    Repeater {
                        model: root.w

                        delegate: Rectangle {

                            id: xCell
                            required property int index

                            implicitWidth: Cell.w(1)
                            implicitHeight: Cell.h(1)
                            color: root.grid && (yCell.index + xCell.index)%2 == 1 ? root.color2 : root.color
                        }
                    }
                } 
            }

        }

    }
}
