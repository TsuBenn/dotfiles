import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    w: 70
    h: Cell.hCount(layout.implicitHeight) + 1

    CellBox {

        w: root.w + 2
        h: root.h + 2

        ColumnLayout {

            id: layout

            property string current: Colors.current
            property var colorObject: Colors.colors[current]

            spacing: 0

            Cells {

                w: root.w
                h: 10

                color: Colors.bgSurface

            }

            CellBox {

                Layout.leftMargin: Cell.w(1)
                Layout.topMargin: Cell.h(1)

                border.type: 4

                w: root.w
                h: 3

            }

        }

    }

}
