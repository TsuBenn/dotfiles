pragma ComponentBehavior:Bound 

import qs.modules.common
import qs.services
import qs.assets

import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ClippingRectangle {

    id: root

    visible: implicitWidth

    implicitHeight: 30
    implicitWidth: workspace.implicitWidth
    radius: implicitHeight/2
    color: "transparent"
    Behavior on implicitWidth { NumberAnimation {duration: 200; easing.type: Easing.OutCubic} }

    RowLayout {
        id: workspace
        spacing: 0

        Repeater {

            model: HyprInfo.specialWorkspaces

            delegate: Loader {
                id: theLoader

                required property int index
                required property int id
                required property string name
                required property int windows

                sourceComponent: ClippingRectangle {

                    id: wb

                    property int index: theLoader.index
                    property int id: theLoader.id
                    property string name: theLoader.name
                    property int windows: theLoader.windows

                    property bool selected: index + 1 == HyprInfo.id
                    property real selected_thresold: selected

                    implicitHeight: 30
                    implicitWidth: window.implicitWidth

                    Behavior on implicitWidth { NumberAnimation {duration: 200; easing.type: Easing.OutCubic} }
                    Behavior on selected_thresold { NumberAnimation {duration: 400; easing.type: Easing.OutCubic} }
                    Behavior on color { ColorAnimation {duration: 300; easing.type: Easing.OutCubic} }

                    radius: implicitHeight/2

                    color: selected ? Color.accentStrong : Color.transparent(Color.accentStrong,0)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2.5
                        color: wb.selected ? Color.bgMuted : Color.bgMuted
                        radius: height/2
                        Behavior on color { ColorAnimation {duration: 300; easing.type: Easing.OutCubic} }
                    }

                    RowLayout {

                        id: window
                        spacing: 0

                        PillButton {

                            box_height: 30
                            text_padding: 10
                            text_opacity: HyprInfo.windowCount(wb.index + 1) > 0 || wb.selected ? 1 : 0.5

                            font_size: text == "•" ? 15 : 11
                            font_weight: 1000
                            text: HyprInfo.windowCount(wb.id) > 0 ? wb.name : "•"

                            bg_color: [
                                wb.selected && HyprInfo.windowCount(wb.index + 1) > 0 ? Color.accentStrong : Color.transparent(Color.accentStrong,0),
                                wb.selected && HyprInfo.windowCount(wb.index + 1) > 0 ? Color.accentStrong : Color.transparent(Color.accentStrong,0),
                                wb.selected && HyprInfo.windowCount(wb.index + 1) > 0 ? Color.accentStrong : Color.transparent(Color.accentStrong,0),
                            ]
                            /*
                             bg_color: [
                                 "transparent",
                                 "transparent", 
                                 "transparent", 
                             ]
                             */

                            fg_color: [
                                wb.selected ? Color.textPrimary : Color.accentSoft,
                                wb.selected ? Color.textPrimary : Color.accentSoft,
                                wb.selected ? Color.textPrimary : Color.accentStrong, 
                            ]
                            border_width: [0,0,wb.selected ? 0 : 2]

                            onReleased: {
                                HyprInfo.switchWorkspace(wb.index + 1)
                            }

                        }

                        Repeater {

                            visible: HyprInfo.windowCount(wb.id) > 0

                            model: HyprInfo.specialWorkspaces ? HyprInfo.workspaces[wb.id] : []

                            delegate: Item {

                                id: apps

                                required property int index
                                required property string windowclass
                                required property string windowtitle
                                required property bool focused

                                Component.onCompleted: {
                                    if (focused) {
                                        wb.selected = true
                                    } else {
                                        wb.selected = false
                                    }
                                }

                                visible: index < 2

                                width: 29
                                height: 30

                                Image {

                                    id: icon

                                    visible: apps.index < 1 && source !== "image://icon/exception"

                                    height: 18
                                    width: 18

                                    opacity: apps.focused ? 1 : 0.5
                                    scale: apps.focused ? 1 : 0.9

                                    anchors.verticalCenter: parent.verticalCenter
                                    x: 4

                                    source: "image://icon/" + HyprInfo.iconFetch(apps.windowtitle,apps.windowclass)

                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: 0.6
                                    visible: !icon.visible && apps.index < 1
                                    text: "\udb82\udcc6"
                                    x: 4
                                    width: 30
                                    font.family: Fonts.zalandosans_font
                                    font.pointSize: 10
                                    font.weight: 1000
                                    opacity: apps.focused ? 1 : 0.5
                                    color: Color.textPrimary
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: apps.index == 1 
                                    text: "..."
                                    x: 4
                                    width: 30
                                    font.family: Fonts.zalandosans_font
                                    font.pointSize: 10
                                    font.weight: 1000
                                    color: wb.selected ? Color.accentSoft : Color.accentStrong
                                }
                            }
                        }
                    }

                }
            }
        }


    }

}
