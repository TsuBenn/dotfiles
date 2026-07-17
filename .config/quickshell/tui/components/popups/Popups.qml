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
        "height": 1080
    }

    CalendarPopup {
        id: calendar

        name: "calendar"

        cellX: Cell.wCount(root.monitor.width / 2, "floor") - Math.floor(w / 2) - 1
        cellY: 0
    }

    MediaPlayerPopup {
        id: media_player

        name: "media_player"

        cellX: Cell.wCount(root.monitor.width / 2, "floor") - Math.floor(w / 2) - 1
        cellY: 0
    }

    SystemPopup {
        id: system

        name: "system"

        cellX: Cell.wCount(root.monitor.width / 2, "floor") - Math.floor(w / 2) - 1
        cellY: 0
    }

    SpellCheckerPopup {
        id: spell_checker

        name: "spell_checker"

        cellX: Cell.wCount(root.monitor.width / 2, "floor") - Math.floor(w / 2)
        cellY: Cell.hCount(root.monitor.height / 2, "floor") - Math.round(h / 2)
    }

    ColorPopup {
        id: color

        name: "color"

        cellX: Cell.wCount(root.monitor.width / 2, "floor") - Math.floor(w / 2)
        cellY: Cell.hCount(root.monitor.height / 2, "floor") - Math.round(h / 2)
    }

    WallpaperPopup {
        id: wallpaper

        monitor: root.monitor

        name: "wallpaper"

        cellX: Cell.wCount(root.monitor.width / 2) - Math.round(w / 2) - 1
        cellY: HyprInfo.windowCount(HyprInfo.focusedworkspace) > 0 ? Cell.hCount(root.monitor.height / 2, "floor") - Math.floor(h / 2) : Cell.hCount(root.monitor.height, "floor") - Math.floor(h) - 1
    }

    PowerPopup {
        id: power

        monitor: root.monitor

        name: "power"
    }

    ClipboardPopup {
        id: clipboard

        name: "clipboard"

        cellX: Cell.wCount(root.monitor.width / 2) - Math.round(w / 2) - 1
        cellY: Cell.hCount(root.monitor.height / 2, "floor") - Math.round(h / 2)
    }

    ControlPanelPopup {

        name: "control_panel"

        cellX: Cell.wCount(root.monitor.width - Cell.w(w))
        cellY: 0
    }

    EmojiPopup {
        id: emoji

        name: "emoji"

        cellX: Cell.wCount(root.monitor.width / 2) - Math.round(w / 2) - 1
        cellY: Cell.hCount(root.monitor.height / 2, "floor") - Math.round(h / 2)
    }

    LauncherPopup {
        id: launcher

        name: "launcher"

        cellX: Cell.wCount(root.monitor.width / 2) - Math.round(w / 2) - 1
        cellY: Cell.hCount(root.monitor.height / 2, "floor") - Math.round(h / 2)
    }

    PacmanPopup {
        id: pacman

        name: "pacman"

        cellX: Cell.wCount(root.monitor.width / 2) - Math.round(w / 2) - 1
        cellY: Cell.hCount(root.monitor.height / 2, "floor") - Math.round(h / 2)
    }

    QuickMenuPopup {
        id: quick_menu

        monitor: root.monitor

        name: "quick_menu"

        cellX: Cell.wCount(root.monitor.width / 2) - Math.round(w / 2) - 1
        cellY: Cell.hCount(root.monitor.height / 2, "floor") - Math.round(h / 2)
    }

    AuthPopup {
        id: auth

        monitor: root.monitor

        name: "auth"

        cellX: Cell.wCount(root.monitor.width / 2) - Math.round(w / 2)
        cellY: Cell.hCount(root.monitor.height / 2, "floor") - Math.round(h / 2)
    }

    ScreenshotPopup {
        id: screenshot

        monitor: root.monitor

        name: "screenshot"
    }

    MouseControl {
        implicitHeight: root.monitor.height
        implicitWidth: root.monitor.width

        propagateComposedEvents: true

        hoverEnabled: false

        onPressed: (button, event) => {
            TextFieldManager.unFocusAll();
            event.accepted = false;
        }

        onReleased: (button, event) => {
            TextFieldManager.unFocusAll();
            event.accepted = false;
        }

        onWheel: (button, event) => {
            event.accepted = false;
        }
    }
}
