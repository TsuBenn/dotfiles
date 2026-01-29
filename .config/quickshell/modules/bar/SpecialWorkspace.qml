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

    property int maxWin: 2

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

                    property int winCount: HyprInfo.windowCount(wb.id)
                    property bool selected: false
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
                            text_opacity: wb.winCount > 0 || wb.selected ? 1 : 0.5

                            font_size: text == "•" ? 15 : 11
                            font_weight: 1000
                            text: wb.winCount > 0 ? wb.name.match(/special:(.+)/)[1] : "•"

                            bg_color: [
                                wb.selected && wb.winCount > 0 ? Color.accentStrong : Color.transparent(Color.accentStrong,0),
                                wb.selected && wb.winCount > 0 ? Color.accentStrong : Color.transparent(Color.accentStrong,0),
                                wb.selected && wb.winCount > 0 ? Color.accentStrong : Color.transparent(Color.accentStrong,0),
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
                                HyprInfo.switchWorkspace(wb.name)
                            }

                        }

                        Repeater {

                            visible: wb.winCount > 0

                            model: HyprInfo.workspaces ? HyprInfo.workspaces[wb.id] : []

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

                                visible: index < root.maxWin

                                width: 29
                                height: 30

                                Image {

                                    id: icon

                                    visible: (apps.index <= wb.winCount-1 && !more.visible) && source != "image://icon/exception"

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
                                    visible: !icon.visible && !more.visible
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
                                    id: more
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: 0.6
                                    visible: apps.index >= root.maxWin-1 && wb.winCount > root.maxWin
                                    text: "+" + (wb.winCount - (root.maxWin-1))
                                    width: 30
                                    font.family: Fonts.system
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
