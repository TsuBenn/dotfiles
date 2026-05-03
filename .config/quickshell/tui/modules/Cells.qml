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

    implicitWidth: Cell.w(whole ? Math.round(w) : w)
    implicitHeight: Cell.h(whole ? Math.round(h) : h)

    onWChanged: {
        if (w < 0) {
            w = 0
        }
    }
    onHChanged: {
        if (h < 0) {
            h = 0
        }
    }

    Rectangle {

        anchors.fill: parent

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
