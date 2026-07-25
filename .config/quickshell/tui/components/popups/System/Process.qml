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

        RowLayout {
            Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(parent.w + 1))
            spacing: Cell.w(1)
            CellText {
                text: SystemInfo.cpumodel
                color: {
                    if (text.toLowerCase().includes("amd")) {
                        return Colors.blend(Colors.danger, Colors.fgBase, 0.2);
                    } else if (text.toLowerCase().includes("intel")) {
                        return Colors.blend(Colors.danger, Colors.info, 0.2);
                    }
                    return Colors.fgBase;
                }
                font: Cell.fontBB
            }
            CellText {
                text: "-"
                color: Colors.fgSubtle
            }
            CellText {
                text: SystemInfo.cputemp.toFixed(0) + "°C"
                color: {
                    const value = SystemInfo.cputemp;
                    if (value > root.box.warning_thres) {
                        return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                    } else if (value > 70) {
                        return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                    }
                    return root.box.dyn;
                }
                font: Cell.fontB
            }
        }

        RowLayout {
            Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(parent.w + 1))
            spacing: 0
            CellText {
                text: SystemInfo.cpucores
                color: Colors.info
                font: Cell.fontB
            }
            CellText {
                text: " cores - "
                color: Colors.fgSubtle
                font: Cell.fontB
            }
            CellText {
                text: SystemInfo.cputhreads
                color: Colors.info
                font: Cell.fontB
            }
            CellText {
                text: " threads"
                color: Colors.fgSubtle
                font: Cell.fontB
            }
        }

        CellSeparator {
            w: cpu_spike.w
            color: Colors.accentDim
        }

        CellScrollList {
            id: cpu_list
            w: cpu_spike.w
            h: 12
            model: SystemInfo.cpustats
            scrollbar.enabled: model.length > h
            delegate: RowLayout {

                x: Cell.w(1)

                property var modelData
                property int index

                spacing: 0

                CellText {
                    text: "C" + (parent.index + 1).toString().padEnd(2, " ")
                    color: Colors.secondary
                    font: Cell.fontB
                }

                Bar {
                    property var modelData: parent.modelData
                    key: Math.round(modelData).toString().padStart(3, " ")
                    value: modelData

                    value_color: {
                        if (value > root.box.danger_thres) {
                            return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                        } else if (value > root.box.warning_thres) {
                            return Colors.blend(root.box.bar, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                        }
                        return root.box.bar;
                    }

                    key_color: {
                        if (value > root.box.danger_thres) {
                            return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                        } else if (value > root.box.warning_thres) {
                            return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                        }
                        return root.box.dyn;
                    }
                }
            }
        }

        CellSeparator {
            w: cpu_spike.w
            color: Colors.accentDim
        }

        RowLayout {

            Layout.leftMargin: Cell.w(1)

            spacing: 0

            CellText {
                text: "CPU"
                color: Colors.secondary
                font: Cell.fontB
            }

            Bar {
                key: value.toString().padStart(3, " ")
                value: SystemInfo.cpuusage

                value_color: {
                    if (value > root.box.danger_thres) {
                        return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                    } else if (value > root.box.warning_thres) {
                        return Colors.blend(root.box.bar, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                    }
                    return root.box.bar;
                }

                key_color: {
                    if (value > root.box.danger_thres) {
                        return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                    } else if (value > root.box.warning_thres) {
                        return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                    }
                    return root.box.dyn;
                }
            }
        }

        CellSeparator {
            w: cpu_spike.w
            color: Colors.accentStrong
            bg: "transparent"
            connectStart: true
            connectEnd: true
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
                        h: 11
                        color: "transparent"
                    }

                    CellSeparator {
                        visible: parent.index != 2
                        vertical: true
                        h: 11
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

        CellSeparator {
            w: top_screentime.w
            color: Colors.fgSubtle
            type: 2
            title.text: "Screentimes"
            title.color: Colors.fgBase
            title.font: Cell.fontB
        }

        RowLayout {
            Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
            spacing: 0

            CellButton {
                text: "<"
                color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                fg: [Colors.fgBase, Colors.bgSurface]
                font: Cell.fontB
            }

            CellText {
                text: "Today"
                font: Cell.fontB
                color: Colors.info
                preferedW: 13
                centered: true
            }

            CellButton {
                text: ">"
                color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                fg: [Colors.fgBase, Colors.bgSurface]
                font: Cell.fontB
            }
        }

        RowLayout {
            id: screentime

            property int h: root.box.contentH - 18

            spacing: 0

            CellScrollList {

                h: screentime.h - 2
                w: top_screentime.w - screentime_timeline.w

                model: ScreenTimeInfo.normalizeSessions(ScreenTimeInfo.getTodaySessions())

                delegate: CellText {

                    property var modelData

                    text: modelData.name
                }
            }

            Cells {
                id: screentime_timeline
                w: 64
                h: screentime.h

                color: "transparent"

                CellBox {
                    w: parent.w
                    h: parent.h
                }
            }
        }

        CellSeparator {
            w: top_screentime.w
            color: Colors.accentDim
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

    component Bar: Cells {
        id: bar

        property string key: value + "%"
        property int value: SystemInfo.cpuusage

        property color key_color: Colors.fgBase
        property color value_color: Colors.fgBase

        w: cpu_list.contentW - 4
        h: 1

        color: "transparent"

        CellProgressSquare {
            id: bar_bar

            anchors.left: bar.left
            anchors.leftMargin: Cell.w(root.box.p)

            w: bar.w - 2 * root.box.p - bar_value.w - 2
            percent: bar.value

            fg: bar.value_color
        }

        CellText {
            id: bar_value

            anchors.right: bar.right
            anchors.rightMargin: Cell.w(root.box.p + 1)

            text: bar.key
        }

        CellText {
            anchors.right: bar.right
            anchors.rightMargin: Cell.w(root.box.p)

            text: "%"
            color: Colors.fgDim
        }
    }
}
