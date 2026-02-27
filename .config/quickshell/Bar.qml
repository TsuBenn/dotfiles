pragma ComponentBehavior:Bound 

import qs.modules.common
import qs.modules.homepanel
import qs.modules.bar
import qs.services
import qs.assets

import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
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

            function gainScreenAccess() {
                item.implicitHeight = bar.monitor.height
                bar.focusable = true
            }
            function returnScreenAccess() {
                item.implicitHeight = 31
                bar.focusable = false

            }

            property string screen_name: screen.name
            property var monitor: HyprInfo.monitors[screen_name] != undefined ? HyprInfo.monitors[screen_name] : {"width": 1920, "height": 1080}

            property HyprlandMonitor monitorObject

            property int screenRadius: 20
            property bool transparentBar: false && !homepanel.item.visible

            Behavior on screenRadius {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

            Component.onCompleted: {
                for (const m of Hyprland.monitors.values) {
                    if (m.name == screen.name) {
                        monitorObject = m
                    }
                }
            }

            screen: modelData

            focusable: true

            exclusionMode: ExclusionMode.Auto

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: -40 * (bar.monitorObject.activeWorkspace.hasFullscreen)
            }

            color: transparentBar ? "transparent" : Color.bgSurface

            Behavior on color {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}

            implicitHeight: 40

            PopupWindow {

                anchor {
                    window: bar
                }
                implicitWidth: bar.monitor.width
                implicitHeight: bar.monitor.height
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

                                visible: (text && (text.toLowerCase() != window_title.text.toLowerCase()) && !homepanel.item.visible && window_title.text != "Desktop" )

                                text: `${HyprInfo.monitors[HyprInfo.focusedwindow.monitor]?.name} - ${HyprInfo.focusedwindow.class}`

                                Layout.preferredWidth: Math.min(implicitWidth,bar.implicitWidth/2 - workspaces.implicitWidth/2 - left_center.implicitWidth - homebutton.implicitWidth - 42)
                                elide: Text.ElideRight

                                Layout.bottomMargin: -5

                                color: Qt.lighter(Color.textDisabled,1.5)
                                font.family: Fonts.system
                                font.pointSize: 9
                                font.weight: 700

                            }
                            Text {

                                id: window_title

                                text: homepanel.item.visible ? "Homepanel" : HyprInfo.focusedwindow.title

                                Layout.preferredWidth: Math.min(implicitWidth,bar.monitor.width/2 - workspaces.implicitWidth/2 - left_center.implicitWidth - homebutton.implicitWidth - 42)

                                color: Color.accentSoft
                                font.family: Fonts.system
                                font.pointSize: window_class.visible ? 11 : 12
                                font.weight: 800
                                elide: Text.ElideRight

                            }
                        }

                    }

                    component ComponentCircle: Item {

                        id: component_circle

                        property int percentage: SystemInfo.cpuusage
                        property string icon: "\uf4bc"
                        property int icon_size: 13
                        property real horizontalOffset: 0
                        property real verticalOffset: 0

                        Layout.topMargin: 1

                        implicitWidth: progress_circle.implicitWidth
                        implicitHeight: progress_circle.implicitHeight

                        ClippingRectangle {

                            implicitHeight: 27
                            implicitWidth: 27

                            Behavior on implicitWidth {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

                            radius: implicitHeight/2
                            color: Color.bgMuted

                        }

                        ProgressCircle {

                            anchors.centerIn: parent
                            id: progress_circle

                            thickness: 2.5
                            radius: 12
                            icon: ""
                            label: ""
                            percentage: component_circle.percentage
                            fg_color: {
                                if (percentage >= 90) return Color.error
                                return Color.textPrimary
                            }
                            bg_color: Qt.lighter(Color.bgMuted,1.5)
                        }


                        Text {

                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: component_circle.horizontalOffset
                            anchors.verticalCenterOffset: component_circle.verticalOffset

                            text: component_circle.icon

                            color: {
                                if (component_circle.percentage >= 90) return Color.error
                                return Color.textPrimary
                            }
                            font.family: Fonts.system
                            font.pointSize: component_circle.icon_size
                            font.weight: 800

                        }
                    }

                    RowLayout {
                        id: left_center

                        anchors.rightMargin: 12
                        anchors.right: workspaces.left
                        anchors.verticalCenter: workspaces.verticalCenter
                        spacing: 10


                        ComponentCircle {
                            z: 1
                            percentage: SystemInfo.cpuusage
                            icon: "\uf4bc"
                            icon_size: 11
                            verticalOffset: -0.4
                        }

                        ComponentCircle {
                            z: 1
                            percentage: SystemInfo.gpuusage
                            icon: "\udb83\udfb2"
                        }

                        ComponentCircle {
                            z: 1
                            percentage: SystemInfo.memusage
                            icon: "\uefc5"
                            icon_size: 10
                            horizontalOffset: -0.4
                        }

                        Rectangle {

                            implicitHeight: 26
                            implicitWidth: 160
                            radius: implicitHeight/2

                            color: Color.bgMuted

                            MouseControl {

                                anchors.fill: parent
                                anchors.margins: -7

                                onReleased: {
                                    media_player.opened = !media_player.opened
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                implicitHeight: 40
                                implicitWidth: media_player.implicitWidth
                                color: Color.bgSurface
                            }

                            BarMediaPlayer {

                                z: -10

                                id: media_player

                                x: parent.implicitWidth/2 - implicitWidth/2
                                y: media_player.opacity*40 - (1 - media_player.opacity)*implicitHeight

                                onVisibleChanged: {
                                    if (visible) bar.gainScreenAccess()
                                    else bar.returnScreenAccess()
                                }

                                Rectangle {

                                    width: HyprInfo.focusedMonitor.width*2
                                    height: HyprInfo.focusedMonitor.height*2

                                    x:-HyprInfo.focusedMonitor.width
                                    y:-HyprInfo.focusedMonitor.height

                                    color: "transparent"

                                    z: -2

                                    focus: true

                                    Keys.onPressed: (events) => {
                                        events.accepted = true
                                        KeyHandlers.signalPressed(events.key, events.modifiers, events.isAutoRepeat)
                                    }
                                    Keys.onReleased: (events) => {
                                        events.accepted = true
                                        KeyHandlers.signalReleased(events.key, events.modifiers, events.isAutoRepeat)
                                    }

                                    Component.onCompleted: {
                                        KeyHandlers.pressed.connect((key) => {
                                            if (!media_player.visible) return
                                            if (key == Qt.Key_Right) {
                                                MediaPlayerInfo.nextMedia()
                                            } else if (key == Qt.Key_Left) {
                                                MediaPlayerInfo.prevMedia()
                                            } else if (key == Qt.Key_Space) {
                                                MediaPlayerInfo.playPauseMedia()
                                            } else if (key == Qt.Key_Escape) {
                                                media_player.opacity = 0
                                            }
                                        })
                                    }

                                    MouseControl {

                                        anchors.fill: parent

                                        hoverEnabled: true

                                        onEntered: {
                                            media_player_timer.restart()
                                        }
                                        onExited: {
                                            media_player_timer.stop()
                                        }

                                        onReleased: {
                                            media_player.opened = 0
                                        }

                                    }
                                }

                                Timer {
                                    id: media_player_timer
                                    interval: 500

                                    onTriggered: {
                                        media_player.opened = 0
                                    }
                                }

                                MouseArea {

                                    z:-1

                                    anchors.fill: parent
                                    anchors.margins: -100

                                    hoverEnabled: true

                                    onReleased: {
                                        media_player.opened = 0
                                    }
                                }

                            }

                            Rectangle {

                                visible: true

                                anchors.fill: parent
                                anchors.margins: 2

                                radius: 20
                                color: Color.bgBase
                            }

                            ClippingRectangle {

                                anchors.fill: parent

                                radius: parent.radius
                                color: "transparent"

                                Image {

                                    visible: true

                                    anchors.fill: parent

                                    source: MediaPlayerInfo.artUrl
                                    fillMode: Image.PreserveAspectCrop

                                    opacity: status == Image.Ready ? 0.4 : 0
                                    Behavior on opacity {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

                                    layer.enabled: true
                                    layer.effect: GaussianBlur {
                                        radius: 15
                                        samples: 30
                                        cached: true
                                    }

                                }

                            }

                            PillButton {

                                id: media_playPause

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter

                                box_height: 26
                                box_width: box_height

                                property color play_button: MediaPlayerInfo.canPlay ? Color.textPrimary : Color.textDisabled

                                font_size: {
                                    if (MediaPlayerInfo.status == "playing") return 12
                                    else return 10
                                }

                                text: {
                                    if (MediaPlayerInfo.status == "playing") return "\uf04c"
                                    else return "\uf04b"
                                }

                                fg_color: [play_button, play_button, Color.textSecondary]
                                bg_color: [Color.bgMuted,Color.bgMuted,Color.textPrimary]
                                border_width: [0,0,0]

                                ProgressCircle {

                                    label: ""
                                    icon: ""

                                    radius: 11.75
                                    thickness: 2.5

                                    percentage: MediaPlayerInfo.canPos ? (MediaPlayerInfo.pos/MediaPlayerInfo.length)*100 : 100

                                    bg_color: Qt.lighter(Color.bgMuted,1.5)
                                    fg_color: MediaPlayerInfo.canPos ? Color.textPrimary : Color.textDisabled
                                }

                                onReleased: {
                                    MediaPlayerInfo.playPauseMedia()
                                    MediaPlayerInfo.requestPos()
                                }

                                layer.enabled: true
                                layer.effect: DropShadow {
                                    radius: 6
                                    samples: 10
                                    color: Qt.rgba(0.0,0.0,0.0,0.4)
                                    transparentBorder: true
                                }

                            }

                            MarqueeText {

                                anchors.left: media_playPause.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: 0.4

                                box_width: parent.width - 30

                                centered: false

                                text: `${MediaPlayerInfo.title} ${MediaPlayerInfo.artist ? "- " + MediaPlayerInfo.artist : ""}`

                                padding: 10
                                font_family: Fonts.system
                                font_color: Color.textPrimary
                                font_size: 10
                                font_weight: 700
                            }

                        }

                    }

                    Workspaces {

                        id: workspaces

                        anchors.topMargin: Math.round(31/2 - implicitHeight/2)
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter

                        secondMonitor: bar.monitor.id > 0

                    } 

                    RowLayout {
                        id: right_center

                        anchors.leftMargin: 12
                        anchors.left: workspaces.right
                        anchors.verticalCenter: workspaces.verticalCenter
                        spacing: 10


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
                                font.weight: 700
                                font.wordSpacing: -4
                            }

                        }

                        Item {

                            Layout.topMargin: 1

                            implicitWidth: battery.implicitWidth
                            implicitHeight: battery.implicitHeight

                            ClippingRectangle {

                                id: battery_percentage

                                implicitHeight: 27
                                implicitWidth: 27

                                Behavior on implicitWidth {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

                                radius: implicitHeight/2
                                color: Color.bgMuted

                                MouseArea {

                                    anchors.fill: parent
                                    anchors.margins: -10

                                    hoverEnabled: true

                                    onEntered: {
                                        battery_percentage.implicitWidth = battery_text.paintedWidth + 42
                                    }
                                    onExited: {
                                        battery_percentage.implicitWidth = 27
                                    }

                                }

                                Rectangle {

                                    anchors.right: parent.right

                                    implicitHeight: 27
                                    implicitWidth: 64 - 27
                                    color: "transparent"

                                    Text {

                                        id: battery_text

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.verticalCenterOffset: 0.5

                                        text: SystemInfo.battery == "inf" ? "inf" : parseInt(SystemInfo.battery)

                                        width: implicitWidth
                                        horizontalAlignment: Text.AlignRight 

                                        color: Color.textPrimary
                                        font.family: Fonts.system
                                        font.pointSize: 10
                                        font.weight: 800

                                    }
                                }

                            }

                            Rectangle {
                                implicitHeight: 27
                                implicitWidth: 27

                                color: Color.bgMuted
                                radius: implicitHeight/2
                            }


                            ProgressCircle {

                                anchors.centerIn: parent
                                id: battery

                                thickness: 2.5
                                radius: 12
                                icon: ""
                                label: ""
                                percentage: SystemInfo.battery == "inf" ? 100 : parseInt(SystemInfo.battery)
                                fg_color: {
                                    if (SystemInfo.batterystate == "charging" || SystemInfo.batterystate == "fully-charged") {
                                        return Color.success
                                    }
                                    else if (percentage <= 20) {
                                        return Color.error
                                    }
                                    return Color.textPrimary
                                }
                                bg_color: Qt.lighter(Color.bgMuted,1.5)

                            }


                            Text {

                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: -1/(battery.thickness-1)

                                text: {
                                    const raw = SystemInfo.battery
                                    const state = SystemInfo.batterystate

                                    if (
                                        raw == "inf" ||
                                        state == "charging" ||
                                        state == "fully-charged"
                                    ) {
                                        return "\udb80\udc84"
                                    }

                                    const battery = parseInt(raw)

                                    if (isNaN(battery) || battery <= 5)
                                    return "\udb80\udc8e"

                                    if (battery > 95)
                                    return "\udb80\udc79"

                                    // 6–95 range mapping
                                    const step = Math.max(Math.floor((battery-6)/ 10),0)
                                    return String.fromCharCode(0xDB80, 0xDC7A + step)
                                }

                                color: {
                                    if (SystemInfo.batterystate == "charging" || SystemInfo.batterystate == "fully-charged") {
                                        return Color.success
                                    }
                                    else if (battery.percentage <= 20) {
                                        return Color.error
                                    }
                                    return Color.textPrimary
                                }
                                font.family: Fonts.system
                                font.pointSize: 13
                                font.weight: 800

                            }
                        }
                    }

                    RowLayout {

                        id: rightSide

                        anchors.topMargin: Math.round(31/2 - implicitHeight/2)
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.rightMargin: 9


                        spacing: 5

                    }

                    LazyLoader {id:homepanel; active: true; component: Homepanel {monitor: bar.monitor}}

                    ScreenCorners {visible: !bar.transparentBar; screenRadius: bar.screenRadius; monitor: bar.monitor}
                }
            }

            IpcHandler {
                target: "homepanel"
                function toggle(): void {homepanel.item.toggle()}
            }
        }

    }
}
