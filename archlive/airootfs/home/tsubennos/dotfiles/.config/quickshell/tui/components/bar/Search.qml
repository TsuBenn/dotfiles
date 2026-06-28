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
            PopupManager.toggle("launcher")
        }
    }

}
