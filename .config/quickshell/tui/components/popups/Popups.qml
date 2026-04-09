import qs.components.popups.ControlPanel
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

    ControlPanelPopup {

        visible: PopupManager.isOpen("control_panel")

        x: Cell.wCount(root.monitor.width-Cell.w(w))
        y: 0

    }

}
