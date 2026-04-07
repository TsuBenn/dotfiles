import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Cells {

    id: root

    w: Cell.wCount(control.implicitWidth)
    h: 1

    color: Colors.bgOverlay

    RowLayout {

        spacing: Cell.w(0)

        id: control

        CellButton {

            id: wifi

            text: SystemInfo.wifi.ethernet ? "Ethernet" : SystemInfo.wifi.name
            font: Cell.font

            padding: 1
            clickable: false

            fg: Colors.fgBase
            color: Colors.bgOverlay

        }

        RowLayout {

            id: battery

            spacing: Cell.w(1)

            CellProgress {

                id: battery_progress

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

            CellText {

                text: SystemInfo.battery + " "
                color: {
                    if (battery_progress.percent == 100 || SystemInfo.batterystate == "charging" || SystemInfo.batterystate == "fully-charged") {
                        return Colors.success
                    } else if (battery_progress.percent <= 20) {
                        return Colors.warning
                    } else if (battery_progress.percent <= 10) {
                        return Colors.danger
                    }
                    return Colors.fgBase
                }

            }

        }

    }

}
