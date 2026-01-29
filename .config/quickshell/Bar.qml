pragma ComponentBehavior:Bound 

import qs.modules.common
import qs.modules.homepanel
import qs.modules.bar
import qs.services
import qs.assets

import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData

            property int screenRadius: 20

            Behavior on screenRadius {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

            screen: modelData

            exclusionMode: ExclusionMode.Auto

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: -40 * Hyprland.focusedWorkspace.hasFullscreen
            }

            color: Color.bgSurface

            implicitHeight: 40

            RowLayout {

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.rightMargin: 5

                id: leftSide

                spacing: 5

                PillButton {

                    id: homebutton
                    text: SystemInfo.username

                    marquee: true

                    onReleased: {
                        homepanel.item.visible = !homepanel.item.visible
                    }
                }

                Workspaces {} 

            }

            RowLayout {

                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter

                id: center

                spacing: 5

                Text {
                    text: DateTime.hour12 + ":" + DateTime.minute + ":" + DateTime.second + " " + DateTime.ampm
                    color: Color.accentSoft
                    font.family: Fonts.system
                    font.pointSize: 12
                    font.weight: 800
                }
                Text {
                    text: " | "
                    color: Color.accentSoft
                    font.family: Fonts.system
                    font.pointSize: 12
                    font.weight: 800
                }
                Text {
                    text: HyprInfo.focusedwindow.title
                    Layout.preferredWidth: Math.min(implicitWidth,200)
                    color: Color.accentSoft
                    font.family: Fonts.system
                    font.pointSize: 12
                    font.weight: 800
                    elide: Text.ElideRight
                }
                Text {
                    text: " | "
                    color: Color.accentSoft
                    font.family: Fonts.system
                    font.pointSize: 12
                    font.weight: 800
                }
                Text {
                    text: SystemInfo.battery
                    color: Color.accentSoft
                    font.family: Fonts.system
                    font.pointSize: 12
                    font.weight: 800
                }

            }


            IpcHandler {
                target: "homepanel"
                function toggle(): void {homepanel.item.visible = !homepanel.item.visible}
            }

            LazyLoader {id:homepanel; active: true; component: Homepanel {}}

            ScreenCorners {}
        }

    }
}
