pragma ComponentBehavior:Bound 

import qs.services
import qs.assets
import qs.modules.common

import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import QtQuick

ColumnLayout {

    id: root

    property real artWidth: 0
    property real artHeight: mediaInfo.implicitHeight
    property real artAvailable: art.source != ""

    property bool artHovered: false

    signal entered()
    signal exited()

    spacing: 6


    Rectangle {

        id: mediaInfo

        implicitWidth: 322 - 20
        implicitHeight: 100
        color: "transparent"

        Layout.bottomMargin: 8


        layer.enabled: true
        layer.effect: DropShadow {
            radius: 10
            samples: 20
            color: Qt.rgba(0.0,0.0,0.0,0.5*(1-root.artWidth/root.artHeight))
            transparentBorder: true
            cached: true
        }

        MouseArea {

            anchors.fill: parent

            z:1

            hoverEnabled: true

            acceptedButtons: Qt.NoButton

            onContainsMouseChanged: {
                root.artHovered = containsMouse
            }

            onEntered: {
                root.entered()
            }
            onExited: {
                root.exited()
            }
        }

        RowLayout {

            anchors.left: parent.left

            spacing: 0

            Item {

                id: playerArt

                property int pause: 200

                implicitHeight: mediaInfo.implicitHeight
                implicitWidth: root.artWidth

                ClippingRectangle {

                    anchors.verticalCenter: parent.verticalCenter

                    id: artFrame

                    implicitHeight: art.source == "" ? 0 : (art.sourceSize.height/art.sourceSize.width)*parent.implicitHeight
                    implicitWidth: parent.implicitWidth
                    color: "transparent"
                    radius: 14

                    Image {

                        id: art

                        source: MediaPlayerInfo.artUrl
                        cache: true

                        fillMode: Image.PreserveAspectCrop

                        height: artFrame.implicitHeight
                        width: artFrame.implicitWidth

                    }

                }


            }

            ColumnLayout {

                spacing: 0

                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 2

                Rectangle {

                    implicitWidth: mediaInfo.implicitWidth - artFrame.implicitWidth - 4
                    implicitHeight: 40

                    function adjustText(text) {
                        return text.replace(/([\u3040-\u30FF\u4E00-\u9FFF]+)/g,
                        '<span>$1</span>');
                    }

                    color: "transparent"

                    MarqueeText {

                        id: title

                        anchors.bottom: parent.bottom

                        padding: 10
                        box_width: mediaInfo.implicitWidth - artFrame.implicitWidth - 4
                        centered: false
                        text: MediaPlayerInfo.title
                        font_family: Fonts.zzz_vn_font
                        font_size: 25
                        font_minSize: 18
                        font_color: "white"

                    }
                }


                MarqueeText {
                    hoverable: true
                    visible: MediaPlayerInfo.album && (MediaPlayerInfo.album != MediaPlayerInfo.title)
                    padding: 12
                    box_width: mediaInfo.implicitWidth - artFrame.implicitWidth - 4
                    centered: false
                    text: MediaPlayerInfo.album
                    font_family: Fonts.zzz_vn_font
                    font_size: 10
                    font_color: "white"
                }

                MarqueeText {
                    padding: 12
                    hoverable: true
                    box_width: mediaInfo.implicitWidth - artFrame.implicitWidth - 4
                    centered: false
                    text: MediaPlayerInfo.artist
                    font_family: Fonts.zzz_vn_font
                    font_size: 14
                    font_color: "white"
                }

            }

        }
    }


    Rectangle {

        id: timestamp

        Layout.alignment: Qt.AlignCenter
        Layout.bottomMargin: -2

        implicitHeight: 10
        implicitWidth: 280

        property real size: 8

        color: "transparent"

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            text: MediaPlayerInfo.formatTime(MediaPlayerInfo.pos)
            font.family: Fonts.system 
            font.pointSize: parent.size
            font.weight: 700

            color: Color.textDisabled

        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            color: Color.textDisabled

            text: MediaPlayerInfo.formatTime(MediaPlayerInfo.length)
            font.family: Fonts.system 
            font.pointSize: parent.size
            font.weight: 700
        }

    }

    Item {

        implicitHeight: 6
        implicitWidth: 290

        Layout.alignment: Qt.AlignCenter
        Layout.bottomMargin: 3

        HorizontalProgressBar {

            id: progress

            box_height: 5
            box_width: parent.implicitWidth

            padding: 10

            preferedPercentage: (MediaPlayerInfo.pos/MediaPlayerInfo.length)*100

            interactive: MediaPlayerInfo.canPos

            bg_color: Color.bgMuted
            bg_hover: Color.bgMuted
            fg_color: knob.opacity ? Color.accentStrong : Color.textSecondary
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

            color: Color.textSecondary

        }

    }


    RowLayout {

        spacing: 10

        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 2
        Layout.bottomMargin: Layout.topMargin + 2

        PillButton {

            text_opacity: MediaPlayerInfo.canShuffle && MediaPlayerInfo.shuffleStatus == true ? 1 : 0.25
            clickable: MediaPlayerInfo.canShuffle

            text: {
                if (MediaPlayerInfo.shuffleStatus == true ) {
                    text_padding = 9
                    return "\udb81\udc9d"
                } else {
                    text_padding = 9.5
                    return "\udb81\udc9e"
                }
            }
            text_padding: 8
            centered: false
            font_family: Fonts.system
            box_width: 38
            box_height: 38
            font_size: {
                if (MediaPlayerInfo.shuffleStatus == true ) {
                    return 21
                } else {
                    return 25
                }
            }

            fg_color: MediaPlayerInfo.shuffleStatus == true ? [Color.accentStrong, Color.accentStrong, Color.bgSurface] : [Color.textDisabled, Color.textDisabled, Color.bgSurface]
            bg_color: ["transparent", Color.bgBase, Color.accentStrong]
            border_width: [0,0,0]

            onReleased: {
                MediaPlayerInfo.toggleShuffle()
            }
        }

        PillButton {

            text_opacity: MediaPlayerInfo.canPrev ? 1 : 0.25
            clickable: MediaPlayerInfo.canPrev

            text: "\udb81\udcae"
            text_padding: 8.5
            centered: false
            font_family: Fonts.system
            box_width: 36
            box_height: box_width
            font_size: 25

            fg_color: MediaPlayerInfo.canPrev == true ? [Color.textSecondary, Color.textSecondary, Color.bgSurface] : [Color.textDisabled, Color.textDisabled, Color.bgSurface]
            bg_color: ["transparent", Color.bgBase, Color.accentStrong]
            border_width: [0,0,0]

            onReleased: {
                MediaPlayerInfo.prevMedia()
            }
        }

        PillButton {
            text: {
                if (MediaPlayerInfo.status == "playing") {
                    text_padding = 9
                    return "\udb80\udfe4"
                } else {
                    text_padding = 10.5
                    return "\udb81\udc0a"
                }
            }
            centered: false
            font_family: Fonts.system
            box_width: 36
            box_height: box_width
            font_size: 23

            fg_color: [Color.bgBase, Color.bgBase, Color.bgBase]
            bg_color: [Color.textSecondary, Color.textSecondary, Color.accentStrong]
            border_width: [0,0,0]

            text_opacity: MediaPlayerInfo.canPlay && MediaPlayerInfo.canPause ? 1 : 0.25
            clickable: MediaPlayerInfo.canPlay && MediaPlayerInfo.canPause

            onReleased: {
                MediaPlayerInfo.playPauseMedia()
            }
        }

        Timer {
            interval: 1000
            running: MediaPlayerInfo.status == "playing"
            repeat: true
            onTriggered: {
                MediaPlayerInfo.requestPos()
            }
        }

        PillButton {

            text_opacity: MediaPlayerInfo.canNext ? 1 : 0.25
            clickable: MediaPlayerInfo.canNext

            text: "\udb81\udcad"
            text_padding: 8.5
            centered: false
            font_family: Fonts.system
            box_width: 36
            box_height: box_width
            font_size: 25

            fg_color: MediaPlayerInfo.canNext == true ? [Color.textSecondary, Color.textSecondary, Color.bgSurface] : [Color.textDisabled, Color.textDisabled, Color.bgSurface]
            bg_color: ["transparent", Color.bgBase, Color.accentStrong]
            border_width: [0,0,0]

            onReleased: {
                MediaPlayerInfo.nextMedia()
            }
        }

        PillButton {
            text: {
                if (MediaPlayerInfo.loopStatus == "track") {
                    return "\udb81\udc58"
                } else {
                    return "\udb81\udc56"
                }
            }
            text_padding: 8
            centered: false
            font_family: Fonts.system
            box_width: 38
            box_height: 38
            font_size: 22

            fg_color: MediaPlayerInfo.loopStatus != "none" ? [Color.accentStrong, Color.accentStrong, Color.bgSurface] : [Color.textDisabled, Color.textDisabled, Color.bgSurface]
            bg_color: ["transparent", Color.bgBase, Color.accentStrong]
            border_width: [0,0,0]

            text_opacity: (MediaPlayerInfo.canLoop && MediaPlayerInfo.loopStatus != "none") ? 1 : 0.25
            clickable: MediaPlayerInfo.canLoop

            onReleased: {
                MediaPlayerInfo.itterateLoop()
            }
        }
    }

    PopupList {

        id: sourcesList

        Layout.topMargin: 2
        Layout.alignment: Qt.AlignCenter

        text: MediaPlayerInfo.entry.toUpperCase()
        font_size: 12
        font_weight: 800
        marquee: true

        box_height: 32
        box_width: 120
        maxWidth: box_width
        maxHeight: box_height*2 - list_spacing
        selected_centered: true
        selected_padding: 14
        selected_marquee: true
        selected_text: MediaPlayerInfo.entry.toUpperCase()
        selected_font_size: 12
        selected_font_weight: 800

        selected_list: false

        items: MediaPlayerInfo.players

        list_items: PillButton {
            required property string dbusName
            required property string desktopEntry
            required property int index

            property bool selected: dbusName == MediaPlayerInfo.dbusName

            radius: sourcesList.radius - sourcesList.list_spacing

            text: desktopEntry.toUpperCase()
            font_size: 12
            font_weight: selected ? 800 : 700
            box_width: sourcesList.list_container_implicitWidth
            fg_color: selected ? [Color.textPrimary, Color.textPrimary, Color.textPrimary] :[Color.textPrimary, Color.textPrimary, Color.textPrimary] 
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

