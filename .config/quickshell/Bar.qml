pragma ComponentBehavior:Bound 

import qs.modules.common
import qs.modules.homepanel
import qs.services
import qs.assets

import Quickshell
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
                    text: `CPU: ${SystemInfo.cpuusage}% - GPU: ${SystemInfo.gpuusage}% - RAM: ${SystemInfo.ktoG(SystemInfo.memused)}GB of ${SystemInfo.ktoG(SystemInfo.memtotal)}GB - SWAP: ${SystemInfo.ktoM(SystemInfo.swapused)}MB of ${SystemInfo.ktoM(SystemInfo.swaptotal)}MB | ${SystemInfo.onbattery ? "Battery: " + SystemInfo.battery + " of " + SystemInfo.batteryhealth + " (" + SystemInfo.batterystate + ")" : "PSU"}`

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

            PanelWindow {

                implicitWidth: SystemInfo.monitorwidth

                anchors {
                    top: true
                    left: true
                    right: true
                }

                margins {
                    top: 40 * !Hyprland.focusedWorkspace.hasFullscreen
                }

                implicitHeight: bar.screenRadius*2

                Rectangle {

                    id: bgCorner

                    anchors.fill: parent

                    color: Color.bgSurface

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: topCornerMask
                        invert: true
                    }
                    
                }

                Rectangle {

                    id: topCornerMask

                    visible: false

                    anchors.fill: parent
                    color: "white"

                    topLeftRadius: bar.screenRadius
                    topRightRadius: bar.screenRadius
                }

                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "screenCorners"
                mask: Region {
                    item: null
                }
                
            }
            PanelWindow {

                implicitWidth: SystemInfo.monitorwidth

                anchors {
                    bottom: true
                    left: true
                    right: true
                }
                implicitHeight: bar.screenRadius*2

                Rectangle {
                    anchors.fill: parent

                    color: Color.bgSurface

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: bottomCornerMask
                        invert: true
                    }
                    
                }

                Rectangle {

                    id: bottomCornerMask

                    visible: false

                    anchors.fill: parent
                    color: "white"

                    bottomLeftRadius: bar.screenRadius
                    bottomRightRadius: bar.screenRadius
                }

                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "screenCorners"
                mask: Region {
                    item: null
                }
                
            }
        }

    }
}
