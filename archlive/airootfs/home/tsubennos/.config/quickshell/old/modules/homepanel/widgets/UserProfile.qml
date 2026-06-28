import qs.services
import qs.assets
import qs.modules.common

import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: userprofile

    property string font: Fonts.zzz_vn_font

    property int font_weight: 700

    ClippingRectangle {

        implicitWidth: 168
        implicitHeight: implicitWidth

        radius: implicitWidth/2

        id: pfp

        border {
            width: 0
            color: Color.textSecondary
        }

        color: Color.bgBase

        clip: true

        Text {

            anchors.centerIn: parent

            text: "LOADING..."
            color: Color.bgMuted
            font.family: Fonts.zzz_vn_font
            font.pointSize: 16

        }

        Image {

            id: image

            anchors.fill: parent
            //scale: 1.2
            //transform: [Translate {y: 10}]
            fillMode: Image.PreserveAspectCrop
            cache: true
            source: GithubInfo.avatar

        }

        focus: true

    }

    Text {
        Layout.alignment: Qt.AlignCenter

        Layout.topMargin: 18
        Layout.bottomMargin: -12

        text: "- " + SystemInfo.hostname + " -"
        color: Color.accentSoft
        font.family: userprofile.font
        font.pointSize: 14
        font.weight: userprofile.font_weight
        font.wordSpacing: 0
    }

    Text {
        Layout.alignment: Qt.AlignCenter

        Layout.bottomMargin: -12

        text: SystemInfo.username
        color: Color.textPrimary
        font.family: userprofile.font
        font.pointSize: 26
        font.weight: userprofile.font_weight
    }

}

