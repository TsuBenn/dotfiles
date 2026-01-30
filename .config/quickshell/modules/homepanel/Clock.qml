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

    id: homepanel_clock

    property int preferedWidth

    property string clock_font: Config.clock_font
    property int clock_weight: Config.clock_weight
    property string dateandmonth_font: Config.dateandmonth_font
    property int dateandmonth_weight: Config.dateandmonth_weight
    property int clock_size: Config.clock_size
    property int dateandmonth_size: Config.dateandmonth_size                       
    readonly property var debug_color: Qt.rgba(1,1,1,0.0)

    implicitWidth: preferedWidth
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
            color: Color.textPrimary
            font.family: Fonts.system
            font.pointSize: 28
        }
        Text {

            Layout.bottomMargin: -system_logo.implicitHeight/2 + this.implicitHeight*0.5

            text: "Uptime: " + (Uptime.hour > 0 ? Uptime.hour + "h" : "") + Uptime.minute + "m"
            color: Color.textPrimary
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
        anchors.rightMargin: 18
        anchors.bottomMargin: -4

        Text {
            text: SystemInfo.battery ?? "Inf"
            color: if (SystemInfo.batterystate == "charging" || SystemInfo.batterystate == "fully-charged") {
                return Qt.lighter(Color.success,1.2)
            } else if (parseInt(SystemInfo.battery) <= 20) {
                return Color.error
            } else return Color.textPrimary

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
                    color: Color.textPrimary
                }
            }


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
                    font.weight: Math.min(homepanel_clock.clock_weight * 1.5,1000)
                    font.pointSize: homepanel_clock.clock_size * 0.25
                    lineHeight: 0.7
                    horizontalAlignment: Text.AlignHCenter
                    color: Color.accentSoft
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
                color: Color.textPrimary
            }
        }
    }
}
