import qs.config
import qs.modules
import qs.services

import QtQuick

CellPopup {
    id: root

    w: 48
    h: 20

    Cells {

        w: root.w
        h: root.h

        CellBox {
            id: box

            w: root.w
            h: root.h

        }
    }
}
