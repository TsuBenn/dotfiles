pragma ComponentBehavior:Bound

import qs.assets
import qs.modules.common
import qs.modules.homepanel
import qs.services
import qs.modules.homepanel.widgets

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick

ColumnLayout {

    property bool panel_navigator: true

    id: root

    function advancePanel(interval) {
        widgets.panel_index = Math.min(Math.max(widgets.panel_index + interval,1),3)
    }

    component PowerButton: PillButton {
        box_height: 65
        box_width: 65
        property color icon_color
        radius: Config.radius
        bg_color: [Color.bgSurface , Color.bgSurface, icon_color]
        fg_color: [Color.accentStrong, icon_color, Color.bgSurface]
        border_width: [2,3,0]
        border_color: [Color.blend(Color.accentStrong,Color.bgSurface,0.75),icon_color,Color.accentStrong]
    }

    component WidgetsPanel: RowLayout {

        required property int index

        Layout.preferredWidth: 1000
        Layout.preferredHeight: 425

        x: (-implicitWidth - 50) * (widgets.panel_index - index)

        opacity: widgets.panel_index == index

        Behavior on x {NumberAnimation {
            duration: 400
            easing.type: Easing.OutElastic
            easing.amplitude: 0.5
            easing.period: 1.8
        }}
        Behavior on opacity {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

        spacing: Config.gap


    }

    spacing: Config.gap

    Rectangle {

        id: widgets

        implicitWidth: 1000
        implicitHeight: 425

        color: "transparent"
        radius: Config.radius

        property int panel_index: 1

        //Panel 1
        WidgetsPanel {

            index: 1

            ColumnLayout {

                spacing: Config.gap

                //User Profile
                WidgetsContainer {
                    implicitWidth: 210
                    implicitHeight: 294

                    UserProfile {
                        anchors.centerIn: parent
                    }
                }

                //Weather
                WidgetsContainer {
                    implicitWidth: 210
                    implicitHeight: 124

                    Weather {
                        anchors.fill: parent
                    }

                }
            }

            ColumnLayout {

                spacing: Config.gap

                //Performance
                WidgetsContainer {
                    implicitWidth: 584
                    implicitHeight: 170
                    Performance {
                        anchors.centerIn: parent
                    }
                }

                RowLayout {

                    spacing: Config.gap

                    //Calendar
                    WidgetsContainer {
                        implicitWidth: 256
                        implicitHeight: 248

                        property var date: CalendarInfo.dates

                        Calendar {

                            anchors.centerIn: parent

                        }

                    }

                    //Media Player
                    WidgetsContainer {

                        implicitWidth: 320
                        implicitHeight: 248

                        ClippingRectangle {

                            id: mediaBg

                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.left: parent.left

                            anchors.margins: parent.border.width

                            implicitHeight: 120 - parent.border.width*2

                            radius: Config.radius

                            border.width: 4
                            border.color: Color.bgSurface

                            color: Color.bgMuted

                            Item {

                                id: artContainer

                                anchors.fill: parent

                                Text {
                                    anchors.centerIn: parent

                                    visible: !MediaPlayerInfo.activePlayer

                                    text: "No Media Player Active"
                                    font.family: Fonts.system
                                    font.pointSize: 13
                                    font.weight: 700
                                    color: Color.textDisabled
                                }

                                Image {

                                    id: artBg

                                    anchors.verticalCenter: parent.verticalCenter

                                    width: parent.width
                                    height: (sourceSize.height/sourceSize.width)*width
                                    cache: true

                                    opacity: status == Image.Ready
                                    Behavior on opacity {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

                                    source: MediaPlayerInfo.artUrl

                                    layer.enabled: true
                                    layer.effect: GaussianBlur {
                                        radius: 15
                                        samples: 30
                                        cached: true
                                    }

                                }

                                Image {

                                    id: artBgBlurred

                                    anchors.verticalCenter: parent.verticalCenter

                                    width: parent.width
                                    height: (sourceSize.height/sourceSize.width)*width
                                    cache: true

                                    visible: true

                                    source: MediaPlayerInfo.artUrl

                                    opacity: 0

                                    Behavior on opacity {
                                        SequentialAnimation {
                                            PauseAnimation {duration: mediaPlayer.pause}
                                            NumberAnimation {duration: 300; easing.type: Easing.OutCubic}
                                        }
                                    }

                                    layer.enabled: true
                                    layer.effect: GaussianBlur {
                                        radius: 50
                                        samples: 50
                                        cached: true
                                    }

                                }

                            }

                            Rectangle {

                                visible: MediaPlayerInfo.activePlayer

                                id: mediaDarken

                                anchors.fill: parent

                                color: "black"

                                opacity: 0.2

                            }

                            BarVisualizer {

                                id: barVisualizer

                                visible: MediaPlayerInfo.activePlayer

                                spacing: 2
                                round: true
                                opacity: 0.4

                                color: Qt.lighter(Color.accentSoft,1.2)

                                layer.enabled: true
                                layer.effect: DropShadow {
                                    radius: 15
                                    samples: 20
                                    color: Qt.rgba(0.0,0.0,0.0,0.5)
                                    transparentBorder: true
                                }
                            }

                        }

                        SequentialAnimation {
                            id: artOpen
                            PauseAnimation {
                                duration: 200
                            }
                            ScriptAction {
                                script: {
                                    if (!mediaPlayer.artHovered) {artOpen.stop()}
                                }
                            }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: barVisualizer
                                    property: "opacity"
                                    duration: 200
                                    to: 0.3
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: mediaDarken
                                    property: "opacity"
                                    duration: 200
                                    to: 0.4
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: artBgBlurred
                                    property: "opacity"
                                    duration: 200
                                    to: 1
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: mediaPlayer
                                    property: "artWidth"
                                    duration: 200
                                    to: mediaPlayer.artHeight
                                    easing.type: Easing.OutCubic
                                }
                            }
                            ScriptAction {
                                script: {
                                    if (!mediaPlayer.artHovered) {artClose.start()}
                                }
                            }
                        }
                        SequentialAnimation {
                            id: artClose
                            PauseAnimation {
                                duration: 200
                            }
                            ScriptAction {
                                script: {
                                    if (mediaPlayer.artHovered) {artClose.stop()}
                                }
                            }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: barVisualizer
                                    property: "opacity"
                                    duration: 200
                                    to: 0.4
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: mediaDarken
                                    property: "opacity"
                                    duration: 200
                                    to: 0.2
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: artBgBlurred
                                    property: "opacity"
                                    duration: 200
                                    to: 0
                                    easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: mediaPlayer
                                    property: "artWidth"
                                    duration: 200
                                    to: 0
                                    easing.type: Easing.OutCubic
                                }
                            }
                            ScriptAction {
                                script: {
                                    if (mediaPlayer.artHovered) {artOpen.start()}
                                }
                            }
                        }

                        MediaPlayer {


                            id: mediaPlayer

                            property int pause: 200

                            anchors.top: parent.top
                            anchors.topMargin: 13
                            anchors.horizontalCenter: parent.horizontalCenter

                            onEntered: {
                                if (!artClose.running && mediaPlayer.artAvailable) {
                                    artClose.stop()
                                    artOpen.start()
                                }
                            }

                            onExited: {
                                if (!artOpen.running) {
                                    artOpen.stop()
                                    artClose.start()
                                }
                            }

                        }

                    }

                }
            }

            //Volumes and Mics
            WidgetsContainer {

                implicitWidth: 120
                implicitHeight: 425

                AudioControl {
                    anchors.centerIn: parent
                }

            }

            //Power buttons
            ColumnLayout {

                spacing: Config.gap

                Process {
                    id: power
                    onStarted: console.log("Hello")
                    stderr: StdioCollector {
                        onStreamFinished: {
                            if (text.trim()) {
                                SystemInfo.notifyerr(text)
                            }
                        }
                    }
                }


                //SHUTDOWN
                PowerButton {

                    icon_color: "#ec2727"

                    text: "\udb81\udc25"
                    font_size: 36

                    onReleased: power.exec(["bash", "-c", "systemctl poweroff"])

                }

                //HIBERNATE
                PowerButton {

                    icon_color: "#b72bee"

                    text: "\udb82\udd01"
                    font_size: 36

                    onReleased: power.exec(["bash", "-c", "systemctl hibernate"])
                }

                //SLEEP
                PowerButton {

                    icon_color: "#1f62ee"

                    text: "\udb82\udd04"
                    font_size: 32

                    onReleased: power.exec(["bash", "-c", "systemctl suspend"])
                }

                //REBOOT
                PowerButton {
                    icon_color: "#eea022"

                    text: "\uead2"
                    font_size: 32

                    onReleased: power.exec(["bash", "-c", "systemctl reboot"])
                }

                //LOCK
                PowerButton {

                    icon_color: "#38de31"

                    text: "\uf456"
                    font_size: 30

                    onReleased: power.exec(["bash", "-c", "notify-send 'LOCK'"])
                }

                //LOGOUT
                PowerButton {

                    icon_color: "#2fbcf0"

                    text: "\udb81\uddfd"
                    font_size: 32

                    onReleased: power.exec(["bash", "-c", "loginctl kill-user $USER"])
                }
            }
        }

        //Panel 2
        WidgetsPanel {

            index: 2

            WidgetsContainer {

                implicitWidth: 425
                implicitHeight: 425

                ClippingRectangle {

                    anchors.fill: parent

                    radius: Config.radius
                    color: "transparent"

                    Image {

                        anchors.fill: parent

                        fillMode: Image.PreserveAspectCrop
                        source: MediaPlayerInfo.artUrl

                        opacity: 0.3

                        layer.enabled: true
                        layer.effect: GaussianBlur {
                            radius: 30
                            samples: 30
                            cached: true
                        }

                    }
                }

                MediaPlayer2 {}


            }
            WidgetsContainer {
                implicitWidth: 1000-Config.gap*2-425-120
                implicitHeight: 425


            }
            WidgetsContainer {

                implicitWidth: 120
                implicitHeight: 425

                AudioControl {
                    anchors.centerIn: parent
                }

            }
        }

        //Panel 3
        WidgetsPanel {

            index: 3

            WidgetsContainer {
                implicitWidth: 1000
                implicitHeight: 425
            }
        }

    }

    RowLayout {

        id: panel_navigator

        opacity: root.panel_navigator

        Behavior on opacity {NumberAnimation {duration: 300; easing.type: Easing.OutCubic}}

        Layout.alignment: Qt.AlignCenter

        Text {
            text: "\uf0d9"
            font.family: Fonts.system
            font.pointSize: 12
            font.weight: 1000
            color: widgets.panel_index > 1 ? Color.textPrimary : Color.textDisabled
            MouseArea {
                anchors.fill: parent
                anchors.margins: -10

                hoverEnabled: true

                onReleased: {
                    root.advancePanel(-1)
                }
            }
        }
        WidgetsContainer {
            implicitHeight: 20
            implicitWidth: panel_page.implicitWidth + 20

            RowLayout {

                id: panel_page
                anchors.centerIn: parent

                Repeater {

                    model: 3

                    delegate: Rectangle {

                        required property int index

                        property bool selected: widgets.panel_index == index+1 

                        property real size: selected ? 8 : 6
                        implicitWidth: size
                        implicitHeight: size

                        Behavior on color {ColorAnimation {duration: 200; easing.type: Easing.OutCubic}}

                        color: selected ? Color.textPrimary : Color.textDisabled
                        radius: size/2
                    }
                }
            }

        }
        Text {
            text: "\uf0da"
            font.family: Fonts.system
            font.pointSize: 12
            font.weight: 1000
            color: widgets.panel_index < 3 ? Color.textPrimary : Color.textDisabled
            MouseArea {
                anchors.fill: parent
                anchors.margins: -10

                hoverEnabled: true

                onReleased: {
                    root.advancePanel(1)
                }
            }
        }


    }

}

