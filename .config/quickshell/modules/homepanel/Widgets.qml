pragma ComponentBehavior:Bound

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

            //Media Player
            Widgets {
                implicitWidth: 321
                implicitHeight: 248

                MediaPlayer {

                    id: mediaPlayer


                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter

                }
            }

            //Calendar
            Widgets {
                implicitWidth: 256
                implicitHeight: 248

                property var date: CalendarInfo.dates

                Calendar {

                    anchors.centerIn: parent

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
