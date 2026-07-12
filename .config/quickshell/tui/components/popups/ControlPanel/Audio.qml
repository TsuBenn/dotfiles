pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    property bool minimal: SettingsInfo.minimal

    property var box

    spacing: 0

    CellScrollView {

        id: list

        w: root.box.contentW
        h: 21

        source: ColumnLayout {

            spacing: 0

            ColumnLayout {

                spacing: 0

                Timer {
                    id: thetimer
                    interval: 200
                }

                Repeater {

                    id: repeater

                    Component.onCompleted: {
                        AudioInfo.statusUpdated.connect(()=>{
                            if (thetimer.running) return
                            repeater.model = AudioInfo.streams
                        })
                    }

                    model: AudioInfo.streams.length

                    delegate: Cells {

                        id: stream

                        required property int index

                        property int id : AudioInfo.streams[index]?.id
                        property real volume : AudioInfo.streams[index]?.volume
                        property string app : AudioInfo.streams[index]?.app
                        property string name : AudioInfo.streams[index]?.name
                        property string binary : AudioInfo.streams[index]?.binary

                        w: list.contentW
                        h: 3

                        color: "transparent"

                        ColumnLayout {

                            spacing: 0

                            RowLayout {

                                spacing: 0

                                CellText {
                                    text: " "
                                }

                                CellIcon {
                                    id: icon
                                    w: 5
                                    icon: [stream.binary,stream.app,stream.name]
                                    hideOnFail: false
                                }

                                CellText {

                                    visible: !root.minimal

                                    text: " "
                                }

                                ColumnLayout {

                                    spacing: 0

                                    CellText {

                                        text: stream.app.toLowerCase() == stream.name.toLowerCase() ? `${stream.app}` : `${stream.app} | ${stream.name}`

                                        preferedW: stream.w - 3 - 5*icon.success

                                    }

                                    RowLayout {

                                        spacing: 0

                                        CellText {
                                            text: "["
                                            color: Colors.fgSubtle
                                        }

                                        CellProgressSquare {

                                            w: stream.w - 5 - 5*icon.success + root.minimal*1
                                            percent: stream.volume
                                            interactive: true
                                            adjustOnHold: false
                                            syncDelay: 5000
                                            adjustOnPress: true
                                            cellInterval: 2

                                            fg: Colors.accentStrong

                                            onAdjusted: (percent) => {
                                                AudioInfo.setVolume(stream.id, percent)
                                                thetimer.restart()
                                            }

                                        }

                                        CellText {
                                            text: "]"
                                            color: Colors.fgSubtle
                                        }

                                    }


                                }
                            }

                            CellSeparator {

                                padding: 1
                                w: stream.w
                                type: root.minimal ? 0 : 2
                                color: Colors.bgOverlay

                            }
                        }


                    }

                }

            }

            ColumnLayout {

                spacing: 0

                CellText {
                    visible: AudioInfo.streams.length == 0
                    text: " "
                }

                CellText {
                    visible: AudioInfo.streams.length == 0
                    Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(list.contentW))

                    text: "No media"
                    color: Colors.fgSubtle
                }

            }
        }


    }

    CellSeparator {

        type: 0
        padding: 0
        w: root.box.contentW
        color: Colors.accentDim
        title.text: "MASTER VOLUME"
        title.font: Cell.fontB

    }

    CellText {

        visible: false

        text: "  MASTER VOLUME"
        font: Cell.fontB
    }

    RowLayout {

        Layout.leftMargin: Cell.centerWCell(implicitWidth,parent.implicitWidth)

        spacing: 0

        CellText{
            text: "["
            color: Colors.fgSubtle
        }

        CellProgressSquare {

            w: root.box.w - 6
            percent: AudioInfo.volume
            interactive: true
            syncDelay: 5000
            adjustOnHold: false
            cellInterval: 2

            onAdjusted: (percent) => {
                AudioInfo.setVolume(AudioInfo.sinkDefault, percent)
            }

            onReleased: {
                SettingsInfo.audio_check()
            }

        }

        CellText{
            text: "]"
            color: Colors.fgSubtle
        }
    }

    CellSeparator {

        type: 2
        padding: 1
        w: root.box.contentW
        color: Colors.bgOverlay

    }

    RowLayout {

        spacing: 0

        CellText {
            text: " OUTPUT "
        }

        CellDropdown {
            w: root.box.contentW - 9
            text: ""
            selected: {
                for (const i in AudioInfo.sinks) {
                    if (AudioInfo.sinks[i].id == AudioInfo.sinkDefault) {
                        return i
                    }
                }
                return 0
            }
            items: {
                let items = []
                for (const sink of AudioInfo.sinks) {
                    items.push({
                        label: sink.name,
                        action: () => {
                            AudioInfo.switchDefault(sink.id)
                        }
                    })
                }
                return items
            }
        }
    }

    CellSeparator {

        w: root.box.contentW
        padding: 2
        color: Colors.bgOverlay

    }

    RowLayout {

        spacing: 0

        CellText {
            text: "  INPUT "
        }

        CellDropdown {
            w: root.box.contentW - 9
            text: ""
            selected: {
                for (const i in AudioInfo.sources) {
                    if (AudioInfo.sources[i].id == AudioInfo.sourceDefault) {
                        return i
                    }
                }
                return 0
            }
            items: {
                let items = []
                for (const sink of AudioInfo.sources) {
                    items.push({
                        label: sink.name,
                        action: () => {
                            AudioInfo.switchDefault(sink.id)
                        }
                    })
                }
                return items
            }
        }
    }

    CellSeparator {

        type: 2
        padding: 1
        w: root.box.contentW
        color: Colors.bgOverlay

    }

}
