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

        CellText {
            text: " "
        }

        CellButton {

            id: wifi

            text: (SystemInfo.wifi.freq ? SystemInfo.wifi.ethernet ? "Ethernet" : `${SystemInfo.wifi.name}` : "WiFi×") + " "
            font: Cell.fontB

            padding: 0
            clickable: false

            fg: SystemInfo.wifi.freq ? Colors.success : Colors.danger
            color: "transparent"

        }

        RowLayout {

            id: battery

            spacing: Cell.w(1)

            CellProgress {

                id: battery_progress

                w: 1
                h: 1

                vertical: true

                percent: SystemInfo.onbattery ? parseInt(SystemInfo.battery) : 100

                color: Colors.bgSurface

                fg: {
                    if (percent == 100 || SystemInfo.batterystate == "charging" || SystemInfo.batterystate == "fully-charged") {
                        return Colors.success
                    } else if (percent <= 10) {
                        return Colors.danger
                    } else if (percent <= 20) {
                        return Colors.warning
                    }
                    return Colors.fgSubtle
                }


            }

            CellText {

                id: battery_stat

                font: Cell.fontB

                text: (SystemInfo.battery == "100%" ? "MAX" : SystemInfo.battery) + " "

                color: {
                    if (battery_progress.percent == 100 || SystemInfo.batterystate == "charging" || SystemInfo.batterystate == "fully-charged") {
                        return Colors.success
                    } else if (battery_progress.percent <= 10) {
                        return Colors.danger
                    } else if (battery_progress.percent <= 20) {
                        return Colors.warning
                    }
                    return Colors.fgBase
                }

            }


        }

    }

}
