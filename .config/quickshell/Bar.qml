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
            property bool transparentBar: false && !homepanel.item.visible

            Behavior on screenRadius {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

            screen: modelData

            focusable: true

            exclusionMode: ExclusionMode.Auto

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: -40 * Hyprland.focusedWorkspace.hasFullscreen
            }

            color: transparentBar ? "transparent" : Color.bgSurface

            Behavior on color {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}

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

                            Layout.topMargin: -1

                            bg_color: [
                                homepanel.item?.visible ? Color.accentStrong : Color.bgSurface,
                                homepanel.item?.visible ? Color.accentStrong : Color.bgSurface,
                                homepanel.item?.visible ? Color.bgSurface : Color.accentStrong,
                            ]

                            fg_color: [
                                homepanel.item?.visible ? Color.textSecondary : Color.textPrimary,
                                homepanel.item?.visible ? Color.textSecondary : Color.textPrimary,
                                homepanel.item?.visible ? Color.textSecondary : Color.textSecondary,
                            ]

                            border_width: [
                                homepanel.item?.visible ? 0 : 0,
                                homepanel.item?.visible ? 0 : 2,
                                homepanel.item?.visible ? 2 : 0,
                            ]

                            onReleased: {
                                homepanel.item.toggle()
                            }
                        }

                        ColumnLayout {
                            Layout.leftMargin: 4
                            spacing: 0
                            Text {

                                id: window_class

                                visible: text && (text != window_title.text) && !homepanel.item.visible

                                text: HyprInfo.focusedwindow.class

                                Layout.preferredWidth: Math.min(implicitWidth,200)
                                Layout.bottomMargin: -5

                                color: Qt.lighter(Color.textDisabled,1.5)
                                font.family: Fonts.system
                                font.pointSize: 9
                                font.weight: 700
                                elide: Text.ElideRight

                            }
                            Text {

                                id: window_title

                                text: homepanel.item.visible ? "Homepanel" : HyprInfo.focusedwindow.title

                                Layout.preferredWidth: Math.min(implicitWidth,200)

                                color: Color.accentSoft
                                font.family: Fonts.system
                                font.pointSize: window_class.visible ? 11 : 12
                                font.weight: 800
                                elide: Text.ElideRight

                            }
                        }

                    }

                    RowLayout {
                        id: left_center
                        anchors.right: workspaces.left
                    }

                    Workspaces {

                        id: workspaces

                        anchors.topMargin: Math.round(31/2 - implicitHeight/2)
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter

                    } 

                    RowLayout {
                        id: right_center

                        anchors.leftMargin: 10
                        anchors.left: workspaces.right
                        anchors.verticalCenter: workspaces.verticalCenter
                        spacing: 12


                        Rectangle {

                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: clock.implicitWidth + 20
                            implicitHeight: 26
                            radius: implicitWidth/2
                            color: Color.bgMuted

                            Text {

                                id: clock
                                anchors.centerIn: parent
                                color: Color.textPrimary
                                text: DateTime.hour12 + ":" + DateTime.minute + " " + DateTime.ampm + " • " + DateTime.dayofweek_short + ", " + DateTime.date + " " + DateTime.month_short
                                font.family: Fonts.system
                                font.pointSize: 11
                                font.weight: 800
                                font.wordSpacing: -4
                            }

                        }

                        Text {

                            id: battery

                            text: {
                                if (SystemInfo.battery == "inf" || SystemInfo.batterystate == "charging" || SystemInfo.batterystate == "fully-charged") {
                                    return "\udb80\udc84"                                
                                }
                                else if (parseInt(SystemInfo.battery) >= 100) {
                                    return "\udb80\udc79"
                                }
                                else if (parseInt(SystemInfo.battery) > 95) {
                                    return "\udb80\udc82"
                                }
                                else if (parseInt(SystemInfo.battery) > 85) {
                                    return "\udb80\udc81"
                                }
                                else if (parseInt(SystemInfo.battery) > 75) {
                                    return "\udb80\udc80"
                                }
                                else if (parseInt(SystemInfo.battery) > 65) {
                                    return "\udb80\udc7f"
                                }
                                else if (parseInt(SystemInfo.battery) > 55) {
                                    return "\udb80\udc7e"
                                }
                                else if (parseInt(SystemInfo.battery) > 45) {
                                    return "\udb80\udc7d"
                                }
                                else if (parseInt(SystemInfo.battery) > 35) {
                                    return "\udb80\udc7c"
                                }
                                else if (parseInt(SystemInfo.battery) > 25) {
                                    return "\udb80\udc7c"
                                }
                                else if (parseInt(SystemInfo.battery) > 15) {
                                    return "\udb80\udc7b"
                                }
                                else if (parseInt(SystemInfo.battery) > 5) {
                                    return "\udb80\udc7a"
                                }
                                else if (parseInt(SystemInfo.battery) > 0) {
                                    return "\udb80\udc8e"
                                }
                            }

                            color: Color.textPrimary
                            font.family: Fonts.system
                            font.pointSize: 13
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

                    ScreenCorners {visible: !bar.transparentBar}
                }
            }

            IpcHandler {
                target: "homepanel"
                function toggle(): void {homepanel.item.toggle()}
            }
        }

    }
}
