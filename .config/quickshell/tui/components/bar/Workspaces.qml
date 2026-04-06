import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

RowLayout {

    spacing: Cell.w(0)

    Repeater {

        model: 5

        delegate: CellButton {

            required property int index

            property bool isActive: HyprInfo.focusedworkspace == index
            property int winCount: HyprInfo.windowCount(index) 

            Component.onCompleted: {
                index += 1
            }

            text: isActive ? (winCount ? `${index}` : `•`) : (winCount ? `${index}` : `•`)
            font: isActive ? Cell.fontB : Cell.font
            fg: isActive ? Colors.fgBase : Colors.fgSubtle
            color: isActive ? Colors.accentStrong : Colors.bgOverlay

            onPressed: (button) => {
                if (button != "L") return
                HyprInfo.switchWorkspace(index)
            }
        }

    }

    CellText {
        visible: HyprInfo.specialworkspaces?.length > 0
        text: " "
        font: Cell.font
        color: Colors.fgDim
    }

    Repeater {

        model: HyprInfo.specialworkspaces

        delegate: CellButton {

            required property int id 
            required property string name 

            Component.onCompleted: {
                name = name.match(/special:(.*)/)?.[1]
            }

            property bool isActive: HyprInfo.focusedspecial == id

            text: isActive ? `${name}` : `${name}`
            font: isActive ? Cell.fontB : Cell.font
            fg: isActive ? Colors.bgBase : Colors.fgSubtle

            color: isActive ? Colors.secondary : Colors.bgOverlay

            onPressed: (button) => {
                if (button != "L") return
                HyprInfo.switchWorkspace(name)
            }

        }

    }

}
