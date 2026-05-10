pragma ComponentBehavior: Bound

import qs.components.popups.ControlPanel
import qs.components.popups
import qs.config
import qs.modules
import qs.services

import Quickshell
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
            power_countdown.mode = mode
            power_countdown.count = count
            power_countdown.active = true
            PopupManager.open("power_countdown")
        })
    }

    CalendarPopup {

        id: calendar

        name: "calendar"

        cellX: Cell.wCount(root.monitor.width/2,"floor") - Math.floor(w/2)
        cellY: -1

    }

    MediaPlayerPopup {

        id: media_player

        name: "media_player"

        cellX: Cell.wCount(root.monitor.width/2,"floor") - Math.floor(w/2)
        cellY: -1

    }

    SystemPopup {

        id: system

        name: "system"

        cellX: Cell.wCount(root.monitor.width/2,"floor") - Math.floor(w/2)
        cellY: -1

    }

    WallpaperPopup {

        id: wallpaper

        name: "wallpaper"

        cellX: Cell.wCount(root.monitor.width/2) - Math.round(w/2)
        cellY: HyprInfo.windowCount(HyprInfo.focusedworkspace) > 0 ? Cell.hCount(root.monitor.height/2,"floor") - Math.floor(h/2) - 3 : Cell.hCount(root.monitor.height,"floor") - Math.floor(h) - 4

    }

    PowerPopup {

        id: power

        name: "power"

        cellX: Cell.wCount(root.monitor.width/2) - Math.round(w/2)
        cellY: Cell.hCount(root.monitor.height/2,"floor") - Math.round(h/2) - 4

    }

    PowerCountdownPopup {

        id: power_countdown

        name: "power_countdown"

        cellX: Cell.wCount(root.monitor.width/2) - Math.round(w/2)
        cellY: Cell.hCount(root.monitor.height/2,"floor") - Math.round(h/2) - 2

    }

    ControlPanelPopup {

        name: "control_panel"

        cellX: Cell.wCount(root.monitor.width-Cell.w(w))
        cellY: -1

    }

    LauncherPopup {

        id: launcher

        name: "launcher"

        cellX: Cell.wCount(root.monitor.width/2) - Math.round(w/2)
        cellY: Cell.hCount(root.monitor.height/2,"floor") - Math.round(h/2) - 3

    }

    QuickMenuPopup {

        id: quick_menu

        monitor: root.monitor

        Component.onCompleted: {
            HyprInfo.cursorPos.connect((x, y) => {
                quick_menu.cellX = Cell.wCount(x) - w/2
                quick_menu.cellY = Cell.hCount(y) - h/2 - 2
            })
        }

        name: "quick_menu"

        cellX: 0
        cellY: 0

    }

}
