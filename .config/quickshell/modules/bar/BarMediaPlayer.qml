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


Rectangle {

    id: media_player

    visible: opacity

    property bool opened: false
    property var easing: Easing.OutCubic

    opacity: opened

    onOpacityChanged: {
        if (opacity == 1) {
            easing = Easing.InCubic
        } else if (opacity == 0) {
            easing = Easing.OutCubic
        }
    }

    Behavior on opacity {NumberAnimation {duration: 200; easing.type: media_player.easing}}

    implicitWidth: 460
    implicitHeight: 143

    color: Color.bgMuted

    radius: Config.radius

    layer.enabled: true
    layer.effect: DropShadow {
        radius: 10
        samples: 10
        color: Qt.rgba(0.0,0.0,0.0,0.3)
        transparentBorder: true
    }


    Rectangle {
        anchors.fill: parent
        anchors.margins: 2.5
        radius: Config.radius - anchors.margins
        color: Color.bgSurface
    }

    ClippingRectangle {

        anchors.fill: parent
        radius: Config.radius

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
                radius: 30
                samples: 60
                cached: true
            }

        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                implicitWidth: media_player.implicitWidth
                implicitHeight: media_player.implicitHeight

                gradient: Gradient {
                    GradientStop {position: 0.0; color: "white" }
                    GradientStop {position: 1.2; color: "transparent" }
                }
            }
        }

        BarVisualizer {
            anchors.fill: parent
            anchors.topMargin: -8
            anchors.bottomMargin: -8
            color: Qt.lighter(Color.accentSoft,1.2)
            opacity: 0.2
            scale: 0.9
            spacing: 4
            round: true
        }

    }


    ClippingRectangle {

        x: 13
        y: 12

        implicitWidth: 118
        implicitHeight: 118
        color: Color.bgMuted

        radius: Config.radius - 10

        Image {

            id: media_player_art

            visible: true

            anchors.fill: parent

            source: MediaPlayerInfo.artUrl
            fillMode: Image.PreserveAspectCrop

            opacity: status == Image.Ready ? 1 : 0
            Behavior on opacity {NumberAnimation {duration: 300; easing.type: Easing.OutCubic}}

        }

        layer.enabled: true
        layer.effect: DropShadow {
            radius: 10
            samples: 10
            color: Qt.rgba(0.0,0.0,0.0,0.3)
            transparentBorder: true
        }

    }

    Rectangle {

        anchors.fill: parent
        anchors.leftMargin: 136

        color: "transparent"

        layer.enabled: true
        layer.effect: DropShadow {
            radius: 10
            samples: 10
            color: Qt.rgba(0.0,0.0,0.0,0.3)
            transparentBorder: true
        }


        RowLayout {

            x: 12
            y: 73

            spacing: 10

            PillButton {

                Layout.alignment: Qt.AlignVCenter
                Layout.topMargin: -1

                text: {
                    if (MediaPlayerInfo.status == "playing") {
                        text_padding = 8
                        return "\udb80\udfe4"
                    } else {
                        text_padding = 9.5
                        return "\udb81\udc0a"
                    }
                }
                centered: false
                font_family: Fonts.system
                box_width: 30
                box_height: box_width
                font_size: 17

                verticalOffset: 1

                fg_color: [Color.bgBase, Color.bgBase, Color.bgBase]
                bg_color: [Color.accentStrong, Color.accentStrong, Color.textPrimary]
                border_width: [0,0,0]

                text_opacity: MediaPlayerInfo.canPlay && MediaPlayerInfo.canPause ? 1 : 0.25
                clickable: MediaPlayerInfo.canPlay && MediaPlayerInfo.canPause

                onReleased: {
                    MediaPlayerInfo.playPauseMedia()
                }
            }

            PopupList {

                id: sourcesList

                Layout.alignment: Qt.AlignVCenter

                text: MediaPlayerInfo.entry.toUpperCase()
                font_size: 11
                font_weight: 800
                marquee: true
                dropdown: true

                border_width: [2, 2, 2]
                border_color: [Color.accentStrong, Color.accentSoft, Color.accentStrong]

                box_height: 30
                box_width: 90
                maxWidth: box_width
                maxHeight: box_height*2 - list_spacing - 1
                selected_centered: true
                selected_padding: 14
                selected_marquee: true
                selected_text: MediaPlayerInfo.entry.toUpperCase()
                selected_font_size: font_size
                selected_font_weight: 800

                show_scroller: false

                selected_list: false

                items: MediaPlayerInfo.players

                list_items: Loader {

                    id: sources

                    active: root.visible

                    required property string dbusName
                    required property string desktopEntry
                    required property int index

                    sourceComponent: PillButton {
                        property string dbusName: sources.dbusName
                        property string desktopEntry: sources.desktopEntry
                        property int index: sources.index

                        property bool selected: dbusName == MediaPlayerInfo.dbusName

                        radius: sourcesList.radius - sourcesList.list_spacing + 1

                        text: desktopEntry.toUpperCase()
                        font_size: sourcesList.font_size
                        font_weight: selected ? 800 : 700
                        box_width: sourcesList.list_container_implicitWidth
                        box_height: sourcesList.box_height - 2
                        fg_color: selected ? [Color.textSecondary, Color.textSecondary, Color.textPrimary] :[Color.textPrimary, Color.textPrimary, Color.textPrimary] 
                        bg_color: selected ? [Qt.darker(Color.accentStrong,1.2),Qt.darker(Color.accentStrong,1.2),Color.bgSurface] : ["transparent",Color.bgBase,Color.bgSurface]
                        border_width: [0,0,2]

                        onReleased: {
                            if (dbusName != MediaPlayerInfo.activePlayer.dbusName) {
                                MediaPlayerInfo.pauseMedia()
                                MediaPlayerInfo.activePlayer = MediaPlayerInfo.players[index] 
                            }
                            sourcesList.closeList()
                        }
                    }
                }
            }

        }

        ColumnLayout {

            id: media_info

            anchors.top: parent.top
            anchors.topMargin: 8

            implicitWidth: 460 - 140 - 10

            spacing: -4


            Rectangle {

                implicitWidth: parent.implicitWidth
                implicitHeight: 40
                color: "transparent"

                MarqueeText {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    box_width: parent.implicitWidth

                    centered: false
                    text: MediaPlayerInfo.title
                    font_family: Fonts.zzz_vn_font
                    font_size: 22
                    font_minSize: 18
                    font_color: Color.textPrimary

                }
            }

            Rectangle {

                Layout.topMargin: -2

                implicitWidth: parent.implicitWidth
                implicitHeight: 30

                color: "transparent"

                Text {

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: 15

                    width: Math.min(implicitWidth, parent.implicitWidth-20)

                    elide: Text.ElideRight

                    text: MediaPlayerInfo.artist
                    font.family: Fonts.zzz_vn_font
                    font.pointSize: 14
                    color: Color.accentSoft

                }

            }

            Rectangle {

                id: timestamp

                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 24
                Layout.leftMargin: 8
                Layout.bottomMargin: 20

                implicitHeight: 10
                implicitWidth: parent.implicitWidth - 26

                property real size: 9

                color: "transparent"

                Text {

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    text: MediaPlayerInfo.formatTime(MediaPlayerInfo.pos) + " / " + MediaPlayerInfo.formatTime(MediaPlayerInfo.length)
                    font.family: Fonts.system 
                    font.pointSize: parent.size
                    font.weight: 800

                    color: Qt.lighter(Color.textDisabled,1.5)

                }

            }

            Item {

                id: progress_bar

                Layout.alignment: Qt.AlignHCenter
                Layout.leftMargin: 6

                implicitHeight: 6
                implicitWidth: parent.implicitWidth - 70


                HorizontalProgressBar {

                    id: progress

                    box_height: 5
                    box_width: parent.implicitWidth

                    padding: 10

                    preferedPercentage: (MediaPlayerInfo.pos/MediaPlayerInfo.length)*100

                    interactive: MediaPlayerInfo.canPos

                    bg_color: Color.bgMuted
                    bg_hover: Color.bgMuted
                    fg_color: knob.opacity ? Color.accentStrong : Color.textDisabled
                    fg_hover: Color.accentStrong

                    onAdjusted: {
                        MediaPlayerInfo.setPos((percentage/100)*MediaPlayerInfo.length)
                        syncBar()
                    }

                    onPressed: {
                        knob.opacity = 1
                    }

                    onReleased: {
                        if (!containsMouse) {
                            knob.opacity = 0
                        }
                    }

                    onEntered: {
                        knob.opacity = 1
                    }

                    onExited: {
                        if (!containsPress) {
                            knob.opacity = 0
                        }
                    }

                }
                Rectangle {

                    id: knob

                    opacity: 0
                    Behavior on opacity {NumberAnimation {duration: 100; easing.type: Easing.OutCubic}}

                    anchors.verticalCenter: progress.verticalCenter

                    x: progress.box_width*(progress.percentage/100) - implicitWidth/2
                    Behavior on x {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

                    implicitHeight: 14
                    implicitWidth: 14

                    radius: implicitWidth/2

                    color: Color.textPrimary

                }

                PillButton {

                    anchors.right: progress.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: progress.verticalCenter

                    text_opacity: MediaPlayerInfo.canPrev ? 1 : 0.25
                    clickable: MediaPlayerInfo.canPrev

                    text: "\udb81\udcae"
                    centered: true
                    verticalOffset: 0.2
                    font_family: Fonts.system
                    box_width: 26
                    box_height: box_width
                    font_size: 18

                    fg_color: MediaPlayerInfo.canPrev == true ? [Color.textPrimary, Color.textPrimary, Color.accentStrong] : [Color.textDisabled, Color.textDisabled, Color.bgSurface]
                    bg_color: ["transparent", "transparent", "transparent"]
                    border_width: [0,0,0]

                    onReleased: {
                        MediaPlayerInfo.prevMedia()
                    }
                }

                PillButton {

                    anchors.left: progress.right
                    anchors.leftMargin: 6
                    anchors.verticalCenter: progress.verticalCenter

                    text_opacity: MediaPlayerInfo.canNext ? 1 : 0.25
                    clickable: MediaPlayerInfo.canNext

                    text: "\udb81\udcad"
                    centered: true
                    verticalOffset: 0.2
                    font_family: Fonts.system
                    box_width: 26
                    box_height: box_width
                    font_size: 18

                    fg_color: MediaPlayerInfo.canNext == true ? [Color.textPrimary, Color.textPrimary, Color.accentStrong] : [Color.textDisabled, Color.textDisabled, Color.bgSurface]
                    bg_color: ["transparent", "transparent", "transparent"]
                    border_width: [0,0,0]

                    onReleased: {
                        MediaPlayerInfo.nextMedia()
                    }
                }

            }


        }



    }

}
