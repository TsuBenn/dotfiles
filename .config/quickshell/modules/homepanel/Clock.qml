pragma ComponentBehavior:Bound 

import qs.assets
import qs.services
import qs.modules.homepanel

import Quickshell
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick

//Clock
Item {

    component Clock: Rectangle {

        required property string content 

        implicitWidth: clock_size_reference.implicitWidth
        implicitHeight: clock_size_reference.implicitHeight * 0.8
        color: homepanel_clock.debug_color
        Text {
            id: clock_size_reference
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: parent.content
            font.family: homepanel_clock.clock_font
            font.weight: homepanel_clock.clock_weight
            font.pointSize: homepanel_clock.clock_size
            color: "white"
        }
    }

    id: homepanel_clock

    property string clock_font: Config.clock_font
    property int clock_weight: Config.clock_weight
    property string dateandmonth_font: Config.dateandmonth_font
    property int dateandmonth_weight: Config.dateandmonth_weight
    property int clock_size: Config.clock_size
    property int dateandmonth_size: Config.dateandmonth_size                       
    readonly property var debug_color: Qt.rgba(1,1,1,0.0)

    implicitWidth: 1000
    implicitHeight: 230

    //Uptime
    RowLayout {

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 22
        anchors.bottomMargin: -8

        spacing: 10

        Text {
            id: system_logo
            text: SystemInfo.systemUTF
            color: "white"
            font.family: Fonts.system
            font.pointSize: 28
        }
        Text {

            Layout.bottomMargin: -system_logo.implicitHeight/2 + this.implicitHeight*0.5

            text: "Uptime: " + (Uptime.hour > 0 ? Uptime.hour + "h" : "") + Uptime.minute + "m"
            color: "white"
            font.family: Fonts.system
            font.wordSpacing: -4
            font.pointSize: 12
            font.weight: 600
        }
    }

    //Battery
    RowLayout {

        //visible: SystemInfo.onbattery

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.bottomMargin: -8

        spacing: 4

        Text {
            id: battery
            text: "\uf244"
            color: "white"
            font.family: Fonts.system
            font.pointSize: 18

            Rectangle {

                property real percentage: parseInt(SystemInfo.battery.match(/\d+/)?.[0] ?? 100)/100

                x: 4
                y: 13
                z: -1

                color:
                if (percentage >= 0.85 || SystemInfo.batterystate == "charging") {
                    return "#2eff62"
                } else if (percentage <= 0.2) {
                    return "#ed312b"
                } else {
                    return "white"
                }

                implicitHeight: 6
                implicitWidth: 15.6*percentage
            }

            ColorOverlay {
                visible: charging.visible
                anchors.fill: charging
                color: "black"
                source: charging
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 2
                    samples: 20
                    spread: 0.88
                    color: "black"
                }
            }

            Text {

                visible: SystemInfo.batterystate == "charging" || SystemInfo.batterystate == "fully-charged" || !SystemInfo.onbattery

                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 0.5
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: -2

                id: charging
                textFormat: Text.MarkdownText
                text: "\u26a1"
                color: "white"
                font.family: Fonts.system
                font.pointSize: 11
                layer.enabled: true
                layer.effect: ColorOverlay {
                    color: "#f1ff75"
                }
            }

        }
        Text {
            text: SystemInfo.battery ?? "Inf"
            color: "white"
            font.family: Fonts.system
            font.wordSpacing: -4
            font.pointSize: 10.5
            font.weight: 700
        }
    }

    //Clock
    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -8

        spacing: -12

        //Time
        RowLayout {

            Layout.alignment: Qt.AlignCenter
            spacing: -4

            //Hour
            Clock {
                content: DateTime.hour12
            }

            //AM or PM
            Rectangle {
                implicitWidth: 40
                implicitHeight: 70
                color: homepanel_clock.debug_color
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 0
                    text: DateTime.ampm[0] + "\n" + DateTime.ampm[1]
                    font.family: homepanel_clock.clock_font
                    font.weight: homepanel_clock.clock_weight * 1.2
                    font.pointSize: homepanel_clock.clock_size * 0.25
                    lineHeight: 0.7
                    horizontalAlignment: Text.AlignHCenter
                    color: "white"
                }
            }
            //Minute
            Clock {
                content: DateTime.minute
            }
        }

        //Date and Months
        Rectangle {

            Layout.alignment: Qt.AlignCenter

            implicitWidth: 300
            implicitHeight: 45
            color: homepanel_clock.debug_color
            Text {
                anchors.centerIn: parent
                text: DateTime.dayofweek_short + ", " + DateTime.date + " " + DateTime.month_short
                font.wordSpacing: -15
                font.family: homepanel_clock.dateandmonth_font
                font.weight: homepanel_clock.dateandmonth_weight
                font.pointSize: homepanel_clock.dateandmonth_size
                color: "white"
            }
        }
    }
}
