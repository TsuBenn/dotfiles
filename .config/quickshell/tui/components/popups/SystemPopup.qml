pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {

    id: root

    w: 120
    h: 27

    function fmt(str, ...args) {
        return str.replace(/{}/g, () => args.shift());
    }

    CellBox {

        id: box

        property int eW: 40
        property int p: 1
        property color stc: Colors.fgDim
        property color dyn: Colors.fgBase

        w: root.w+2
        h: root.h+2

        component Header: CellSeparator {

            property string text: "CPU"

            w: box.eW
            type: 2
            padding: 1
            title {
                text: text
                centered: false
                font: Cell.fontBB
                color: Colors.fgBase
            }
            color: Qt.lighter(Colors.bgOverlay,1.2)

        }

        component Stat: Cells {

            id: stat

            property string key: "Name:"
            property string value: "Ryzen R5 7600"

            property color key_color: Colors.fgDim
            property color value_color: stc ? box.stc : box.dyn

            property bool stc: false

            w: box.eW
            h: 1

            color: "transparent"

            CellText {

                anchors.left: stat.left
                anchors.leftMargin: Cell.w(box.p)

                text: stat.key
                color: stat.key_color

            }

            CellText {

                anchors.right: stat.right
                anchors.rightMargin: Cell.w(box.p)

                text: stat.value
                color: stat.value_color

            }

        }

        component Bar: Cells {

            id: bar

            property string key: value + "%"
            property int value: SystemInfo.cpuusage

            property color key_color: Colors.fgBase
            property color value_color: Colors.fgBase

            w: box.eW
            h: 1

            color: "transparent"

            CellProgressSquare {

                id: bar_bar

                anchors.left: bar.left
                anchors.leftMargin: Cell.w(box.p)

                w: bar.w - 2*box.p - bar_value.w - 1
                percent: bar.value

                fg: bar.value_color

            }

            CellText {

                anchors.right: bar.right
                anchors.rightMargin: Cell.w(box.p)

                id: bar_value

                text: bar.key

                color: bar.key_color

            }

        }

        RowLayout {

            spacing: 0

            ColumnLayout {

                Layout.alignment: Qt.AlignTop

                spacing: 0

                Header { text: "CPU" }

                Stat {
                    key: "Name:"
                    value: root.fmt("<b>{}</b>", SystemInfo.cpumodel)

                    value_color: {
                        if (value.toLowerCase().includes("amd")) {
                            return Colors.blend(Colors.danger,Colors.fgBase,0.2)
                        } else if (value.toLowerCase().includes("intel")) {
                            return Colors.blend(Colors.danger,Colors.info,0.2)
                        }
                        return Colors.fgBase
                    }
                }

                CellSeparator {
                    w: box.eW
                    padding: 1
                    color: Colors.bgOverlay
                }

                Bar {

                    key: root.fmt("<b>{}%<b>", parseInt(SystemInfo.cpuusage).toString().padStart(3, " "))
                    value: SystemInfo.cpuusage

                    value_color: {
                        if (value > 90) {
                            return Colors.danger
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }

                    key_color: {
                        if (value > 90) {
                            return Colors.danger
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return box.dyn
                    }

                }

                CellSeparator {
                    w: box.eW
                    padding: 1
                    color: Colors.bgOverlay
                }

                Stat {
                    key: "Temp:"
                    value: root.fmt("<b>{}°C</b>",parseInt(SystemInfo.cputemp))

                    value_color: {
                        if (SystemInfo.cputemp > 80) {
                            return Colors.danger
                        } else if (SystemInfo.cputemp > 70) {
                            return Colors.warning
                        }
                        return box.dyn
                    }
                }

                Stat {
                    key: "Freq:"
                    value: root.fmt("<b>{}MHz</b>",parseInt(SystemInfo.cpubase))
                }

                Stat {
                    key: "Boost:"
                    value: root.fmt("{}MHz",parseInt(SystemInfo.cpuboost))
                    stc: true
                }

                Stat {
                    key: "Cores:"
                    value: parseInt(SystemInfo.cpucores)
                    stc: true
                }

                Stat {
                    key: "Threads:"
                    value: parseInt(SystemInfo.cputhreads)
                    stc: true
                }

                CellText { text: "" }

                Header { 

                    id: gpu

                    text: "GPU" 

                    property int index: 0

                }

                Stat {
                    key: "Name:"
                    value: root.fmt("<b>{}</b>",SystemInfo.gpumodels[gpu.index].name)

                    value_color: {
                        if (value.toLowerCase().includes("amd")) {
                            return Colors.blend(Colors.danger,Colors.fgBase,0.2)
                        } else if (value.toLowerCase().includes("intel")) {
                            return Colors.blend(Colors.danger,Colors.info,0.2)
                        } else if (value.toLowerCase().includes("nvidia")) {
                            return Colors.blend(Colors.success,Colors.info,0.2)
                        }
                        return Colors.fgBase
                    }
                }

                CellSeparator {
                    w: box.eW
                    padding: 1
                    color: Colors.bgOverlay
                }

                Bar {

                    key: root.fmt("<b>{}%</b>",parseInt(SystemInfo.gpumodels[gpu.index].usage).toString().padStart(3, " "))
                    value: SystemInfo.gpumodels[gpu.index].usage

                    value_color: {
                        if (value > 90) {
                            return Colors.danger
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }

                    key_color: {
                        if (value > 90) {
                            return Colors.danger
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return box.dyn
                    }

                }

                CellSeparator {
                    w: box.eW
                    padding: 1
                    color: Colors.bgOverlay
                }

                Stat {
                    key: "Temp:"
                    value: root.fmt("<b>{}°C</b>",SystemInfo.gpumodels[gpu.index].temp)

                    value_color: {
                        if (SystemInfo.gpumodels[gpu.index].temp > 80) {
                            return Colors.danger
                        } else if (SystemInfo.gpumodels[gpu.index].temp > 70) {
                            return Colors.warning
                        }
                        return box.dyn
                    }
                }

                Stat {
                    key: "Type:"
                    value: SystemInfo.gpumodels[gpu.index].type
                    stc: true
                }

                Stat {
                    key: "Cores:"
                    value: SystemInfo.gpumodels[gpu.index].cores
                    stc: true
                }

                RowLayout {

                    spacing: 0

                    Stat {
                        key: "VRAM:"
                        value: root.fmt("<b>{}G</b>",SystemInfo.ktoG(SystemInfo.gpumodels[gpu.index].memoryused).toFixed(1))

                        w: box.eW - vram.w
                    }

                    CellText {

                        Layout.leftMargin: -Cell.w(2)

                        id: vram

                        text: root.fmt("/{}G",SystemInfo.ktoG(SystemInfo.gpumodels[gpu.index].memorytotal).toFixed(1))
                        color: box.stc

                    }

                }

                CellSeparator {
                    w: box.eW
                    padding: 1
                    color: Colors.bgOverlay
                }

                Bar {

                    key: root.fmt("<b>{}%</b>",parseInt(value).toString().padStart(3, " "))
                    value: (SystemInfo.gpumodels[gpu.index].memoryused/SystemInfo.gpumodels[gpu.index].memorytotal)*100

                    value_color: {
                        if (value > 90) {
                            return Colors.danger
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }

                    key_color: {
                        if (value > 90) {
                            return Colors.danger
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return box.dyn
                    }

                }

                CellSeparator {
                    w: box.eW
                    padding: 1
                    color: Colors.bgOverlay
                }

                RowLayout {

                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                    spacing: 0

                    CellText {

                        property bool available: gpu.index > 0

                        text: "      < "
                        font: Cell.fontBB
                        color: available ? Colors.fgBase : Colors.fgSubtle

                        MouseControl {

                            anchors.fill: parent

                            onReleased: (button) => {
                                if (button == "L" && available) {
                                    gpu.index -= 1
                                }
                            }

                        }

                    }

                    CellText {
                        text: {
                            const base = [..."-".repeat(SystemInfo.gpumodels.length)]
                            base[gpu.index] = "*"
                            return base.join("")
                        }
                        font: Cell.fontBB
                    }

                    CellText {

                        property bool available: gpu.index < SystemInfo.gpumodels.length - 1

                        text: " >      "
                        font: Cell.fontBB
                        color: available ? Colors.fgBase : Colors.fgSubtle

                        MouseControl {

                            anchors.fill: parent

                            onReleased: (button) => {
                                if (button == "L" && available) {
                                    gpu.index += 1
                                }
                            }

                        }

                    }

                }

                CellText { text: "" }

                Header { 

                    text: "Motherboard" 

                }

                Stat {
                    key: "Name:"
                    value: SystemInfo.board
                    stc: true
                }

            }

            ColumnLayout {

                Layout.alignment: Qt.AlignTop

                spacing: 0

                Header { text: "MEMORY" }

                RowLayout {

                    spacing: 0

                    Stat {
                        key: "RAM:"
                        value: root.fmt("<b>{}G</b>",SystemInfo.ktoG(SystemInfo.memused).toFixed(1))

                        w: box.eW - ram.w
                    }

                    CellText {

                        Layout.leftMargin: -Cell.w(box.p)

                        id: ram

                        text: root.fmt("/{}G",SystemInfo.ktoG(SystemInfo.memtotal).toFixed(1))
                        color: box.stc

                    }

                }

                Bar {

                    key: root.fmt("<b>{}%<b>", parseInt(SystemInfo.memusage).toString().padStart(3, " "))
                    value: SystemInfo.memusage

                    value_color: {
                        if (value > 90) {
                            return Colors.danger
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }

                    key_color: {
                        if (value > 90) {
                            return Colors.danger
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return box.dyn
                    }

                }

                CellSeparator {
                    w: box.eW
                    padding: 1
                    color: Colors.bgOverlay
                }

                RowLayout {

                    spacing: 0

                    Stat {
                        key: "SWAP:"
                        value: root.fmt("<b>{}G</b>",SystemInfo.ktoG(SystemInfo.swapused).toFixed(1))

                        w: box.eW - swap.w
                    }

                    CellText {

                        Layout.leftMargin: -Cell.w(box.p)

                        id: swap

                        text: root.fmt("/{}G",SystemInfo.ktoG(SystemInfo.swaptotal).toFixed(1))
                        color: box.stc

                    }

                }

                Bar {

                    key: root.fmt("<b>{}%<b>", parseInt(SystemInfo.swapusage).toString().padStart(3, " "))
                    value: SystemInfo.swapusage

                    value_color: {
                        if (value > 90) {
                            return Colors.danger
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }

                    key_color: {
                        if (value > 90) {
                            return Colors.danger
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return box.dyn
                    }

                }

                CellSeparator {
                    w: box.eW
                    padding: 1
                    color: Colors.bgOverlay
                }

                CellText {
                    text: " "
                }

                Header { text: "DISKS" }

            }

        }


    }

}
