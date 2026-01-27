pragma ComponentBehavior:Bound 

import qs.modules.common
import qs.services
import qs.assets

import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ClippingRectangle {

    implicitHeight: 28
    implicitWidth: workspace.implicitWidth
    radius: implicitHeight/2
    color: "transparent"

    Rectangle {

        id: selection
        implicitHeight: 28

        anchors.left: parent.left
        anchors.right: parent.right

        visible: HyprInfo.id >= 1 && HyprInfo.id <= 5

        anchors.leftMargin: {
            var leftMargin = 28*(HyprInfo.id-1)
            for (var i = 1; i < HyprInfo.id; i++) {
                leftMargin += 29*HyprInfo.windowCount(i)
            }
            if (anchors.leftMargin < leftMargin) {
                left_pause = true
            } else if (anchors.leftMargin > leftMargin) {
                left_pause = false
            }
            return leftMargin
        }
        anchors.rightMargin: {
            var rightMargin = 28*(5-HyprInfo.id)
            for (var i = 5; i > HyprInfo.id; i--) {
                rightMargin += 29*HyprInfo.windowCount(i)
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

            delegate: ClippingRectangle {

                id: wb

                required property int index

                property bool selected: index + 1 == HyprInfo.id
                property real selected_thresold: selected

                implicitHeight: 28
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

                        box_height: 28
                        box_width: box_height
                        text_padding: 0

                        text_opacity: HyprInfo.windowCount(wb.index + 1) > 0 || wb.selected ? 1 : 0.5

                        font_size: text == "•" ? 15 : 10
                        font_weight: 1000
                        text: HyprInfo.windowCount(wb.index + 1) > 0 ? wb.index + 1 : "•"

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

                        visible: HyprInfo.windowCount(wb.index+1) > 0

                        model: HyprInfo.workspaces[wb.index+1]

                        delegate: Item {

                            id: apps

                            required property int index
                            required property string windowclass
                            required property bool focused

                            //Layout.rightMargin: 2

                            Component.onCompleted: {
                                if (windowclass.toLowerCase() == "zen") windowclass = "zen-browser"
                                if (windowclass.toLowerCase() == "portproton") windowclass = "portproton"
                                if (windowclass.match(/.*steam.*/)) windowclass = "steam"
                            }

                            visible: index < 4

                            width: 29
                            height: 28

                            Image {

                                id: icon

                                visible: apps.index < 3

                                height: 18
                                width: 18

                                Behavior on opacity {NumberAnimation {duration: 400; easing.type: Easing.OutCubic}}

                                anchors.verticalCenter: parent.verticalCenter
                                x: 4

                                source: "image://icon/" + apps.windowclass

                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: apps.index == 3
                                text: "..."
                                x: 4
                                width: 28
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

