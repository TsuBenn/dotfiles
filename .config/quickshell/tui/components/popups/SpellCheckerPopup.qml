import qs.config
import qs.modules
import qs.services

import QtQuick

CellPopup {

    w: Cell.wCount(box.implicitWidth) + 2
    h: Cell.hCount(box.implicitHeight) + 2


    CellBox {

        id: box

        w: 50
        h: 30

    }

}
