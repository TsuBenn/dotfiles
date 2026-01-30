pragma ComponentBehavior:Bound 

import qs.assets
import qs.modules.common
import qs.modules.homepanel
import qs.services

import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick
import QtQml.Models

ColumnLayout {

    RowLayout {

        id: sliders

        spacing: 7

        component AudioBar: ColumnLayout {

            id: control

            property string text: "icon"
            property int text_size: 20
            property real percentage: bar.percentage
            property real source: AudioInfo.volume
            property int box_width: 18
            property int box_height: 240

            spacing: 9

            signal toggleMute()

            signal adjusted()

            function syncBar() {
                bar.syncBar()
            }

            function setVolume(device: int, bind: real, percentage: real, alert: bool) {
                let audio

                switch (Math.floor(Math.random() * 3)) {
                    case 0: audio = "mambo"; break
                    case 1: audio = "mambo_tongye"; break
                    case 2: audio = "mambo_wow"; break
                }

                AudioInfo.setVolume(device, percentage)
                if (alert) AudioInfo.playSound(audio, 2/3)
            }

            VerticalProgressBar {

                Layout.alignment: Qt.AlignCenter

                id: bar

                box_width: control.box_width
                box_height: control.box_height

                interactive: true

                percentage: preferedPercentage
                preferedPercentage: control.source

                onAdjusted: {
                    control.adjusted()
                }

            }

            PillButton {
                Layout.alignment: Qt.AlignCenter
                text: control.text
                font_size: control.text_size  
                box_height: control.text_size*2
                box_width: control.text_size*2
                onPressed: control.toggleMute()

                bg_color: ["transparent", Color.bgBase, Color.bgBase]
                fg_color: [Color.textPrimary, Color.textPrimary, Color.accentStrong]
                border_width: [0,0,2]
            }
        }

        AudioBar {

            id: volume

            property int lastPercentage

            text: {
                if (AudioInfo.mute) {
                    return "\udb81\udf5f"
                }
                if (percentage > 200/3) {
                    return "\udb81\udd7e"
                }
                else if (percentage > 100/3) {
                    return "\udb81\udd80"
                }
                else if (percentage > 0) {
                    return "\udb81\udd7f"
                }
                else {
                    return "\udb81\udf5f"
                }
            }

            source: AudioInfo.volume

            onAdjusted: {
                setVolume(AudioInfo.sinkDefault, AudioInfo.volume, percentage, true)
                syncBar()
            }

            onToggleMute: {
                AudioInfo.muteVolume(AudioInfo.sinkDefault)
            }


        }

        AudioBar {

            id: mic

            property int lastPercentage

            text: {
                if (percentage > 0) {
                    return "\udb80\udf6c"
                }
                else {
                    return "\udb80\udf6d"
                }
            }

            source: AudioInfo.mic

            onAdjusted: {
                setVolume(AudioInfo.sourceDefault, AudioInfo.mic, percentage, false)
                syncBar()
            }

            onToggleMute: {
                if (percentage > 0) {
                    lastPercentage = percentage
                    setVolume(AudioInfo.sourceDefault, AudioInfo.mic, 0, false)
                    syncBar()
                } else {
                    setVolume(AudioInfo.sourceDefault, AudioInfo.mic, lastPercentage, false)
                    syncBar()
                }
            }
        }

        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 10
        Layout.bottomMargin: -2

    }


    spacing: 16

    ColumnLayout {

        Layout.alignment: Qt.AlignCenter

        spacing: 10

        id: device_selector

        property bool   dropdown                  : false
        property int    maxWidth                  : 300
        property int    maxHeight                 : 102
        property int    box_width                 : 90
        property int    box_height                : 34
        property string list_font                 : Fonts.system
        property int    list_font_weight          : 600
        property int    list_font_weight_selected : 700
        property var    list_font_color           : [Color.textPrimary, Color.textPrimary, Color.textPrimary]
        property var    list_color                : ["transparent", Color.bgBase, Color.bgSurface]
        property var    list_font_color_selected  : [Color.textSecondary, Color.textSecondary, Color.textSecondary]
        property var    list_color_selected       : [Color.accentStrong, Color.accentStrong, Color.bgSurface]
        property var    list_border               : [0,0,2]
        property var    list_border_selected      : [0,0,2]
        property int    list_font_size            : 11
        property int    list_padding              : 10

        component DeviceSelector: PopupList {

            id:devicelist

            property int defaultID: AudioInfo.sinkDefault

            maxWidth: device_selector.maxWidth
            maxHeight: device_selector.maxHeight
            box_width: device_selector.box_width
            font_family: Fonts.system
            font_size: 13
            selected_font_size: 11
            box_height: device_selector.box_height
            font_weight: 800
            dropdown: device_selector.dropdown
            items: AudioInfo.sinks ?? [{"id": 0, "name": "n/a"}]
            selected_padding: 15
            selected_marquee: true
            animation_speed: 5
            show_scroller: true

            list_items: Item {
                id: device_items 
                implicitWidth: devicelist.list_container_implicitWidth
                implicitHeight: devicelist.box_height
                required property int id
                required property string name

                Loader {
                    active: devicelist.visible
                    anchors.fill:parent
                    sourceComponent: PillButton {
                        property int id: device_items.id
                        property string name: device_items.name

                        text: name
                        implicitWidth: devicelist.list_container_implicitWidth
                        implicitHeight: devicelist.box_height
                        text_padding: device_selector.list_padding
                        font_family: device_selector.list_font
                        font_size: device_selector.list_font_size
                        font_weight: id == devicelist.defaultID ? device_selector.list_font_weight_selected : device_selector.list_font_weight
                        bg_color: id == devicelist.defaultID ? device_selector.list_color_selected : device_selector.list_color
                        fg_color: id == devicelist.defaultID ? device_selector.list_font_color_selected : device_selector.list_font_color
                        border_width: id == devicelist.defaultID ? device_selector.list_border_selected : device_selector.list_border
                        centered: false
                        radius: devicelist.radius-devicelist.list_spacing

                        marquee: true

                        onReleased: {
                            devicelist.itemPressed(this)
                            devicelist.closeList()
                        }

                    }
                }

            }


            onItemPressed: (item) => {
                AudioInfo.switchDefault(item.id)
            }
        }

        DeviceSelector {
            text: "Output"
            selected_text: AudioInfo.getName(AudioInfo.sinkDefault)
            spacing: -5
        }
        DeviceSelector {
            items: AudioInfo.sources ?? [{"id": 0, "name": "n/a"}]
            text: "Input"
            spacing: -5
            selected_text: AudioInfo.getName(AudioInfo.sourceDefault)
            property int defaultID: AudioInfo.sourceDefault
        }

    }

    Process {
        id: mambo
    }

}
