import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

Cells {

    id: root

    w: Cell.wCount(layout.implicitWidth)
    h: 1

    color: "transparent"

    property bool interactive: true

    component Stat: RowLayout {
        id: stat
        property string stat
        property int percent

        spacing: 0

        CellText {
            text: `${parent.stat} `
            font: Cell.font
            color: Colors.fgBase
        }

        CellProgressSquare {

            w: 1
            h: 1

            percent: stat.percent

            vertical: true

            type: 0

            fg: {
                if (percent > 90) return Colors.danger
                if (percent > 80) return Colors.warning
                return Colors.fgBase
            }

        }

    } 

    RowLayout {

        id: layout

        spacing: Cell.w(2)

        CellText {
            text: "FPS: " + SettingsInfo.fps
            font: Cell.fontBB
            color: {
                if (SettingsInfo.fps > 50) {
                    return Colors.success
                } else if (SettingsInfo.fps > 30) {
                    return Colors.warning
                } else {
                    return Colors.danger
                }
            }
        }

        Stat {
            stat: "CPU"
            percent: SystemInfo.cpuusage
        }
        Stat {
            stat: "RAM"
            percent: SystemInfo.memusage
        }
        Stat {
            stat: "GPU"
            percent: SystemInfo.gpuusage
        }
        Stat {
            stat: "VRAM"
            percent: SystemInfo.gpumemusage
        }

    }

    MouseControl {

        visible: root.interactive

        anchors.fill: parent

        property Component hint: ColumnLayout {

            spacing: 0

            RowLayout {

                spacing: 0

                CellText {
                    text: "CPU: "
                    color: Colors.fgDim
                    font: Cell.fontB
                }

                CellText {
                    text: `${Math.round(SystemInfo.cpuusage)}%`
                    color: {
                        const usage = Math.round(SystemInfo.cpuusage)
                        if (usage >= 90) {
                            return Colors.danger
                        } else if (usage >= 70) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }
                }

            }

            RowLayout {

                spacing: 0

                CellText {
                    text: "RAM: "
                    color: Colors.fgDim
                    font: Cell.fontB
                }
                CellText {
                    text: `${SystemInfo.ktoG(SystemInfo.memused).toFixed(1)}GB`
                    color: {
                        const usage = Math.round(SystemInfo.memusage)
                        if (usage >= 90) {
                            return Colors.danger
                        } else if (usage >= 80) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }
                }
                CellText {
                    text: `/${SystemInfo.ktoG(SystemInfo.memtotal).toFixed(1)}GB`
                    color: Colors.fgBase
                }

            }

            RowLayout {

                spacing: 0

                CellText {
                    text: "GPU: "
                    color: Colors.fgDim
                    font: Cell.fontB
                }

                CellText {
                    text: `${Math.round(SystemInfo.gpuusage)}%`
                    color: {
                        const usage = Math.round(SystemInfo.gpuusage)
                        if (usage >= 90) {
                            return Colors.danger
                        } else if (usage >= 70) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }
                }

            }

            RowLayout {

                spacing: 0

                CellText {
                    text: "VRAM: "
                    color: Colors.fgDim
                    font: Cell.fontB
                }
                CellText {
                    text: `${SystemInfo.ktoG(SystemInfo.gpumemused).toFixed(1)}GB`
                    color: {
                        const usage = Math.round(SystemInfo.memusage)
                        if (usage >= 90) {
                            return Colors.danger
                        } else if (usage >= 80) {
                            return Colors.warning
                        }
                        return Colors.fgBase
                    }
                }
                CellText {
                    text: `/${SystemInfo.ktoG(SystemInfo.gpumemtotal).toFixed(1)}GB`
                    color: Colors.fgBase
                }

            }

        }

        onReleased: (button) => {
            const global = mapToGlobal(mouseX, mouseY)
            if (button == "L") {
                PopupManager.toggle("system")
            } else if (button == "R") {
                if (PopupManager.isOpen("system")) PopupManager.close("system")
                HintManager.hint = hint
                HintManager.show(global.x, global.y, 4, "", 1000)
            }
        }

    }

}
