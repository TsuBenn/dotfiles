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

            focusable: true

            exclusionMode: ExclusionMode.Auto
            WlrLayershell.layer: WlrLayer.Overlay

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

            PopupWindow {
                anchor {
                    window: bar
                }
                implicitWidth: SystemInfo.monitorwidth
                implicitHeight: SystemInfo.monitorheight
                color: "transparent"
                visible: true
                mask: Region {
                    item: item
                }

                Item {

                    id: item

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right

                    implicitHeight: 31


                    RowLayout {

                        id: leftSide

                        anchors.topMargin: Math.round(31/2 - implicitHeight/2)
                        anchors.top: parent.top
                        anchors.left: parent.left

                        spacing: 5

                        PillButton {

                            id: homebutton
                            text: SystemInfo.username

                            marquee: true

                            bg_color: [
                                homepanel.item.visible ? Color.accentStrong : Color.transparent(Color.accentStrong,0),
                                homepanel.item.visible ? Color.accentStrong : Color.transparent(Color.accentStrong,0),
                                homepanel.item.visible ? "transparent" : Color.accentStrong,
                            ]

                            fg_color: [
                                homepanel.item.visible ? Color.textSecondary : Color.textPrimary,
                                homepanel.item.visible ? Color.textSecondary : Color.textPrimary,
                                homepanel.item.visible ? Color.textSecondary : Color.textSecondary,
                            ]

                            border_width: [
                                homepanel.item.visible ? 0 : 0,
                                homepanel.item.visible ? 0 : 2,
                                homepanel.item.visible ? 2 : 0,
                            ]

                            onReleased: {
                                homepanel.item.visible = !homepanel.item.visible
                            }
                        }

                        Workspaces {} 

                    }

                    RowLayout {

                        id: center

                        anchors.topMargin: Math.round(31/2 - implicitHeight/2)
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter

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

                    RowLayout {

                        id: rightSide

                        anchors.topMargin: Math.round(31/2 - implicitHeight/2)
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.rightMargin: 9


                        spacing: 5


                        PopupList {

                            id: themeList

                            text: "Theme"

                            box_width: 200
                            box_height: 30

                            maxWidth: box_width
                            maxHeight: 200

                            selected_text: Color.current
                            selected_font_size: 13
                            selected_centered: true

                            items: Object.values(Color.colors)

                            list_items: PillButton {

                                required property string id

                                box_height: 30
                                box_width: themeList.list_container_implicitWidth

                                text: id

                                onReleased: {
                                    Color.current = id
                                    //themeList.closeList()
                                }

                            }

                            dropdown: true

                            onListOpened: {
                                item.implicitHeight = SystemInfo.monitorheight
                                bar.focusable = true
                            }
                            onListClosed: {
                                item.implicitHeight = 31
                                bar.focusable = false
                            }
                        }

                    }

                    LazyLoader {id:homepanel; active: true; component: Homepanel {}}

                    ScreenCorners {}
                }
            }

            IpcHandler {
                target: "homepanel"
                function toggle(): void {homepanel.item.visible = !homepanel.item.visible}
            }
        }

    }
}
