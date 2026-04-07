import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Cells {

    id: root

    w: Cell.wCount(battery.implicitWidth)
    h: 1

    color: "transparent"

    RowLayout {

        id: battery

        spacing: Cell.w(1)

        CellText {

            text: SystemInfo.battery

        }
        
        CellProgress {

            w: 1
            h: 1

            percent: SystemInfo.onbattery ? parseInt(SystemInfo.battery) : 100

            fg: {
                if (percent == 100 || SystemInfo.batterystate == "charging" || SystemInfo.batterystate == "fully-charged") {
                    return Colors.success
                } else if (percent <= 20) {
                    return Colors.warning
                } else if (percent <= 10) {
                    return Colors.danger
                }
                return Colors.fgBase
            }

        }

    }

}
