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

    signal closeHomepanel()

    onVisibleChanged: {
        power_buttons.active_power_button = ""
        power_buttons.power_countdown = 0
        power_timer.stop()
    }

    component PowerButton: PillButton {
        box_height: 65
        box_width: 65
        property color icon_color
        property string power_name
        property string icon
        property real size

        property bool active: power_timer.running && power_buttons.active_power_button == power_name 

        text: active ? "" : icon
        font_size: active ? 18 : size

        radius: Config.radius
        bg_color: [Color.bgSurface , Color.bgSurface, icon_color]
        fg_color: [active ? icon_color : Color.accentStrong, icon_color, Color.bgSurface]
        font_family: Fonts.system
        font_weight: 600
        border_width: [active ? 3 : 2,3,0]
        border_color: [active ? icon_color : Color.blend(Color.accentStrong,Color.bgSurface,0.75),icon_color,Color.accentStrong]

        ProgressCircle {

            visible: parent.active

            anchors.centerIn: parent
            fg_color: parent.icon_color
            percentage: (power_buttons.power_countdown/2)*100
            thickness: 4
            radius: 16
            icon: ""
            label: ""
        }
    }

    component WidgetsPanel: RowLayout {

        required property int index

        Layout.preferredWidth: 1000
        Layout.preferredHeight: 425

        x: (-implicitWidth - (SystemInfo.monitorwidth-1000)/2) * (widgets.panel_index - index)

        //opacity: widgets.panel_index == index
        z: widgets.panel_index == index ? 0 : -2

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
                                        radius: 30
                                        samples: 60
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
                                        samples: 60
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

                id: power_buttons

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

                property int power_countdown: 0
                property string active_power_button: ""

                function startTimer() {
                    power_countdown = 2
                    power_timer.restart()
                }

                Timer {
                    id: power_timer

                    interval: 1000

                    onTriggered: {
                        if (power_buttons.power_countdown == 0) {
                            power.startDetached()
                            power_buttons.power_countdown = 0
                            power_buttons.active_power_button = ""
                            return
                        }
                        power_buttons.power_countdown -= 1
                        power_timer.restart()
                    }
                }

                //SHUTDOWN
                PowerButton {

                    icon_color: "#ec2727"

                    icon: "\udb81\udc25"

                    power_name: "shutdown"

                    size: 36

                    onReleased: {
                        if (power_buttons.power_countdown > 0 && power_name == power_buttons.active_power_button) {
                            power_buttons.power_countdown = 0
                            power_timer.stop()
                            return
                        }
                        power_buttons.active_power_button = power_name
                        power_buttons.startTimer()
                        power.command = ["bash", "-c", "systemctl poweroff"] 
                    }

                }

                //HIBERNATE
                PowerButton {

                    icon_color: "#b72bee"

                    icon: "\udb82\udd01"

                    power_name: "hibernate"

                    size: 36

                    onReleased: {
                        if (power_buttons.power_countdown > 0 && power_name == power_buttons.active_power_button) {
                            power_buttons.power_countdown = 0
                            power_timer.stop()
                            return
                        }
                        power_buttons.active_power_button = power_name
                        power_buttons.startTimer()
                        power.command = ["bash", "-c", "systemctl hibernate"]
                    }
                }

                //SLEEP
                PowerButton {

                    icon_color: "#1f62ee"

                    icon: "\udb82\udd04"

                    power_name: "sleep"

                    size: 32

                    onReleased: {
                        if (power_buttons.power_countdown > 0 && power_name == power_buttons.active_power_button) {
                            power_buttons.power_countdown = 0
                            power_timer.stop()
                            return
                        }
                        power_buttons.active_power_button = power_name
                        power_buttons.startTimer()
                        power.command = ["bash", "-c", "systemctl suspend"]
                    }
                }

                //REBOOT
                PowerButton {
                    icon_color: "#eea022"

                    icon: "\uead2"

                    power_name: "reboot"

                    size: 32

                    onReleased: {
                        if (power_buttons.power_countdown > 0 && power_name == power_buttons.active_power_button) {
                            power_buttons.power_countdown = 0
                            power_timer.stop()
                            return
                        }
                        power_buttons.active_power_button = power_name
                        power_buttons.startTimer()
                        power.command = ["bash", "-c", "systemctl reboot"]
                    }
                }

                //LOCK
                PowerButton {

                    icon_color: "#38de31"

                    icon: "\uf456"

                    power_name: "lock"

                    size: 30

                    onReleased: {
                        if (power_buttons.power_countdown > 0 && power_name == power_buttons.active_power_button) {
                            power_buttons.power_countdown = 0
                            power_timer.stop()
                            return
                        }
                        power_buttons.active_power_button = power_name
                        power_buttons.startTimer()
                        power.command = ["kitty"]
                    }
                }

                //LOGOUT
                PowerButton {

                    icon_color: "#2fbcf0"

                    icon: "\udb81\uddfd"

                    power_name: "logout"

                    size: 32

                    onReleased: {
                        if (power_buttons.power_countdown > 0 && power_name == power_buttons.active_power_button) {
                            power_buttons.power_countdown = 0
                            power_timer.stop()
                            return
                        }
                        power_buttons.active_power_button = power_name
                        power_buttons.startTimer()
                        power.command = ["spotify"]
                    }
                }
            }
        }

        //Panel 2
        WidgetsPanel {

            index: 2

            //Media Player 2 (MP2)
            WidgetsContainer {

                implicitWidth: 425
                implicitHeight: 425

                ClippingRectangle {

                    id: artBg2

                    anchors.fill: parent

                    radius: Config.radius
                    color: "transparent"


                    Image {

                        anchors.fill: parent

                        fillMode: Image.PreserveAspectCrop
                        source: MediaPlayerInfo.artUrl

                        opacity: status == Image.Ready ? 0.4 : 0
                        Behavior on opacity {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

                        layer.enabled: true
                        layer.effect: GaussianBlur {
                            radius: 30
                            samples: 60
                            cached: true
                        }

                    }


                    BarVisualizer {

                        id: mp2_bar

                        visible: MediaPlayerInfo.activePlayer

                        anchors.fill: parent
                        anchors.bottomMargin: 200
                        scale: 0.92
                        x: -2

                        spacing: 4
                        round: true
                        opacity: 0.4

                        maxHeight: 300

                        color: Qt.lighter(Color.accentSoft,1.2)

                        centered: true

                    }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            implicitWidth: artBg.implicitWidth
                            implicitHeight: artBg.implicitHeight

                            gradient: Gradient {
                                GradientStop {position: 0.0; color: "white" }
                                GradientStop {position: 0.7; color: "transparent" }
                            }
                        }
                    }
                }

                Text {

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -70

                    visible: !MediaPlayerInfo.activePlayer

                    text: "No Media Player Active"
                    font.family: Fonts.system
                    font.pointSize: 13
                    font.weight: 700
                    color: Qt.lighter(Color.bgMuted,1.5)

                }

                MediaPlayer2 {
                    anchors.centerIn: parent
                }


            }
            WidgetsContainer {
                implicitWidth: 1000-Config.gap*2-425-120
                implicitHeight: 425

                Rectangle {
                    id: mixer_header

                    implicitWidth: parent.implicitWidth
                    implicitHeight: 34

                    color: "transparent"

                    Text {

                        y: 12
                        x: 12

                        text: "App Volumes"
                        font.family: Fonts.system
                        font.pointSize: 12
                        font.weight: 700
                        color: Color.textDisabled
                    }
                }

                AudioMixer {
                    anchors.top: mixer_header.bottom
                    anchors.bottom: parent.bottom
                    implicitWidth: parent.implicitWidth
                }

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
                anchors.topMargin: -10
                anchors.bottomMargin: -50
                anchors.leftMargin: -200
                anchors.rightMargin: -10

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
                anchors.topMargin: -10
                anchors.bottomMargin: -50
                anchors.leftMargin: -10
                anchors.rightMargin: -200

                hoverEnabled: true

                onReleased: {
                    root.advancePanel(1)
                }
            }
        }


    }

}

