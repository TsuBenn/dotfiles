pragma ComponentBehavior: Bound

import qs.components.popups.System
import qs.config
import qs.services
import qs.modules

import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    spacing: 0

    property var box

    property bool minimal

    ColumnLayout {
        id: cpu_spike

        Layout.alignment: Qt.AlignTop

        spacing: 0

        property int w: 44

        Cores {
            w: parent.w
            box: root.box
        }

        CellSeparator {
            w: cpu_spike.w
            color: Colors.accentStrong
            bg: "transparent"
            connectStart: true
            connectEnd: true
        }

        Spikes {
            w: parent.w
            box: root.box
        }
    }

    CellSeparator {
        vertical: true
        h: root.box.contentH - 2
        color: Colors.accentStrong
        bg: "transparent"
        connectEnd: true
        connectStart: true
    }

    ColumnLayout {
        id: top_screentime
        Layout.alignment: Qt.AlignTop
        spacing: 0

        property int w: root.box.contentW - cpu_spike.w - 1

        RowLayout {
            spacing: 0

            Repeater {
                model: 3

                delegate: RowLayout {
                    required property int index
                    spacing: 0
                    Cells {
                        w: 27
                        h: 10
                        color: "transparent"
                    }

                    CellSeparator {
                        visible: parent.index != 2
                        vertical: true
                        h: 10
                        color: Colors.accentStrong
                        bg: "transparent"
                        connectEnd: true
                        connectStart: true
                    }
                }
            }
        }

        CellSeparator {
            w: top_screentime.w
            color: Colors.accentStrong
            bg: "transparent"
            connectStart: true
            connectEnd: true
        }

        ScreenTime {
            w: top_screentime.w
            h: root.box.contentH - 19
        }
    }

    component Header: CellSeparator {

        property string text: "CPU"

        w: root.box.eW
        type: 2
        padding: 1
        title {
            text: text
            centered: false
            font: Cell.fontBB
            color: root.box.head
        }
        color: Colors.accentDim
    }
}
