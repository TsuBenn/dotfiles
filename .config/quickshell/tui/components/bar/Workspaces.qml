import qs.config
import qs.services

import QtQuick.Layouts
import QtQuick

RowLayout {

    spacing: Cell.w(0)

    Repeater {

        model: 5

        delegate: Rectangle {

            id: wb

            required property int index

            property bool isActive: HyprInfo.focusedworkspace == wb.index
            property int winCount: HyprInfo.windowCount(wb.index) 

            implicitWidth: Cell.w(wb_text.text.length)
            implicitHeight: Cell.h(1)

            Component.onCompleted: {
                wb.index += 1
            }


            color: wb.isActive ? Colors.accentStrong : Colors.bgOverlay

            Text {
                id: wb_text
                text: wb.isActive ? (wb.winCount ? `  ${wb.index}  ` : `  •  `) : (wb.winCount ? ` ${wb.index} ` : ` • `)
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

    Rectangle {
        visible: HyprInfo.specialworkspaces?.length ?? false
        implicitWidth: Cell.w(2)
        implicitHeight: Cell.h(1)
        color: "transparent"

        Text {
            text: "  "
            font: Cell.font
            color: Colors.fgBase
        }
    }

    Repeater {

        model: HyprInfo.specialworkspaces

        delegate: Rectangle {

            id: spwb

            required property int id 
            required property string name 

            Component.onCompleted: {
                name = name.match(/special:(.*)/)?.[1]
            }

            property bool isActive: HyprInfo.focusedspecial == spwb.id

            implicitWidth: Cell.w(spwb_text.text.length)
            implicitHeight: Cell.h(1)

            color: spwb.isActive ? Colors.secondary : Colors.bgOverlay

            Text {
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
