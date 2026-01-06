pragma ComponentBehavior:Bound 

import qs.modules.common
import qs.modules.homepanel
import qs.services
import qs.assets

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

                Text {
                    text: DateTime.hour12 + ":" + DateTime.minute + ":" + DateTime.second + " " + DateTime.ampm
                    font.family: Fonts.system
                    font.pointSize: 12
                    font.weight: 800
                }

                Text {
                    text: " | "
                    font.family: Fonts.system
                    font.pointSize: 12
                    font.weight: 800
                }

                Text {
                    text: `CPU: ${SystemInfo.cpuusage}% - GPU: ${SystemInfo.gpuusage}% - RAM: ${SystemInfo.ktoG(SystemInfo.memused)}GB of ${SystemInfo.ktoG(SystemInfo.memtotal)}GB - SWAP: ${SystemInfo.ktoM(SystemInfo.swapused)}MB of ${SystemInfo.ktoM(SystemInfo.swaptotal)}MB | ${SystemInfo.onbattery ? "Battery: " + SystemInfo.battery + " of " + SystemInfo.batteryhealth + " (" + SystemInfo.batterystate + ")" : "PSU (Which means " + SystemInfo.battery + " powers lol)"}`
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
        }



    }
}
