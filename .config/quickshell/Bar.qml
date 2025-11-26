pragma ComponentBehavior:Bound 

import qs.modules.common
import qs.modules.homepanel
import qs.services

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar

            required property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Auto

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 40

            RowLayout {

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.rightMargin: 5

                id: wrapper

                spacing: 5

                PillButton {
                    id: homebutton
                    text: SystemInfo.username

                    marquee: true

                    onReleased: {
                        homepanel.item.visible = !homepanel.item.visible
                    }
                }

            }


            IpcHandler {
                target: "homepanel"
                function toggle(): void {homepanel.item.visible = !homepanel.item.visible}
            }

            LazyLoader {id:homepanel; active: true; component: Homepanel {}}
        }



    }
}
