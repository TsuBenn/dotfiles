pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {

    id: root

    w: 40
    h: 18

    CellBox {

        id: box

        property int eW: 40

        w: root.w+2
        h: root.h+2

        component Header: CellSeparator {

            property string text: "CPU"

            w: box.eW
            type: 1
            padding: 1
            title {
                text: text
                centered: false
                font: Cell.fontBB
            }

        }

        component Stat: Cells {

            id: stat

            property string key: "Name:"
            property string value: "Ryzen R5 7600"

            property color key_color: Colors.fgDim
            property color value_color: Colors.fgBase

            w: box.eW
            h: 1

            color: "transparent"

            CellText {

                anchors.left: stat.left
                anchors.leftMargin: Cell.w(1)

                text: stat.key
                color: stat.key_color

            }

            CellText {

                anchors.right: stat.right
                anchors.rightMargin: Cell.w(1)

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
                anchors.leftMargin: Cell.w(1)

                w: bar.w - 2 - bar_value.w - 1
                percent: bar.value

                fg: bar.value_color

            }

            CellText {

                anchors.right: bar.right
                anchors.rightMargin: Cell.w(1)

                id: bar_value

                text: bar.key

                color: bar.key_color

            }

        }

        RowLayout {

            spacing: 0

            ColumnLayout {

                spacing: 0

                Header { text: "CPU" }

                Stat {
                    key: "Name:"
                    value: "<b>" + SystemInfo.cpumodel + "</b>"

                    value_color: {
                        if (value.toLowerCase().includes("amd")) {
                            return Colors.blend(Colors.danger,Colors.fgBase,0.2)
                        } else if (value.toLowerCase().includes("intel")) {
                            return Colors.blend(Colors.danger,Colors.info,0.2)
                        }
                        return Colors.fgBase
                    }
                }

                Bar {

                    key: "<b>" + parseInt(SystemInfo.cpuusage).toString().padStart(3, " ") + "%</b>"
                    value: SystemInfo.cpuusage

                    key_color: {
                        if (value > 90) {
                            return Colors.warning
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }

                }

                Stat {
                    key: "Temp:"
                    value: "<b>" + parseInt(SystemInfo.cputemp) + "°C</b>"

                    value_color: {
                        if (SystemInfo.cputemp > 80) {
                            return Colors.danger
                        } else if (SystemInfo.cputemp > 70) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }
                }

                Stat {
                    key: "Freq:"
                    value: `<b>${parseInt(SystemInfo.cpubase)}MHz</b>`
                }

                Stat {
                    key: "Boost:"
                    value: `${parseInt(SystemInfo.cpuboost)}MHz`
                }

                Stat {
                    key: "Cores:"
                    value: `${parseInt(SystemInfo.cpucores)}`
                }

                Stat {
                    key: "Threads:"
                    value: `${parseInt(SystemInfo.cputhreads)}`
                }

                CellText { text: "" }

                Header { 

                    id: gpu

                    text: "GPU" 

                    property int index: 0

                }

                Stat {
                    key: "Name:"
                    value: "<b>" + SystemInfo.gpumodels[gpu.index].name + "</b>"

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

                Bar {

                    key: "<b>" + parseInt(SystemInfo.gpumodels[gpu.index].usage).toString().padStart(3, " ") + "%</b>"
                    value: SystemInfo.gpumodels[gpu.index].usage

                    key_color: {
                        if (value > 90) {
                            return Colors.warning
                        } else if (value > 80) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }

                }

            }

        }


    }

}
