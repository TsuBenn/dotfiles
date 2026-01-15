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

RowLayout {

    component Widgets: ClippingRectangle {
        radius: Config.radius
    }

    spacing: Config.gap

    ColumnLayout {

        spacing: Config.gap

        //User Profile
        Rectangle {
            implicitWidth: 210
            implicitHeight: 294
            radius: Config.radius
            UserProfile {
                anchors.centerIn: parent
            }
        }

        //Weather
        Widgets {
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
        Widgets {
            implicitWidth: 585
            implicitHeight: 170
            Performance {
                anchors.centerIn: parent
            }
        }

        RowLayout {

            spacing: Config.gap

            //Calendar
            Widgets {
                implicitWidth: 256
                implicitHeight: 248

                property var date: CalendarInfo.dates

                Calendar {

                    anchors.centerIn: parent

                }

            }

            //Media Player
            Widgets {

                implicitWidth: 321
                implicitHeight: 248

                ClippingRectangle {

                    id: mediaBg

                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.left: parent.left

                    implicitHeight: 120

                    radius: Config.radius
                    topRightRadius: 0
                    topLeftRadius: 0


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
                            color: "gray"
                        }

                        Image {

                            id: artBg

                            anchors.verticalCenter: parent.verticalCenter

                            width: parent.width
                            height: (sourceSize.height/sourceSize.width)*width
                            cache: true

                            visible: true

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
                            to: 0.25
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
                    anchors.topMargin: 10
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
    Widgets {

        visible: true

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
        PillButton {

            box_height: 65
            box_width: 65

            radius: Config.radius

            bg_color: ["white", "#ec2727", "#b61212"]

            fg_color: ["black", "white", "white"]

            text: "\udb81\udc25"
            font_size: 40

            onReleased: power.exec(["bash", "-c", "systemctl poweroff"])
        }

        //HIBERNATE
        PillButton {

            box_height: 65
            box_width: 65

            radius: Config.radius

            bg_color: ["white", "#b72bee", "#8515b0"]

            fg_color: ["black", "white", "white"]

            text: "\udb82\udd01"
            font_size: 40

            onReleased: power.exec(["bash", "-c", "systemctl hibernate"])
        }

        //SLEEP
        PillButton {

            box_height: 65
            box_width: 65

            radius: Config.radius

            bg_color: ["white", "#1f62ee", "#0e48c1"]

            fg_color: ["black", "white", "white"]

            text: "\udb82\udd04"
            font_size: 36

            onReleased: power.exec(["bash", "-c", "systemctl suspend"])
        }

        //REBOOT
        PillButton {

            box_height: 65
            box_width: 65

            radius: Config.radius

            bg_color: ["white", "#eea022", "#c57d0a"]

            fg_color: ["black", "white", "white"]

            text: "\uead2"
            font_size: 36

            onReleased: power.exec(["bash", "-c", "systemctl reboot"])
        }

        //LOCK
        PillButton {

            box_height: 65
            box_width: 65

            radius: Config.radius


            bg_color: ["white", "#38de31", "#1db816"]

            fg_color: ["black", "white", "white"]

            text: "\uf456"
            font_size: 32

            onReleased: power.exec(["bash", "-c", "notify-send 'LOCK'"])
        }

        //LOGOUT
        PillButton {

            box_height: 65
            box_width: 65

            radius: Config.radius

            bg_color: ["white", "#2fbcf0", "#1194c3"]

            fg_color: ["black", "white", "white"]

            text: "\udb81\uddfd"
            font_size: 38

            onReleased: power.exec(["bash", "-c", "loginctl kill-user $USER"])
        }
    }
}
