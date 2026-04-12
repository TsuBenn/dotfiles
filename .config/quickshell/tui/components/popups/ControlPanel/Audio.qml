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
        h: 12

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

                            Cells {

                                Layout.alignment: Qt.AlignTop

                                w: 5
                                h: 2

                                color: "transparent"

                                Image {
                                    source: "image://icon/zen-browser"
                                    height: Cell.h(2)
                                    width: Cell.h(2)

                                    fillMode: Image.PreserveAspectCrop
                                }

                            }

                            ColumnLayout {

                                spacing: 0

                                CellText {

                                    text: ` ${stream.app} | ${stream.name}`

                                    preferedW: stream.w - 8

                                }

                                RowLayout {

                                    spacing: 0

                                    CellText {
                                        text: " ["
                                        color: Colors.fgSubtle
                                    }

                                    CellProgressSquare {

                                        w: stream.w - 10
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

    }

    CellText {
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

        type: 0
        padding: 1
        w: root.box.contentW
        color: Colors.fgSubtle

    }


}
