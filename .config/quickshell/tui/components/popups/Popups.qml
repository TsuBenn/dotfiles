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

        cellX: Cell.wCount(root.monitor.width/2,"floor") - Math.floor(w/2) - 1
        cellY: 0

    }

    MediaPlayerPopup {

        id: media_player

        name: "media_player"

        cellX: Cell.wCount(root.monitor.width/2,"floor") - Math.floor(w/2) - 1
        cellY: 0

    }

    SystemPopup {

        id: system

        name: "system"

        cellX: Cell.wCount(root.monitor.width/2,"floor") - Math.floor(w/2) - 1
        cellY: 0

    }

    ColorPopup {

        id: color

        name: "color"

        cellX: Cell.wCount(root.monitor.width/2,"floor") - Math.floor(w/2) - 1
        cellY: Cell.hCount(root.monitor.height/2,"floor") - Math.round(h/2) - 1

    }

    WallpaperPopup {

        id: wallpaper

        name: "wallpaper"

        cellX: Cell.wCount(root.monitor.width/2) - Math.round(w/2) - 1
        cellY: HyprInfo.windowCount(HyprInfo.focusedworkspace) > 0 ? Cell.hCount(root.monitor.height/2,"floor") - Math.floor(h/2) - 1 : Cell.hCount(root.monitor.height,"floor") - Math.floor(h) - 3

    }

    PowerPopup {

        monitor: root.monitor

        id: power

        name: "power"

    }

    PowerCountdownPopup {

        id: power_countdown

        name: "power_countdown"

        cellX: Cell.wCount(root.monitor.width/2) - Math.round(w/2) - 1
        cellY: Cell.hCount(root.monitor.height/2,"floor") - Math.round(h/2) - 1

    }

    ControlPanelPopup {

        name: "control_panel"

        cellX: Cell.wCount(root.monitor.width-Cell.w(w))
        cellY: 0

    }

    LauncherPopup {

        id: launcher

        name: "launcher"

        cellX: Cell.wCount(root.monitor.width/2) - Math.round(w/2) - 1
        cellY: Cell.hCount(root.monitor.height/2,"floor") - Math.round(h/2) - 1

    }


    QuickMenuPopup {

        id: quick_menu

        monitor: root.monitor

        Component.onCompleted: {
            HyprInfo.cursorPos.connect((x, y) => {
                quick_menu.cellX = Cell.wCount(x) - w/2
                quick_menu.cellY = Cell.hCount(y) - h/2 - 1
            })
        }

        name: "quick_menu"

        cellX: 0
        cellY: 0

    }

}
