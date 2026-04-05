import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

RowLayout {

    spacing: Cell.w(0)

    Repeater {

        model: 5

        delegate: Cells {

            id: wb

            required property int index

            property bool isActive: HyprInfo.focusedworkspace == wb.index
            property int winCount: HyprInfo.windowCount(wb.index) 

            w: wb_text.text.length
            h: 1

            Component.onCompleted: {
                wb.index += 1
            }


            color: wb.isActive ? Colors.accentStrong : Colors.bgOverlay

            CellText {
                id: wb_text
                text: wb.isActive ? (wb.winCount ? ` ${wb.index} ` : ` • `) : (wb.winCount ? ` ${wb.index} ` : ` • `)
                font: wb.isActive ? Cell.fontB : Cell.font
                color: wb.isActive ? Colors.fgBase : Colors.fgSubtle
            }

            MouseArea {
                anchors.fill: parent

                onPressed: {
                    HyprInfo.switchWorkspace(wb.index)
                }
            }
        }

    }

    Cells {
        visible: HyprInfo.specialworkspaces?.length ?? false
        w: 1
        h: 1
        color: "transparent"

        CellText {
            text: " "
            font: Cell.font
            color: Colors.fgBase
        }
    }

    Repeater {

        model: HyprInfo.specialworkspaces

        delegate: Cells {

            id: spwb

            required property int id 
            required property string name 

            Component.onCompleted: {
                name = name.match(/special:(.*)/)?.[1]
            }

            property bool isActive: HyprInfo.focusedspecial == spwb.id

            w: spwb_text.text.length
            h: 1

            color: spwb.isActive ? Colors.secondary : Colors.bgOverlay

            CellText {
                id: spwb_text
                text: spwb.isActive ? ` ${spwb.name} ` : ` ${spwb.name} `
                font: spwb.isActive ? Cell.fontB : Cell.font
                color: spwb.isActive ? Colors.bgBase : Colors.fgSubtle
            }

            MouseArea {
                anchors.fill: parent

                onPressed: {
                    HyprInfo.switchWorkspace(spwb.name)
                }
            }
        }

    }

}
