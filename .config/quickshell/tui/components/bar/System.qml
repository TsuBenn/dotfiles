import qs.config
import qs.services
import qs.modules

import QtQuick.Layouts
import QtQuick

RowLayout {
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

        ProgressBar {

            w: 1
            h: 1

            percent: stat.percent

            fg: {
                if (percent > 90) return Colors.danger
                if (percent > 80) return Colors.warning
                return Colors.fgBase
            }

        }

    } 

    spacing: Cell.w(2)

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
