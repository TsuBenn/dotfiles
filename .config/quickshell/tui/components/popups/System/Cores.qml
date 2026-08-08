pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property int w
    property var box

    spacing: 0

    function fmt(str, ...args) {
        return str.replace(/{}/g, () => args.shift());
    }
    function strip(str: string): string {
        return str.trim().replace(/<[^>]*>/g, "");
    }

    Cells {

        w: root.w
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
                font: Cell.fontB
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
    }

    CellSeparator {
        w: root.w
        color: Colors.accentDim
    }

    CellScrollView {
        id: cpu_list
        w: root.w
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
        }
    }

    CellSeparator {
        w: root.w
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
        w: root.w
        color: Colors.bgOverlay
        padding: 1
    }

    RowLayout {

        spacing: 0

        Stat {
            key: "<b>CLOCK:</b>"
            value: root.fmt("<b>{}MHz</b>", SystemInfo.cpubase.toFixed(0))

            key_color: Colors.secondary

            w: root.w - clock.w

            value_color: {
                const value = SystemInfo.cpubase / SystemInfo.cpuboost * 100;
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.dyn;
            }
        }

        CellText {
            id: clock

            Layout.leftMargin: -Cell.w(root.box.p)

            text: root.fmt(" / {}Mhz", SystemInfo.cpuboost.toFixed(0))
            color: root.box.stc
        }
    }

    RowLayout {

        spacing: 0

        Stat {
            key: "<b>POWER:</b>"
            value: root.fmt("<b>{}W</b>", SystemInfo.cpupower)

            key_color: Colors.secondary

            w: root.w - power.w

            value_color: {
                if (SystemInfo.cpumaxpower == 0)
                    return root.box.dyn;
                const value = SystemInfo.cpupower / SystemInfo.cpumaxpower * 100;
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.dyn;
            }
        }

        CellText {
            id: power

            Layout.leftMargin: -Cell.w(root.box.p)

            text: SystemInfo.cpumaxpower > 0 ? root.fmt(" / {}W", SystemInfo.cpumaxpower.toFixed(1)) : ""
            color: root.box.stc
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
            font: Cell.fontB
        }

        CellText {
            anchors.right: bar.right
            anchors.rightMargin: Cell.w(root.box.p)

            text: "%"
            color: Colors.fgDim
        }
    }

    component Stat: Cells {
        id: stat

        property string key: "Name:"
        property string value: "Ryzen R5 7600"

        property color key_color: root.box.key
        property color value_color: stc ? root.box.stc : root.box.dyn

        property bool stc: false
        property bool debug: false

        w: root.box.eW
        h: 1

        color: "transparent"

        CellText {
            id: stat_key

            anchors.left: stat.left
            anchors.leftMargin: Cell.w(root.box.p)

            text: stat.key
            color: stat.key_color
            debug: stat.debug
        }

        MarqueeCellText {
            id: stat_value

            anchors.right: stat.right
            anchors.rightMargin: Cell.w(root.box.p)

            text: stat.value
            fg: stat.value_color
            cellw: stat.w - root.strip(stat.key).length - root.box.p * 2 - 1
            alignRight: true
        }
    }
}
