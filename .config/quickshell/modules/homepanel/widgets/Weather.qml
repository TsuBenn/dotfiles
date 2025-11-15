import qs.services
import qs.assets
import qs.modules.common

import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {

    id: root

    property string temp_font: Fonts.system
    property string condition_font: Fonts.zzz_vn_font
    property int temp_size: 52
    property int temp_unit_size: 15
    property int icon_size: 62
    property int condition_size: 13
    property string text_color: "white"

    property bool toggleinfo: false

    color: "black"

    MouseControl {

        anchors.fill: parent

        onPressed: {
            toggle.start()
        }
    }

    Image {

        id: background

        anchors.centerIn: parent

        property int index: {
            if (WeatherInfo.condition_icon == "🌤" ||WeatherInfo.condition_icon == "⛅️") {
                return 3
            } else if (WeatherInfo.condition_icon =="🌦" ||WeatherInfo.condition_icon == "🌧") {
                return 4
            } else if (WeatherInfo.condition_icon =="⛈" || WeatherInfo.condition_icon =="🌩") {
                return 1
            } else if (WeatherInfo.condition_icon =="☀️") {
                return 0
            } else if (WeatherInfo.condition_icon =="☁" ||WeatherInfo.condition_icon =="🌫" ) {
                return 2
            }
        }

        source: "../../../assets/images/weathers.jpg"

        scale: 0.5

        transform: [Translate {x: background.height-(background.height/2)*background.index}]

        cache: true
        asynchronous: true

        opacity: 0.9

    }

    DropShadow {
        anchors.fill: text
        source: text
        horizontalOffset: 0
        verticalOffset: 0
        radius: 10
        color: "black"
        opacity: 0.5 
    }

    ColumnLayout {

        id: text


        spacing: -8

        anchors.centerIn: parent

        RowLayout {

            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: -8

            spacing: -4

            Text {

                id: temp

                text: WeatherInfo.temperature
                font.family: root.temp_font
                font.pointSize: root.temp_size
                font.weight: 700
                font.letterSpacing: -5
                color: root.text_color


            }

            Text {

                id: temp_unit

                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 10

                layer.enabled: true

                text: "°C"
                font.family: root.temp_font
                font.pointSize: root.temp_unit_size
                font.weight: 800
                color: root.text_color

            }

            Text {
                id: icon

                property bool exception: WeatherInfo.condition_icon == "🌫" 

                Layout.leftMargin: exception ? 10 : 0 
                Layout.rightMargin: exception ? 0 : -10

                text: WeatherInfo.condition_icon
                font.family: "Noto Color Emoji"
                font.pointSize: exception ? root.icon_size*0.8 : root.icon_size
            }

        }

        SequentialAnimation {
            id: toggle
            ParallelAnimation{
                NumberAnimation {
                    target: condition
                    property: "opacity"
                    duration: 200
                    from: 1
                    to: 0
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: location
                    property: "opacity"
                    duration: 200
                    from: 1
                    to: 0
                    easing.type: Easing.InCubic
                }
            }
            ScriptAction {script: root.toggleinfo = !root.toggleinfo}
            PauseAnimation {duration: 100}
            ParallelAnimation {
                NumberAnimation {
                    target: condition
                    property: "opacity"
                    duration: 200
                    from: 0
                    to: 1
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: location
                    property: "opacity"
                    duration: 200
                    from: 0
                    to: 1
                    easing.type: Easing.OutCubic
                }
            }
        }

        MarqueeText {

            id: condition

            visible: !root.toggleinfo

            text: WeatherInfo.condition.toUpperCase().trim()

            box_width: 196
            font_family: root.condition_font
            font_size: root.condition_size
            font_weight: 800
            font_color: root.text_color
            spacing: -6
        }

        MarqueeText {

            id: location

            visible: root.toggleinfo

            text: WeatherInfo.location.toUpperCase()

            box_width: 190
            font_family: root.condition_font
            font_size: root.condition_size
            font_weight: 800
            font_color: root.text_color
            spacing: -6
        }

    }
}
