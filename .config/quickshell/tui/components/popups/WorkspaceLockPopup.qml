import qs.config
import qs.modules
import qs.services

import QtQuick

CellPopup {
    id: root

    visible: false

    Connections {
        target: HyprInfo
        function onFocusedWorkspaceChanged() {
        console.log("bruh")
            root.visible = WorkspaceInfo.isLocked(HyprInfo.focusedWorkspace);
        }
    }

    implicitWidth: monitor.width
    implicitHeight: monitor.height

    Cells {
        w: Cell.wCount(root.implicitWidth, "ceil")
        h: Cell.hCount(root.implicitHeight, "ceil")
    }

    MouseControl {

        anchors.fill: parent

        onReleased: button => {
            if (button == "L") {
                root.close();
            }
        }
    }
}
