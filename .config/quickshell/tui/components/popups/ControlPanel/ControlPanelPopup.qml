import qs.components.popups.ControlPanel

import qs.config
import qs.services
import qs.modules

import Quickshell
import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    w: 40
    h: 10

    CellBox {

        id: box

        property string view: "main"

        w: root.w
        h: root.h

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
