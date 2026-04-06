import qs.components.bar
import qs.modules
import qs.config
import qs.services

import Quickshell
import Quickshell.Hyprland
import QtQuick.Layouts
import QtQuick

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {

            id: root

            required property var modelData

            screen: modelData

            property string screen_name: screen.name
            property var monitor: HyprInfo.monitors[screen_name] != undefined ? HyprInfo.monitors[screen_name] : {"width": 1920, "height": 1080}

            property HyprlandMonitor monitorObject

            Component.onCompleted: {
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
                    x: Cell.toW(root.width/2 - implicitWidth/2)
                }

                MediaPlayer {
                    id: media_player
                    anchors.left: clock.right
                    anchors.leftMargin: Cell.w(2)
                }

                RowLayout {
                    x: Cell.toW(root.width - implicitWidth)

                    Volume {}
                }

            }

        }

    }
}
