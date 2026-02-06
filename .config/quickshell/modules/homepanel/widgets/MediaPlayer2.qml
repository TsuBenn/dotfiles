import qs.assets
import qs.modules.common
import qs.modules.homepanel
import qs.services
import qs.modules.homepanel.widgets

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

ColumnLayout {

    anchors.centerIn: parent

    spacing: 0

    ClippingRectangle {

        Layout.alignment: Qt.AlignHCenter
        Layout.margins: 16

        implicitHeight: 160
        implicitWidth: implicitHeight

        radius: Config.radius
        color: "transparent"

        Image {

            anchors.fill: parent

            fillMode: Image.PreserveAspectCrop
            source: MediaPlayerInfo.artUrl

        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 400
        implicitHeight: 48
        color: "transparent"

        MarqueeText {
            anchors.bottom: parent.bottom
            box_width: parent.implicitWidth
            centered: true
            text: MediaPlayerInfo.title
            font_family: Fonts.zzz_vn_font
            font_size: 30
            font_minSize: 20
            font_color: Color.textPrimary
        }

    }

    Text {

        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: -4

        text: `${MediaPlayerInfo.album ? MediaPlayerInfo.album + " - " : ""}${MediaPlayerInfo.artist}`
        font.family: Fonts.zzz_vn_font
        font.pointSize: 18
        color: Color.textPrimary
    }

    RowLayout {

        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 20

        PillButton {

        }
    }

}





