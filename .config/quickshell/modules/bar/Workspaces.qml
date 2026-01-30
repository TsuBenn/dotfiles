pragma ComponentBehavior:Bound 

import qs.modules.common
import qs.services
import qs.assets

import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ClippingRectangle {

    id: root

    implicitHeight: 30
    implicitWidth: workspace.implicitWidth
    radius: implicitHeight/2
    color: "transparent"

    property int maxWin: 3

    Rectangle {

        id: selection
        implicitHeight: 30

        anchors.left: parent.left
        anchors.right: parent.right

        visible: HyprInfo.focusedworkspace >= 1 && HyprInfo.focusedworkspace <= 5

        anchors.leftMargin: left_margin
        property real left_margin: {
            var leftMargin = 30*(HyprInfo.focusedworkspace-1)
            for (var i = 1; i < HyprInfo.focusedworkspace; i++) {
                leftMargin += 29*Math.min(HyprInfo.windowCount(i),root.maxWin)
            }
            if (anchors.leftMargin < leftMargin) {
                left_pause = true
            } else if (anchors.leftMargin > leftMargin) {
                left_pause = false
            }
            return leftMargin
        }

        anchors.rightMargin: right_margin
        property real right_margin: {
            var rightMargin = 30*(5-HyprInfo.focusedworkspace)
            for (var i = 5; i > HyprInfo.focusedworkspace; i--) {
                rightMargin += 29*Math.min(HyprInfo.windowCount(i),root.maxWin)
            }
            if (anchors.rightMargin < rightMargin) {
                right_pause = true
            } else if (anchors.rightMargin > rightMargin) {
                right_pause = false
            }
            return rightMargin
        }

        property bool left_pause: false
        property bool right_pause: false

        Behavior on anchors.leftMargin {
            SequentialAnimation {
                PauseAnimation {duration: 100*selection.left_pause}
                NumberAnimation {duration: 200; easing.type:Easing.OutCubic}
            }
        }
        Behavior on anchors.rightMargin {
            SequentialAnimation {
                PauseAnimation {duration: 100*selection.right_pause}
                NumberAnimation {duration: 200; easing.type:Easing.OutCubic}
            }
        }

        radius: implicitHeight/2
        color: Color.accentStrong
    }

    RowLayout {
        id: workspace
        spacing: 0

        Repeater {

            model: 5

            delegate: Loader {
                id: theLoader

                required property int index

                sourceComponent: ClippingRectangle {

                    id: wb

                    property int index: theLoader.index

                    property int winCount: HyprInfo.windowCount(wb.index + 1)
                    property bool selected: index + 1 == HyprInfo.focusedworkspace
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
                        Behavior on color { ColorAnimation {duration: 400; easing.type: Easing.OutCubic} }
                    }

                    RowLayout {

                        id: window
                        spacing: 0

                        PillButton {

                            box_height: 30
                            box_width: box_height
                            text_padding: 0

                            text_opacity: wb.winCount > 0 || wb.selected ? 1 : 0.5

                            font_size: text == "•" ? 15 : 11
                            font_weight: 1000
                            text: wb.winCount > 0 ? wb.index + 1 : "•"

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
                                wb.selected ? wb.winCount > 0 ? Color.textSecondary : Color.textPrimary: Color.accentSoft,
                                wb.selected ? wb.winCount > 0 ? Color.textSecondary : Color.textPrimary: Color.accentSoft,
                                wb.selected ? wb.winCount > 0 ? Color.textSecondary : Color.textPrimary: Color.accentStrong,
                            ]
                            border_width: [0,0,wb.selected ? 0 : 2]

                            onReleased: {
                                HyprInfo.switchWorkspace(wb.index + 1)
                            }

                        }

                        Repeater {

                            visible: wb.winCount > 0

                            model: HyprInfo.workspaces ? HyprInfo.workspaces[wb.index+1] : []

                            delegate: Item {

                                id: apps

                                required property int index
                                required property string windowclass
                                required property string windowtitle
                                required property bool focused

                                //Layout.rightMargin: 2

                                visible: index < root.maxWin

                                width: 29
                                height: 30

                                Image {

                                    id: icon

                                    visible: (apps.index <= wb.winCount-1 && !more.visible) && source != "image://icon/exception"

                                    height: 16
                                    width: 16

                                    opacity: apps.focused ? 1 : 0.5
                                    scale: apps.focused ? 1 : 0.9

                                    anchors.verticalCenter: parent.verticalCenter
                                    x: 4

                                    source: "image://icon/" + HyprInfo.iconFetch(apps.windowtitle,apps.windowclass)

                                    layer.enabled: apps.focused
                                    layer.effect: DropShadow {
                                        radius: 2
                                        samples: 10
                                        spread: 0.8
                                        color: Qt.darker(Color.accentStrong,1.2)
                                    }

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

