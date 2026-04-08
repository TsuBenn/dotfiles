import qs.config
import qs.services
import qs.modules

import Quickshell
import QtQuick

CellPopup {

    id: root

    w: 40
    h: 10

    x: Cell.wCount(1920-Cell.w(w))
    y: 0

    CellBox {

        w: root.w
        h: root.h

        CellText {

            text: ` Uptime: ${SystemInfo.uptime}`

        }

    }

}
