import qs.components.popups.ControlPanel

import qs.config
import qs.services
import qs.modules

import Quickshell
import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    w: 50
    h: Cell.hCount(content.implicitHeight) + 2

    CellBox {

        id: box

        property string view: "main"

        onVisibleChanged: {
            view = "main"
        }

        w: root.w
        h: root.h

        ColumnLayout {

            id: content

            spacing: 0

            Main {

                visible: box.view == "main"
                box: box

            }

            Wifi {

                visible: box.view == "wifi"
                box: box

            }
        }



    }

}
