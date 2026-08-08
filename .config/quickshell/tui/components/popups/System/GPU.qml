pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 0

    property int w
    property var box

    property var gpus: SystemInfo.gpumodels
    property var selected: 0

    function advance(delta: int) {
        selected = Math.min(Math.max(selected + delta, 0), gpus.length - 1);
    }

    function fmt(str, ...args) {
        return str.replace(/{}/g, () => args.shift());
    }

    function strip(str: string): string {
        return str.trim().replace(/<[^>]*>/g, "");
    }

    RowLayout {
        Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
        spacing: Cell.w(1)
        CellButton {
            text: "<"

            clickable: root.selected > 0
            color: clickable ? ["transparent", Colors.bgOverlay, Colors.fgBase] : "transparent"
            fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle
            font: Cell.fontBB
            onPressed: button => {
                if (button === "L" && clickable) {
                    root.advance(-1);
                }
            }
        }

        Cells {
            w: root.w - 10
            h: 1
            color: "transparent"
            RowLayout {
                x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                spacing: Cell.w(1)
                CellText {
                    text: root.gpus[root.selected].name
                    color: {
                        if (text.toLowerCase().includes("amd")) {
                            return Colors.blend(Colors.danger, Colors.fgBase, 0.2);
                        } else if (text.toLowerCase().includes("nvidia")) {
                            return Colors.blend(Colors.success, Colors.info, 0.2);
                        }
                        return Colors.fgBase;
                    }
                    font: Cell.fontBB
                }
                CellText {
                    text: "-"
                    color: Colors.fgSubtle
                    font: Cell.fontB
                }
                CellText {
                    text: root.gpus[root.selected].temp.toFixed(0) + "°C"
                    color: {
                        const value = root.gpus[root.selected].temp;
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

        CellButton {
            text: ">"

            clickable: root.selected < root.gpus.length - 1
            color: clickable ? ["transparent", Colors.bgOverlay, Colors.fgBase] : "transparent"
            fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle
            font: Cell.fontBB
            onPressed: button => {
                if (button === "L" && clickable) {
                    root.advance(1);
                }
            }
        }
    }

    CellSeparator {
        w: root.w
        color: Colors.accentDim
    }

    GridLayout {
        columns: 1
        columnSpacing: 0
        rowSpacing: 0

        Repeater {
            model: [
                {
                    label: "SMP",
                    key: "sm"
                },
                {
                    label: "MEM",
                    key: "mem"
                },
                {
                    label: "ENC",
                    key: "enc"
                },
                {
                    label: "DEC",
                    key: "dec"
                },
            ]

            delegate: RowLayout {

                required property string label
                required property string key

                property real value: root.gpus[root.selected][key]

                spacing: 0

                CellText {
                    text: " " + parent.label
                    color: Colors.secondary
                    font: Cell.fontB
                }

                Bar {
                    key: Math.round(parent.value).toString().padStart(3, " ")
                    value: parent.value

                    w: (root.w - 4)

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

    CellSeparator {
        w: root.w
        color: Colors.accentDim
    }

    RowLayout {

        spacing: 0

        Stat {
            key: "<b>VRAM</b>"
            value: root.fmt("<b>{}G</b>", SystemInfo.ktoG(root.gpus[root.selected].memoryused).toFixed(1))

            key_color: Colors.secondary

            w: root.w - vram.w

            value_color: {
                const value = root.gpus[root.selected].memoryused / root.gpus[root.selected].memorytotal * 100;
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.dyn;
            }
        }

        CellText {
            id: vram

            Layout.leftMargin: -Cell.w(root.box.p)

            text: root.fmt("/{}G", SystemInfo.ktoG(root.gpus[root.selected].memorytotal).toFixed(1))
            color: root.box.stc
        }
    }

    Bar {
        key: value.toFixed(0).toString().padStart(3, " ")
        value: root.gpus[root.selected].memoryused / root.gpus[root.selected].memorytotal * 100
        w: root.w
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

    CellSeparator {
        w: root.w
        color: Colors.bgOverlay
        padding: 1
    }

    RowLayout {

        spacing: 0

        Stat {
            key: "<b>CLOCK:</b>"
            value: root.fmt("<b>{}Mhz</b>", root.gpus[root.selected].freq.toFixed(0))

            key_color: Colors.secondary

            w: root.w - clock.w

            value_color: {
                const value = root.gpus[root.selected].freq / root.gpus[root.selected].maxfreq * 100;
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

            text: root.fmt(" / {}MHz", root.gpus[root.selected].maxfreq.toFixed(0))
            color: root.box.stc
        }
    }

    RowLayout {

        spacing: 0

        Stat {
            key: "<b>MEMORY CLOCK:</b>"
            value: root.fmt("<b>{}Mhz</b>", root.gpus[root.selected].memoryfreq.toFixed(0))

            key_color: Colors.secondary

            w: root.w - memory_clock.w

            value_color: {
                const value = root.gpus[root.selected].memoryfreq / root.gpus[root.selected].memorymaxfreq * 100;
                if (value > root.box.danger_thres) {
                    return Colors.blend(Colors.warning, Colors.danger, Math.min(value - root.box.danger_thres, 10) / 10);
                } else if (value > root.box.warning_thres) {
                    return Colors.blend(root.box.dyn, Colors.warning, Math.min(value - root.box.warning_thres, 10) / 10);
                }
                return root.box.dyn;
            }
        }

        CellText {
            id: memory_clock

            Layout.leftMargin: -Cell.w(root.box.p)

            text: root.fmt(" / {}MHz", root.gpus[root.selected].memorymaxfreq.toFixed(0))
            color: root.box.stc
        }
    }

    RowLayout {

        spacing: 0

        Stat {
            key: "<b>POWER:</b>"
            value: root.fmt("<b>{}W</b>", root.gpus[root.selected].power.toFixed(1))

            key_color: Colors.secondary

            w: root.w - power.w

            value_color: {
                if (root.gpus[root.selected].maxpower == 0)
                    return root.box.dyn;
                const value = root.gpus[root.selected].power / root.gpus[root.selected].maxpower * 100;
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

            text: root.gpus[root.selected].maxpower > 0 ? root.fmt(" / {}W", root.gpus[root.selected].maxpower.toFixed(1)) : ""
            color: root.box.stc
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

    component Bar: Cells {
        id: bar

        property string key: value + "%"
        property int value: SystemInfo.cpuusage

        property color key_color: Colors.fgBase
        property color value_color: Colors.fgBase

        property bool ratio: true

        w: root.w - 4
        h: 1

        color: "transparent"

        CellProgressSquare {
            id: bar_bar

            anchors.left: bar.left
            anchors.leftMargin: Cell.w(root.box.p)

            w: bar.w - 2 * root.box.p - bar_value.w - 1 - 1 * parent.ratio

            percent: bar.value

            fg: bar.value_color
        }

        CellText {
            id: bar_value

            anchors.right: bar.right
            anchors.rightMargin: Cell.w(root.box.p + 1 * parent.ratio)

            text: bar.key
            font: Cell.fontB
        }

        CellText {
            visible: parent.ratio
            anchors.right: bar.right
            anchors.rightMargin: Cell.w(root.box.p)

            text: "%"
            color: Colors.fgDim
        }
    }
}
