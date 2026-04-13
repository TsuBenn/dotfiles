import qs.components.bar
import qs.components.popups
import qs.modules
import qs.config
import qs.services

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Layouts
import QtQuick

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {

            id: root


            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "bar"

            required property var modelData

            property bool shield: false

            screen: modelData

            property string screen_name: screen.name
            property var monitor: HyprInfo.monitors[screen_name] != undefined ? HyprInfo.monitors[screen_name] : {"width": 1920, "height": 1080}

            property HyprlandMonitor monitorObject

            Component.onCompleted: {
                PopupManager.opened.connect((name) => {
                    root.shield = true
                })
                PopupManager.closed.connect((name) => {
                    if (name == "") root.shield = false
                })
                DropdownManager.opened.connect((name) => {
                    ContextMenuManager.hide()
                    root.shield = true
                })
                DropdownManager.closed.connect((name) => {
                    if (PopupManager.active_popups.length > 0) return
                    root.shield = false
                })
                ContextMenuManager.opened.connect((name) => {
                    root.shield = true
                })
                ContextMenuManager.closed.connect((name) => {
                    if (PopupManager.active_popups.length > 0) return
                    root.shield = false
                })
                SystemInfo.lowBattery.connect((percent) => {
                    if (percent == 20) {
                        NotificationsInfo.send("System", "", "Low Battery", "20% battery remaining - plug in soon!", 0)
                    } else if (percent == 10) {
                        NotificationsInfo.send("System", "", "Low Battery!", "10% battery remaining - best to plug in now!", 1)
                    } else if (percent == 5) {
                        NotificationsInfo.send("System", "", "LOW BATTERY!", "5% battery remaining - plug in now!", 2)
                    }
                })
                for (const m of Hyprland.monitors.values) {
                    if (m.name == screen.name) {
                        monitorObject = m
                    }
                }
            }

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Cell.h(1)

            color: Colors.bgSurface

            Item {

                anchors.fill: parent

                RowLayout {

                    spacing: 0

                    Workspaces {
                        id: workspaces
                    }

                    CellText {
                        visible: window_title.text
                        text: "│ "
                        color: Colors.fgSubtle
                    }

                    CellText {

                        id: window_title

                        property string wTitle: HyprInfo.focusedwindow.title
                        property string wClass: HyprInfo.focusedwindow.class

                        preferedW: Cell.wCount(root.width/2-clock.implicitWidth/2-system.implicitWidth-workspaces.implicitWidth) - 10

                        text: `${wClass}`
                        font: Cell.font
                        color: Colors.fgBase

                    }

                }

                System {
                    id: system
                    anchors.right: clock.left
                    anchors.rightMargin: Cell.w(2)
                }

                Clock {
                    id: clock
                    x: Cell.centerWCell(implicitWidth,root.width)
                }

                MediaPlayer {
                    id: media_player
                    anchors.left: clock.right
                    anchors.leftMargin: Cell.w(2)
                }

                RowLayout {

                    x: Cell.alignRightWCell(implicitWidth, root.width)

                    spacing: Cell.w(0)

                    Volume {}

                    CellText {
                        text: " "
                    }

                    ControlPanel {}

                    CellText {
                        text: " "
                    }

                    Search {
                        id: search
                    }

                }

                MouseArea {
                    visible: context_menu.visible

                    anchors.fill: parent

                    onPressed: {
                        ContextMenuManager.hide()
                        DropdownManager.hide()
                    }
                }

            }

            PanelWindow {

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "popups"

                implicitWidth: root.monitor.width
                implicitHeight: root.monitor.height

                visible: true

                focusable: true

                color: "transparent"

                mask: Region {
                    item: notif
                }

                NotificationsPopup {

                    id: notif

                    cellX: Cell.wCount(Cell.alignRightWCell(implicitWidth, root.monitor.width)) + 1
                    cellY: 2

                }

            }

            PanelWindow {

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "popups"

                implicitWidth: root.monitor.width
                implicitHeight: root.monitor.height

                visible: true

                focusable: root.shield

                color: "transparent"

                mask: Region {
                    item: shield
                }

                Item {

                    id: shield

                    property bool mouse_check: false

                    anchors.topMargin: root.implicitHeight
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.left: parent.left

                    implicitHeight: root.shield ? root.monitor.height : 0

                    MouseControl {

                        anchors.fill: parent

                        onPressed: {
                            PopupManager.close()
                        }
                    }

                    Popups {
                        id: popups
                        monitor: root.monitor
                    }

                    MouseControl {

                        visible: context_menu.visible || dropdown.visible

                        anchors.fill: parent

                        onPressed: {
                            ContextMenuManager.hide()
                            DropdownManager.hide()
                        }
                    }

                    CellDropdownMenu {
                        id: dropdown
                        monitor: root.monitor
                    }

                    CellContextMenu {
                        id: context_menu
                        monitor: root.monitor
                    }

                }

            }

        }

    }
}
