pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    property var box

    spacing: 0

    CellScrollView {

        id: list

        w: root.box.contentW
        h: 20

        ColumnLayout {

            spacing: 0

            Repeater {

                model: AudioInfo.streams

                delegate: Cells {

                    id: stream

                    required property int id
                    required property real volume
                    required property string app
                    required property string name
                    required property string binary

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
                                icon: [stream.app,stream.name,stream.binary]
                                hideOnFail: false
                            }

                            CellText {
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

                                        w: stream.w - 5 - 5*icon.success
                                        percent: stream.volume
                                        interactive: true
                                        syncDelay: 1500
                                        adjustOnHold: false
                                        cellInterval: 2

                                        fg: Colors.accentStrong

                                        onAdjusted: (percent) => {
                                            AudioInfo.setVolume(stream.id, percent)
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
                            type: 2
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

    CellSeparator {

        type: 0
        padding: 1
        w: root.box.contentW
        color: Qt.darker(Colors.fgSubtle,1.5)
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
            syncDelay: 200
            adjustOnHold: true
            cellInterval: 2

            onAdjusted: (percent) => {
                AudioInfo.setVolume(AudioInfo.sinkDefault, percent)
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
