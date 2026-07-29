pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: cpu_spike

    property int w
    property var box

    spacing: 0

    Cells {

        w: cpu_spike.w
        h: 1

        color: Colors.bgSurface

        RowLayout {
            id: cpu

            x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
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
                text: `(${SystemInfo.cputhreads})`
                color: Colors.info
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
                    if (value > cpu_spike.box.warning_thres) {
                        return Colors.blend(Colors.warning, Colors.danger, Math.min(value - cpu_spike.box.danger_thres, 10) / 10);
                    } else if (value > 70) {
                        return Colors.blend(cpu_spike.box.dyn, Colors.warning, Math.min(value - cpu_spike.box.warning_thres, 10) / 10);
                    }
                    return cpu_spike.box.dyn;
                }
                font: Cell.fontB
            }
        }
    }

    // RowLayout {
    //     Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(parent.w + 1))
    //     spacing: 0
    //     CellText {
    //         text: SystemInfo.cpucores
    //         color: Colors.info
    //         font: Cell.fontB
    //     }
    //     CellText {
    //         text: " cores - "
    //         color: Colors.fgSubtle
    //         font: Cell.fontB
    //     }
    //     CellText {
    //         text: SystemInfo.cputhreads
    //         color: Colors.info
    //         font: Cell.fontB
    //     }
    //     CellText {
    //         text: " threads"
    //         color: Colors.fgSubtle
    //         font: Cell.fontB
    //     }
    // }

    CellSeparator {
        w: cpu_spike.w
        color: Colors.accentDim
    }

    CellScrollView {
        id: cpu_list
        w: cpu_spike.w
        h: 6
        scrollbar.enabled: Cell.hCount(contentH) > h
        source: GridLayout {

            columns: 2
            columnSpacing: 0
            rowSpacing: 0

            Repeater {
                model: SystemInfo.cpustats.length

                delegate: RowLayout {

                    required property int index

                    property real percent: SystemInfo.cpustats[index]

                    spacing: 0

                    CellText {
                        text: " C" + (parent.index + 1).toString().padEnd(2, " ")
                        color: Colors.secondary
                        font: Cell.fontB
                    }

                    Bar {
                        key: Math.round(parent.percent).toString().padStart(3, " ")
                        value: parent.percent

                        w: (cpu_list.contentW - 8) / 2

                        value_color: {
                            if (value > cpu_spike.box.danger_thres) {
                                return Colors.blend(Colors.warning, Colors.danger, Math.min(value - cpu_spike.box.danger_thres, 10) / 10);
                            } else if (value > cpu_spike.box.warning_thres) {
                                return Colors.blend(cpu_spike.box.bar, Colors.warning, Math.min(value - cpu_spike.box.warning_thres, 10) / 10);
                            }
                            return cpu_spike.box.bar;
                        }

                        key_color: {
                            if (value > cpu_spike.box.danger_thres) {
                                return Colors.blend(Colors.warning, Colors.danger, Math.min(value - cpu_spike.box.danger_thres, 10) / 10);
                            } else if (value > cpu_spike.box.warning_thres) {
                                return Colors.blend(cpu_spike.box.dyn, Colors.warning, Math.min(value - cpu_spike.box.warning_thres, 10) / 10);
                            }
                            return cpu_spike.box.dyn;
                        }
                    }
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
                if (value > cpu_spike.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - cpu_spike.box.danger_thres, 10) / 10);
                } else if (value > cpu_spike.box.warning_thres) {
                    return Colors.blend(cpu_spike.box.bar, Colors.warning, Math.min(value - cpu_spike.box.warning_thres, 10) / 10);
                }
                return cpu_spike.box.bar;
            }

            key_color: {
                if (value > cpu_spike.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - cpu_spike.box.danger_thres, 10) / 10);
                } else if (value > cpu_spike.box.warning_thres) {
                    return Colors.blend(cpu_spike.box.dyn, Colors.warning, Math.min(value - cpu_spike.box.warning_thres, 10) / 10);
                }
                return cpu_spike.box.dyn;
            }
        }
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
            anchors.leftMargin: Cell.w(cpu_spike.box.p)

            w: bar.w - 2 * cpu_spike.box.p - bar_value.w - 2

            percent: bar.value

            fg: bar.value_color
        }

        CellText {
            id: bar_value

            anchors.right: bar.right
            anchors.rightMargin: Cell.w(cpu_spike.box.p + 1)

            text: bar.key
            font: Cell.fontB
        }

        CellText {
            anchors.right: bar.right
            anchors.rightMargin: Cell.w(cpu_spike.box.p)

            text: "%"
            color: Colors.fgDim
        }
    }
}
