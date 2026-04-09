pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    required property var box

    spacing: 0

    Cells {

        w: root.box.contentW
        h: 1

        color: "transparent"

        RowLayout {

            spacing: 0

            CellText {

                text: " "

            }

            CellButton {

                text: "<"
                fg: Colors.fgBase
                color: Colors.bgOverlay

                onPressed: {
                    root.box.view = "main"
                }

            }

            CellText {

                text: "  WiFi"
                font: Cell.fontB

            }

        }

        CellButton {

            anchors.right: parent.right
            anchors.rightMargin: Cell.w(1)

            text: "Refresh"
            fg: [Colors.fgBase, Colors.bgSurface]
            color: [Colors.bgOverlay, Colors.fgBase]

            onPressed: {
                if (WifiInfo.scan() == 1) {
                    console.log("slow down dude!")
                }
            }

        }

    }

    CellSeparator {

        w: root.box.contentW

    }

    CellList {

        id: list

        w: root.box.contentW
        h: root.box.contentH - 2

        model: WifiInfo.wifi_scan

        item: Cells {

            required property string name

            w: list.contentW
            h: 1

            color: "transparent"

            CellText {

                text: parent.name
                preferedW: parent.w

            }

        }

    }

}
