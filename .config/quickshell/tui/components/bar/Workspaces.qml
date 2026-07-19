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

            property bool isActive: HyprInfo.focusedWorkspace.id == index
            property int winCount: HyprInfo.clientCount(index)

            Component.onCompleted: {
                index += 1
            }

            text: isActive ? (winCount ? `${index}` : `•`) : (winCount ? `${index}` : `•`)
            font: isActive ? Cell.fontB : Cell.font
            fg: isActive ? Colors.onAccent : Colors.fgSubtle
            color: isActive ? Colors.accentStrong : Colors.bgOverlay

            onPressed: (button) => {
                if (button != "L") return
                HyprInfo.switchWorkspace(index)
            }
        }

    }

    CellText {
        visible: HyprInfo.specialWorkspaces.length > 0
        text: " "
        font: Cell.font
        color: Colors.fgDim
    }

    Repeater {

        model: HyprInfo.specialWorkspaces.length

        delegate: CellButton {

            required property int index
            property int id: HyprInfo.listSpecialWorkspaces()[index].id
            property string name: HyprInfo.listSpecialWorkspaces()[index].name

            Component.onCompleted: {
                name = name.match(/special:(.*)/)?.[1]
            }

            property bool isActive: HyprInfo.focusedSpecialWorkspace ? HyprInfo.focusedSpecialWorkspace.id == id : false

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
