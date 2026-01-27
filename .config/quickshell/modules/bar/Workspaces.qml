pragma ComponentBehavior:Bound 

import qs.modules.common
import qs.services
import qs.assets

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {

    implicitHeight: 28
    implicitWidth: workspace.implicitWidth
    radius: implicitHeight/2
    color: Color.bgBase

    Rectangle {
        id: selection
        implicitHeight: 28
        implicitWidth: 28
        radius: implicitHeight/2
        color: Color.accentStrong
        Behavior on implicitWidth {NumberAnimation {duration: 300; easing.type: Easing.OutCubic}}
        Behavior on x {NumberAnimation {duration: 300; easing.type: Easing.OutCubic}}
    }

    RowLayout {
        id: workspace
        spacing: 5

        Repeater {

            model: 5

            delegate: Rectangle {

                id: wb

                required property int index

                property bool selected: index + 1 == HyprInfo.id

                onSelectedChanged: {
                    if (selected) {
                        selection.x = x
                        selection.implicitWidth = implicitWidth
                    }
                }

                onImplicitWidthChanged: {
                    selection.x = x
                    selection.implicitWidth = implicitWidth
                }

                implicitHeight: 28
                implicitWidth: window.implicitWidth

                Behavior on implicitWidth {NumberAnimation {duration: 300; easing.type: Easing.OutCubic}}
                Behavior on border.width {NumberAnimation {duration: 300; easing.type: Easing.OutCubic}}

                radius: implicitHeight/2

                color: selected ? Color.bgBase : "transparent"
                border.width: selected ? 2 : 0
                border.color: Color.accentStrong

                RowLayout {

                    id: window
                    spacing: 0

                    PillButton {

                        box_height: 28
                        box_width: box_height
                        text_padding: 0

                        opacity: HyprInfo.windowCount(wb.index + 1) > 0 || wb.selected ? 1 : 0.2

                        font_size: text == "•" ? 15 : 11
                        font_weight: 1000
                        text: HyprInfo.windowCount(wb.index + 1) > 0 ? wb.index + 1 : "•"

                        bg_color: [
                            wb.selected ? Color.accentStrong : "transparent",
                            wb.selected ? Color.accentStrong : "transparent", 
                            wb.selected ? Color.accentStrong : "transparent", 
                        ]
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

                        visible: HyprInfo.windowCount(wb.index+1) > 0

                        model: HyprInfo.workspaces[wb.index+1]

                        delegate: Item {

                            id: apps

                            required property int index
                            required property string windowclass
                            required property bool focused

                            Layout.rightMargin: 4

                            Component.onCompleted: {
                                if (windowclass == "zen") windowclass = "zen-browser"
                            }

                            visible: index < 4

                            width: 28
                            height: 28

                            Image {

                                visible: apps.index < 3

                                height: 16
                                width: 16
                                smooth: true
                                opacity: apps.focused && wb.selected ? 1 : 0.5

                                Behavior on opacity {NumberAnimation {duration: 300; easing.type: Easing.OutCubic}}
                                anchors.centerIn: parent
                                source: "image://icon/" + apps.windowclass

                                layer.enabled: true
                                layer.effect: ColorOverlay {

                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: apps.index == 3
                                text: "..."
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

