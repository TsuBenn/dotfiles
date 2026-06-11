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

        CellProgress {

            w: 1
            h: 1

            percent: stat.percent

            vertical: true

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

        onReleased: (button) => {
            if (button == "L") {
                PopupManager.toggle("system")
            }
        }

    }

}
