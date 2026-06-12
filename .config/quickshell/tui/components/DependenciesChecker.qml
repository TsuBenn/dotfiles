import qs.config
import qs.modules
import qs.services

import Quickshell
import QtQuick
import QtQuick.Layouts

PanelWindow {

    visible: true

    property int w: 60
    property int h: 20

    width: Cell.w(w)
    height: Cell.h(h)

    color: Colors.bgSurface

    Cells {

        w: parent.w
        h: parent.h

        RowLayout {

            spacing: 0

        }

    }

}
