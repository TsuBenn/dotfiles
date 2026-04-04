import qs.assets
import qs.services
import qs.modules.common

import Quickshell
import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick

ColumnLayout {

    spacing: 8

    RowLayout {

        Layout.topMargin: 3
        Layout.alignment: Qt.AlignCenter

        id: root

        property string font: Fonts.zzz_vn_font
        property real maxPercentage: 0.75
        property int radius: 54
        property int thickness: 12
        property int label_size: 11

        spacing: 20

        ProgressCircle {
            radius: root.radius
            thickness: root.thickness
            icon: "CPU"
            icon_font: root.font
            icon_size: 18
            icon_weight: 700
            label: Math.round(SystemInfo.cpuusage)
            label_height: 0
            font_weight: 800
            font_size: root.label_size
            percentage: SystemInfo.cpuusage
            maxPercentage: root.maxPercentage
        }

        ProgressCircle {
            radius: root.radius
            thickness: root.thickness
            icon: "GPU"
            icon_font: root.font
            icon_size: 18
            icon_weight: 700
            font_size: root.label_size
            font_weight: 800
            label: Math.round(SystemInfo.gpuusage)
            percentage: SystemInfo.gpuusage
            maxPercentage: root.maxPercentage
        }

        ProgressCircle {
            radius: root.radius
            thickness: root.thickness
            icon: "MEM"
            icon_font: root.font
            icon_size: 18
            icon_weight: 700
            font_size: root.label_size
            font_weight: 800
            label: SystemInfo.ktoG(SystemInfo.memused).toFixed(1) + "/" + Math.round(SystemInfo.ktoG(SystemInfo.memtotal))
            percentage: SystemInfo.memusage
            maxPercentage: root.maxPercentage
        }

        ProgressCircle {
            radius: root.radius
            thickness: root.thickness
            icon: "VRAM"
            icon_font: root.font
            icon_size: 18
            icon_weight: 700
            font_size: root.label_size
            font_weight: 800
            label: SystemInfo.ktoG(SystemInfo.gpumemused).toFixed(1) + "/" + Math.round(SystemInfo.ktoG(SystemInfo.gpumemtotal))
            percentage: SystemInfo.gpumemusage
            maxPercentage: root.maxPercentage
        }

    }

    RowLayout {

        visible: true

        Layout.topMargin: 6
        Layout.alignment: Qt.AlignCenter 

        spacing: 16

        component InfoBar: Rectangle {

            id: infobar

            property string text: "Network"
            property string subtextleft: "Network"
            property string subtextmid: "|"
            property real midopacity: 0.4
            property string subtextright: "Network"
            property int font_size: 10
            property int font_weight: 700
            property int info_offset: 0
            property int padding: 30
            property int spacing: 8
            property bool toggleinfo: false
            property real textopacity: 1

            Behavior on info_offset {NumberAnimation {duration: 200; easing.type: Easing.OutCubic}}

            function toggleInfo() {
                fade.start()
            }

            MouseControl {
                anchors.fill: parent

                onPressed: {
                    parent.toggleInfo()
                }
            }

            implicitWidth: 265
            implicitHeight: 20

            radius: implicitHeight/2

            color: Color.bgMuted

            SequentialAnimation {
                id: fade
                NumberAnimation {
                    target: infobar
                    property: "textopacity"
                    duration: 150
                    from: 1
                    to: 0
                    easing.type: Easing.InCubic
                }
                ScriptAction {script: {infobar.toggleinfo = !infobar.toggleinfo}}
                PauseAnimation {duration: 100}
                NumberAnimation {
                    target: infobar
                    property: "textopacity"
                    duration: 150
                    from: 0
                    to: 1
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {

                id: infobar_title

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left

                implicitWidth: infobar_maintext.implicitWidth + infobar.padding
                Behavior on implicitWidth {NumberAnimation { duration: 200; easing.type: Easing.OutCubic }}

                radius: implicitWidth/2

                color: Color.accentStrong

                Text {

                    anchors.centerIn: parent

                    id: infobar_maintext
                    text: infobar.text
                    color: Color.textSecondary
                    font.pointSize: infobar.font_size
                    font.family: Fonts.zzz_vn_font
                    font.weight: infobar.font_weight
                    opacity: infobar.textopacity
                }
            }

            Rectangle {
                id: infobar_info
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.left: infobar_title.right

                color: "transparent"

                Text {

                    anchors.rightMargin: infobar.spacing
                    anchors.right: subtextmid.right
                    anchors.verticalCenter: infobar_info.verticalCenter

                    text: infobar.subtextleft
                    color: Color.accentSoft
                    font.pointSize: infobar.font_size
                    font.family: Fonts.system
                    font.weight: infobar.font_weight
                    opacity: infobar.textopacity

                }
                Text {

                    id:subtextmid

                    anchors.centerIn: parent
                    anchors.verticalCenter: infobar_info.verticalCenter
                    anchors.horizontalCenterOffset: infobar.info_offset

                    opacity: infobar.midopacity

                    text: infobar.subtextmid
                    color: Color.textDisabled
                    font.pointSize: infobar.font_size
                    font.family: Fonts.system
                    font.weight: infobar.font_weight

                }
                Text {

                    anchors.leftMargin: infobar.spacing
                    anchors.left: subtextmid.left
                    anchors.verticalCenter: infobar_info.verticalCenter

                    text: infobar.subtextright
                    color: Color.accentSoft
                    font.pointSize: infobar.font_size
                    font.family: Fonts.system
                    font.weight: infobar.font_weight
                    opacity: infobar.textopacity

                }
            }

        }

        InfoBar {
            id: left
            text: !toggleinfo ? "SWAP" : "NETWORK"
            padding: !toggleinfo ? 40 : 30
            subtextleft: !toggleinfo ? SystemInfo.formatNum(SystemInfo.ktoM(SystemInfo.swapused).toFixed(1),4) + "MB " : SystemInfo.storageRounder(SystemInfo.networktransmit,0,3) + "/s \udb80\udf60"
            subtextmid: !toggleinfo ? "/" : "|"
            subtextright: !toggleinfo ? " " + SystemInfo.formatNum(SystemInfo.ktoM(SystemInfo.swaptotal).toFixed(1),4) + "MB" : "\udb80\udf5d " + SystemInfo.storageRounder(SystemInfo.networkreceive,0,3) + "/s"
            midopacity: !toggleinfo ? 1 : 0.4
        }

        InfoBar {
            id: right
            text: !toggleinfo? "ROOT" : "DISK"
            subtextleft: !toggleinfo ? SystemInfo.ktoG(SystemInfo.rootstorageused).toFixed(1) + "GB " : SystemInfo.storageRounder(SystemInfo.diskreadspeed,0,3) + "/s ʀ"
            subtextmid: !toggleinfo ? "/" : "|"
            subtextright: !toggleinfo ? " " + SystemInfo.formatNum(SystemInfo.ktoG(SystemInfo.rootstoragetotal).toFixed(1),4) + "GB (" + SystemInfo.formatNum(SystemInfo.rootstorageusage.toFixed(0),3) + "%)" : "ᴡ " + SystemInfo.storageRounder(SystemInfo.diskwritespeed,0,3) + "/s"
            padding: !toggleinfo ? 20 : 30
            midopacity: !toggleinfo ? 1 : 0.4
            info_offset: !toggleinfo ? -26 : 0
        }

    }

}

