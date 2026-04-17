import qs.config
import qs.modules

import QtQuick

CellButton {

    text: "\uf422"
    font: Cell.font

    fg: Colors.fgDim
    color: Colors.bgOverlay

    onPressed: (button) => {
        if (button == "L") {
            if (PopupManager.isOpen("launcher")) {
                PopupManager.close("launcher")
                return
            }
            PopupManager.open("launcher",false)
        }
    }

}
