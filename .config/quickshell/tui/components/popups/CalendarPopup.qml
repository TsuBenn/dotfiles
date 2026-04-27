pragma ComponentBehavior: Bound 

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    w: 50
    h: 10

    CellBox {

        id: box

        w: root.w + 2
        h: root.h + 2

        RowLayout {

            spacing: 0

            ColumnLayout {

                spacing: 0

                CellText {

                    text: `${DateTime.hour12}:${DateTime.minute} ${DateTime.ampm}`

                }

            }

        }

    }

}
