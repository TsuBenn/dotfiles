pragma ComponentBehavior:Bound 

import qs.modules.common
import qs.services
import qs.assets

import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {

    id: root

    implicitHeight: 24
    implicitWidth: workspace.implicitWidth
    radius: implicitHeight/2
    color: Color.bgMuted

    border.width: 0
    border.color: Qt.lighter(Color.bgMuted,1.5)

    property int maxWin: 3

    property real icon_size: 16
    property real num_size: 11

    property int hovered_workspace: 1

    property bool monitorBasedWorkspace: false
    property bool secondMonitor: HyprInfo.focusedMonitor.id > 0 && monitorBasedWorkspace
    property bool inBound: HyprInfo.focusedworkspace >= 1 + (root.secondMonitor ? 5 : 0) && HyprInfo.focusedworkspace <= 5 + (root.secondMonitor ? 5 : 0) 

    Rectangle {

        visible: false
        anchors.left: parent.left
        anchors.right: parent.right

        anchors.verticalCenter: parent.verticalCenter

        radius: implicitHeight/2

        implicitHeight: 26

        color: Color.bgMuted

    }

    property real selection_width: root.implicitHeight
    property real selection_height: root.implicitHeight

    Rectangle {

        id: selection
        implicitHeight: root.implicitHeight

        anchors.left: parent.left
        anchors.right: parent.right

        anchors.verticalCenter: parent.verticalCenter

        opacity: root.inBound

        Behavior on opacity {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

        anchors.leftMargin: left_margin
        property real left_margin: {
            if (!root.inBound) return
            var leftMargin = root.selection_width*(HyprInfo.focusedworkspace-(root.secondMonitor ? 6 : 1))
            for (var i = (root.secondMonitor ? 6 : 1); i < HyprInfo.focusedworkspace; i++) {
                leftMargin += (root.selection_width+2)*Math.min(HyprInfo.windowCount(i),root.maxWin) + workspace.spacing
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
            if (!root.inBound) return
            var rightMargin = root.selection_width*((root.secondMonitor ? 10 : 5)-HyprInfo.focusedworkspace)
            for (var i = (root.secondMonitor ? 10 : 5); i > HyprInfo.focusedworkspace; i--) {
                rightMargin += (root.selection_width+2)*Math.min(HyprInfo.windowCount(i),root.maxWin) + workspace.spacing
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
                PauseAnimation {duration: 75*selection.left_pause}
                NumberAnimation {duration: 100; easing.type:Easing.OutCubic}
            }
        }
        Behavior on anchors.rightMargin {
            SequentialAnimation {
                PauseAnimation {duration: 75*selection.right_pause}
                NumberAnimation {duration: 100; easing.type:Easing.OutCubic}
            }
        }

        radius: implicitHeight/2
        color: Color.accentStrong
    }

    RowLayout {
        id: workspace
        spacing: 4

        Repeater {

            model: 5

            delegate: Loader {
                id: theLoader

                required property int index

                sourceComponent: ClippingRectangle {

                    id: wb

                    property int index: theLoader.index + (root.secondMonitor ? 5 : 0)

                    property int winCount: HyprInfo.windowCount(wb.index + 1)
                    property bool selected: index + 1 == HyprInfo.focusedworkspace
                    property real selected_thresold: selected

                    implicitHeight: root.selection_height
                    implicitWidth: window.implicitWidth

                    Behavior on implicitWidth { NumberAnimation {duration: 200; easing.type: Easing.OutCubic} }
                    Behavior on selected_thresold { NumberAnimation {duration: 400; easing.type: Easing.OutCubic} }

                    radius: implicitHeight/2

                    color: "transparent"

                    Rectangle {

                        visible: false
                        anchors.fill: parent
                        anchors.margins: 2
                        color: wb.selected ? Color.bgMuted : Color.bgMuted
                        radius: height/2
                        Behavior on color { ColorAnimation {duration: 400; easing.type: Easing.OutCubic} }

                    }

                    MouseArea {
                        z: 2
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true

                        onEntered: {
                            root.hovered_workspace = wb.index + 1
                        }
                    }

                    RowLayout {

                        id: window
                        spacing: 0

                        PillButton {

                            id: pillbutton

                            box_height: root.selection_height
                            box_width: box_height
                            text_padding: 0

                            text_opacity: wb.winCount > 0 || wb.selected ? 1 : 0.5

                            font_size: text == "•" ? 15 : root.num_size
                            font_weight: 1000
                            text: wb.winCount > 0 ? wb.index + 1 : "•"

                            verticalOffset: wb.winCount > 0 ? -0.6 : 0.8
                            horizontalOffset: wb.winCount > 0 ? 0.8 : 0

                            Behavior on color {ColorAnimation {duration: 100; easing.type: Easing.OutCubic}}

                            fg_color_animation: 100

                            bg_color: [
                                "transparent",
                                "transparent",
                                "transparent",
                            ]
                            /*
                             bg_color: [
                                 "transparent",
                                 "transparent", 
                                 "transparent", 
                             ]
                             */

                            fg_color: [
                                wb.selected ? wb.winCount > 0 ? Color.textSecondary : Color.textSecondary: Color.accentSoft,
                                wb.selected ? wb.winCount > 0 ? Color.textSecondary : Color.textSecondary: Color.accentSoft,
                                wb.selected ? wb.winCount > 0 ? Color.textSecondary : Color.textSecondary: Color.accentStrong,
                            ]
                            border_width: [0,0,0]

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
                                required property string address

                                //Layout.rightMargin: 2

                                visible: index < root.maxWin

                                width: root.selection_width + 2
                                height: root.selection_height + 2

                                layer.enabled: true
                                layer.effect: DropShadow {
                                    radius: 2
                                    samples: 10
                                    color: Color.transparent(Qt.darker(Color.accentStrong,2))
                                }

                                Image {

                                    id: icon

                                    visible: (apps.index <= wb.winCount-1 && !more.visible) && source != ""

                                    height: root.icon_size
                                    width: root.icon_size

                                    scale: apps.focused || !wb.selected  ? 1 : 0.9
                                    opacity: apps.focused || !wb.selected  ? 1 : 0.5

                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: -0.6
                                    x: 2

                                    property string icon_name: HyprInfo.iconFetch(apps.windowtitle,apps.windowclass)

                                    source: icon_name != "exception" ? "image://icon/" + icon_name : ""

                                    cache: false

                                    mipmap: true
                                    smooth: true

                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: 0.6
                                    visible: !icon.visible && !more.visible
                                    text: "\udb82\udcc6"
                                    x: 6
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
                                    anchors.verticalCenterOffset: -0.4
                                    visible: apps.index >= root.maxWin-1 && wb.winCount > root.maxWin
                                    text: "+" + (wb.winCount - (root.maxWin-1))
                                    width: 30
                                    font.family: Fonts.system
                                    font.pointSize: 10
                                    font.weight: 1000
                                    color: wb.selected ? Color.textSecondary : Color.accentStrong

                                    Behavior on color {ColorAnimation {duration: pillbutton.fg_color_animation*2; easing.type: Easing.OutCubic}}
                                }

                                MouseControl {
                                    anchors.fill: parent

                                    onReleased: {
                                        if (containsMouse) {
                                            HyprInfo.switchWorkspace(wb.index + 1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}

