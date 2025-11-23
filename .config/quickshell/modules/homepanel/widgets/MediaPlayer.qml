pragma ComponentBehavior:Bound 

import qs.services
import qs.assets
import qs.modules.common

import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts
//import Qt5Compat.GraphicalEffects
import QtQuick

ColumnLayout {

    id: root

    property var sources: MediaPlayerInfo.sources

    spacing: 10

    Component.onCompleted: {
        KeyHandlers.released.connect((key) => {
            if (key == Qt.Key_Space) {
                MediaPlayerInfo.playPauseMedia()
            }
        })
    }

    Rectangle {

        id: mediaInfo

        implicitWidth: 322 - 20
        implicitHeight: 100
        color: "transparent"

        RowLayout {

            spacing: 4

            Item {

                implicitHeight: mediaInfo.implicitHeight
                implicitWidth: mediaInfo.implicitHeight

                ClippingRectangle {

                    id: artFrame

                    anchors.centerIn: parent

                    implicitHeight: parent.implicitHeight
                    implicitWidth: parent.implicitWidth
                    color: "transparent"
                    radius: 14


                    Image {

                        id: icon

                        visible: art.source

                        source: "image://icon/" + MediaPlayerInfo.entry
                        cache: true

                        fillMode: Image.PreserveAspectCrop

                        scale: 0.9

                        height: artFrame.implicitHeight
                        width: artFrame.implicitHeight

                    }

                    Image {

                        id: art

                        source: MediaPlayerInfo.artUrl
                        cache: true

                        fillMode: Image.PreserveAspectCrop

                        height: artFrame.implicitHeight
                        width: artFrame.implicitHeight

                    }

                }


            }

            ColumnLayout {

                spacing: 0

                Layout.alignment: Qt.AlignTop

                Rectangle {

                    implicitWidth: mediaInfo.implicitWidth - artFrame.implicitWidth - 4
                    implicitHeight: 40

                    color: "transparent"

                    MarqueeText {

                        anchors.bottom: parent.bottom

                        box_width: mediaInfo.implicitWidth - artFrame.implicitWidth - 4
                        centered: false
                        text: MediaPlayerInfo.title
                        font_family: Fonts.zzz_vn_font
                        font_size: {
                            Math.max(20-0.05*Math.max((paintedWidth-implicitWidth),0),16)
                        }
                    }
                }


                MarqueeText {
                    hoverable: true
                    visible: MediaPlayerInfo.album && (MediaPlayerInfo.album != MediaPlayerInfo.title)
                    box_width: mediaInfo.implicitWidth - artFrame.implicitWidth - 4
                    centered: false
                    text: MediaPlayerInfo.album
                    font_family: Fonts.zzz_vn_font
                    font_size: 10
                }

                MarqueeText {
                    hoverable: true
                    box_width: mediaInfo.implicitWidth - artFrame.implicitWidth - 4
                    centered: false
                    text: MediaPlayerInfo.artist
                    font_family: Fonts.zzz_vn_font
                    font_size: 12
                }
            }

        }
    }


    Rectangle {

        id: timestamp

        Layout.alignment: Qt.AlignCenter
        Layout.bottomMargin: -6

        implicitHeight: 10
        implicitWidth: 280

        property real size: 9

        color: "transparent"

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            text: MediaPlayerInfo.formatTime(MediaPlayerInfo.pos)
            font.family: Fonts.system 
            font.pointSize: parent.size
            font.weight: 700
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

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

        HorizontalProgressBar {

            id: progress

            box_height: 6
            box_width: parent.implicitWidth

            padding: 10

            preferedPercentage: (MediaPlayerInfo.pos/MediaPlayerInfo.length)*100

            interactive: true

            onAdjusted: {
                MediaPlayerInfo.setPosMedia((percentage/100)*MediaPlayerInfo.length)
                syncBar()
            }

            onPressed: {
                knob.opacity = 1
            }

            onReleased: {
                knob.opacity = 0
            }

            onEntered: {
                knob.opacity = 1
            }

            onExited: {
                knob.opacity = 0
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

            color: "light gray"

        }

    }


    RowLayout {

        spacing: 10

        Layout.alignment: Qt.AlignCenter

        PillButton {
            text: "\udb81\udcae"
            text_padding: 11
            centered: false
            font_family: Fonts.system
            box_width: 42
            box_height: 42
            font_size: 25

            onReleased: {
                MediaPlayerInfo.prevMedia()
            }
        }

        PillButton {
            text: {
                if (MediaPlayerInfo.status == "Playing") {
                    text_padding = 11
                    return "\udb80\udfe4"
                } else {
                    text_padding = 12.5
                    return "\udb81\udc0a"
                }
            }
            centered: false
            font_family: Fonts.system
            box_width: 42
            box_height: 42
            font_size: 25

            onReleased: {
                MediaPlayerInfo.playPauseMedia()
            }
        }

        PillButton {
            text: "\udb81\udcad"
            text_padding: 11
            centered: false
            font_family: Fonts.system
            box_width: 42
            box_height: 42
            font_size: 25

            onReleased: {
                MediaPlayerInfo.nextMedia()
            }
        }
    }


    PopupList {

        id: sourcesList

        Layout.leftMargin: -2

        text: MediaPlayerInfo.entry.toUpperCase()
        font_size: 12
        font_weight: 800
        marquee: true

        box_height: 32
        box_width: 150
        maxWidth: 150
        maxHeight: 92
        selected_centered: true
        selected_padding: 14
        selected_marquee: true
        selected_text: MediaPlayerInfo.entry.toUpperCase()
        selected_font_size: 12
        selected_font_weight: 800

        selected_list: false

        show_scroller: false

        items: MediaPlayerInfo.sources
        list_items: PillButton {
            required property string source
            required property string entry

            property bool selected: source == MediaPlayerInfo.currentSource

            text: entry.toUpperCase()
            font_size: 12
            font_weight: selected ? 800 : 700
            box_width: sourcesList.list_container_implicitWidth
            bg_color: selected ? ["#888888","light gray","gray"] : ["#aaaaaa","light gray","gray"]

            onReleased: {
                if (source != MediaPlayerInfo.currentSource) {
                    MediaPlayerInfo.pauseMedia()
                    MediaPlayerInfo.currentSource = source
                }
                sourcesList.closeList()
            }
        }
    }

}

