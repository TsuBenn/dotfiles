import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    property int id: 0
    property string prompt: ""
    property string description: ""
    property bool return_password: false

    w: 40
    h: Cell.wCount(layout.implicitHeight) + 2

    Connections {
        target: AuthInfo
        function onPrompted(prompt: string, description: string, return_password: bool, id: int) {
            root.prompt = prompt
            root.description = description
            PopupManager.open(root.name, false)
        }
    }

    Cells {

        w: root.w
        h: root.h

        CellBox {

            id: box

            w: root.w
            h: root.h

            ColumnLayout {

                id: layout

                spacing: 0

                CellText {

                    id: title

                    Layout.leftMargin: Cell.w(1)

                    text: root.prompt
                    preferedW: box.contentW - 2
                    centered: true
                    color: Colors.secondary

                }

                CellSeparator {
                    w: root.w - 2
                    color: Colors.accentStrong
                }

                CellText {

                    id: context

                    visible: text.length > 0

                    Layout.leftMargin: Cell.w(1)

                    text: root.description
                    color: Colors.fgDim
                    preferedW: box.contentW - 2

                }

            }

        }

    }

}
