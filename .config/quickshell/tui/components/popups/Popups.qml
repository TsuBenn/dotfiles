import qs.components.popups.ControlPanel
import qs.components.popups
import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

Item {

    id: root

    property var monitor: {
        "width": 1920,
        "height": 1080,
    }

    Component.onCompleted: {
        PowerManager.called.connect((mode, count) => {
            power.mode = mode
            power.count = count
            power.active = true
            PopupManager.open("power")
        })
    }

    LauncherPopup {

        id: launcher

        name: "launcher"

        cellX: Cell.wCount(root.monitor.width/2) - Math.round(w/2)
        cellY: Cell.hCount(root.monitor.height/2,"floor") - Math.round(h*(1/2)) - 2

    }

    PowerPopup {

        id: power

        name: "power"

        cellX: Cell.wCount(root.monitor.width/2) - Math.round(w/2)
        cellY: Cell.hCount(root.monitor.height/2,"floor") - Math.round(h)

    }

    ControlPanelPopup {

        name: "control_panel"

        cellX: Cell.wCount(root.monitor.width-Cell.w(w))
        cellY: -1

    }

}
