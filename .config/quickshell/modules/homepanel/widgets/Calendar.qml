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

    property var date: DateTime.date
    property var dates: CalendarInfo.dates

    onDateChanged: {
        root.dates = CalendarInfo.dates
    }

    property int selectedDate: -1

    spacing: 16

    Text {

        id: months

        Layout.leftMargin: 4
        //Layout.alignment: Qt.AlignCenter

        text: DateTime.month_long
        color: Color.accentStrong
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
                color: Color.accentSoft
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

                fg_color: if (isToday) {
                    return [Color.textPrimary, Color.accentStrong, Color.bgBase]
                } else if (index == root.selectedDate) {
                    return [Color.bgBase, Color.warn, Color.bgBase]
                } else if (inMonth) {
                    return [Color.accentSoft, Color.textPrimary, Color.bgBase]
                } else {
                    return [Color.textDisabled, Color.textDisabled, Color.textPrimary]
                }

                bg_color: if (isToday) {
                    return [Color.accentStrong, Color.bgSurface, Color.accentStrong]
                } else if (index == root.selectedDate) {
                    return [Color.warn, Color.bgSurface, Color.warn]
                } else {
                    ["transparent", Color.bgBase, Color.warn]
                }

                border_width: if (isToday) {
                    return [0,2,0]
                } else if (index == root.selectedDate) {
                    return [0,2,0]
                } else {
                    [0,0,0]
                }
                border_color: if (isToday) {
                    if (index == root.selectedDate) {
                        return [0,Color.warn,0]
                    } else {
                        return [0,Color.accentStrong,0]
                    }
                } else if (index == root.selectedDate) {
                    return [Color.warn,Color.warn,Color.warn]
                } else {
                    ["transparent", Color.bgBase, Color.warn]
                }

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

