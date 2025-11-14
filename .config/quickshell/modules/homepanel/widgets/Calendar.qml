pragma ComponentBehavior:Bound

import qs.services
import qs.modules.common
import qs.assets

import Quickshell
import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    property var dayofweeks: ["MO","TU","WE","TH","FR","SA","SU"]

    property var dates: CalendarInfo.dates

    property int selectedDate: -1

    spacing: 16

    Text {

        id: months

        Layout.leftMargin: 4
        //Layout.alignment: Qt.AlignCenter

        text: DateTime.month_long
        font.family: Fonts.zzz_vn_font
        font.pointSize: 20
        font.weight: 800
    }


    GridLayout {

        Layout.alignment: Qt.AlignCenter

        id: dates

        columns: 7
        columnSpacing: 4
        rowSpacing: 2

        Repeater {

            model: root.dayofweeks

            delegate: Text {

                Layout.alignment: Qt.AlignCenter

                required property string modelData

                text: modelData
                font.family: Fonts.zzz_vn_font
                font.pointSize: 11
                font.weight: 900
            }

        }

        Repeater {

            id: days

            model: root.dates

            delegate: PillButton {

                Layout.alignment: Qt.AlignCenter

                required property int day
                required property bool inMonth
                required property bool isToday
                required property int index

                text: day
                font_family: Fonts.system
                box_height: 28
                box_width: box_height
                font_size: 10.5
                font_weight: isToday ? 800 : 600

                fg_color: {if (isToday || index == root.selectedDate) ["white", "white", "white"]; else if (inMonth) ["black", "black", "white"]; else ["gray", "gray", "black"]}
                bg_color: {if (isToday) ["black", "black", "gray"]; else if (index == root.selectedDate) ["gray", "gray", "black"]; else ["transparent", "light gray", "gray"]}

                onReleased: {
                    if (index != root.selectedDate) {
                        root.selectedDate = index
                    } else {
                        root.selectedDate = -1
                    }
                }

            }
        }

    }

}

