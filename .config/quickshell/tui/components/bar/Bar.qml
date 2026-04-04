import qs.components.bar
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

            implicitHeight: Cell.h(1.5) + 1

            color: Colors.bgSurface

            RowLayout {

                y: Cell.h(0.25)
                x: Cell.w(0.5)

                spacing: 0

                Workspaces {}

                Rectangle {

                    visible: window_title.text

                    implicitWidth: Cell.w(4)
                    implicitHeight: Cell.h(1)

                    color: "transparent"

                    Text {
                        text: " || "
                        font: Cell.fontB
                        color: Colors.fgSubtle
                    }
                }

                Rectangle {
                    implicitHeight: Cell.h(1)
                    implicitWidth: Cell.w(1)

                    color: "transparent"

                    Text {

                        id: window_title

                        property string wTitle: HyprInfo.focusedwindow.title
                        property string wClass: HyprInfo.focusedwindow.class

                        width: Cell.w(30)

                        elide: Qt.ElideRight

                        text: `${wClass}`
                        font: Cell.font
                        color: Colors.fgBase
                    }
                }


            }

            System {
                y: Cell.h(0.25)

                anchors.right: clock.left
                anchors.rightMargin: Cell.w(2)
            }

            Clock {
                id: clock
                y: Cell.h(0.25)
                anchors.horizontalCenter: parent.horizontalCenter
            }

            MediaPlayer {
                y: Cell.h(0.25)

                anchors.left: clock.right
                anchors.leftMargin: Cell.w(2)
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                implicitHeight: 1

                color: Colors.fgDim
            }

        }

    }
}
