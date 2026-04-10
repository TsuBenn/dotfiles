import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    required property var box

    spacing: 0

    Cells {

        w: root.box.contentW
        h: 1

        color: "transparent"

        CellText {

            text: ` \udb82\udcc7 Uptime: ${SystemInfo.uptime}`

        }

        RowLayout {

            anchors.right: parent.right
            anchors.rightMargin: Cell.w(1)

            spacing: Cell.w(1)

            CellButton {

                padding: 1

                text: "Power"
                font: Cell.fontB

            }

        }

    }

    CellSeparator {

        w: root.box.contentW
        padding: 1

    }

    RowLayout {

        spacing: 0

        CellButton {

            padding: 0

            text: SystemInfo.wifi.ethernet ? " Ethernet  " : " WiFi      "
            color: ["transparent", Colors.bgOverlay, Colors.fgBase]
            fg: [ SystemInfo.wifi.enabled ? Colors.fgBase : Colors.fgDim, Colors.bgSurface]

            clickable: !SystemInfo.wifi.ethernet

            onReleased: (button) => {
                if (button == "L") {
                    WifiInfo.toggleWifi()
                }
            }

        }

        CellText {

            text: "█"

            color: {
                if (!SystemInfo.wifi.enabled) {
                    return Colors.bgOverlay
                } else if (SystemInfo.wifi.freq || SystemInfo.wifi.ethernet) {
                    return Colors.success
                } else {
                    return Colors.danger
                }
            }

        }

        Cells {

            w: Cell.wCount(children[1].implicitWidth) + 1
            h: 1

            color: "transparent"

            RowLayout {

                spacing: 0

                CellText {
                    text: " "
                }

                CellText {

                    text: {
                        if (!SystemInfo.wifi.enabled) {
                            return "OFF"
                        } else if (SystemInfo.wifi.ethernet) {
                            return "Connected"
                        } else if (SystemInfo.wifi.freq) {
                            return SystemInfo.wifi.name
                        } else {
                            return "Disconnected"
                        }
                    }

                    font: SystemInfo.wifi.enabled ? Cell.fontB : Cell.font

                    preferedW: root.box.contentW - 12 - 5

                    color: {
                        if (!SystemInfo.wifi.enabled) {
                            return Colors.fgSubtle
                        } else if (SystemInfo.wifi.freq || SystemInfo.wifi.ethernet) {
                            return Colors.success
                        } else {
                            return Colors.danger
                        }
                    }

                }

                CellText {

                    text: "  >"
                    color: SystemInfo.wifi.enabled ? Colors.fgBase : Colors.fgSubtle

                }
            }

            MouseControl {

                visible: SystemInfo.wifi.enabled && !SystemInfo.wifi.ethernet

                anchors.fill: parent

                onEntered: {
                    parent.color = Colors.bgOverlay
                }

                onExited: {
                    parent.color = "transparent"
                }

                onReleased: (button) => {
                    if (button == "L") {
                        root.box.view = "wifi"
                    }
                }

            }

        }

    }

    RowLayout {

        spacing: 0

        CellButton {

            padding: 0
            text: " Bluetooth "

            color: ["transparent", Colors.bgOverlay, Colors.fgBase]
            fg: [SystemInfo.bluetooth.enabled ? Colors.fgBase : Colors.fgDim, Colors.bgSurface]

            onReleased: (button) => {
                if (button == "L") {
                    WifiInfo.toggleWifi()
                }
            }

        }

        CellText {

            text: "█"

            color: {
                if (!SystemInfo.bluetooth.enabled) {
                    return Colors.bgOverlay
                } else {
                    return Colors.info
                }
            }

        }

        Cells {

            w: Cell.wCount(children[1].implicitWidth) + 1
            h: 1

            color: "transparent"

            RowLayout {

                spacing: 0

                CellText {
                    text: " "
                }

                CellText {

                    text: {
                        if (!SystemInfo.bluetooth.enabled) {
                            return "OFF"
                        } else if (SystemInfo.bluetooth.devices.length > 0) {
                            return `${SystemInfo.bluetooth.devices[0]?.name} (${SystemInfo.bluetooth.devices[0]?.battery}%) ${SystemInfo.bluetooth.devices.length > 1 ? `[+${SystemInfo.bluetooth.devices.length - 1}]` : ""}` 
                        } else {
                            return "No devices"
                        }
                    }

                    font: SystemInfo.bluetooth.devices.length > 0 ? Cell.fontB : Cell.font

                    preferedW: root.box.contentW - 12 - 5

                    color: {
                        if (!SystemInfo.bluetooth.enabled) {
                            return Colors.fgSubtle
                        } else if (SystemInfo.bluetooth.devices.length > 0) {
                            return Colors.info
                        } else {
                            return Colors.fgSubtle
                        }
                    }

                }

                CellText {

                    text: "  >"
                    color: SystemInfo.bluetooth.enabled ? Colors.fgBase : Colors.fgSubtle

                }
            }

            MouseControl {


                anchors.fill: parent

                onEntered: {
                    parent.color = Colors.bgOverlay
                }

                onExited: {
                    parent.color = "transparent"
                }

                onReleased: (button) => {
                    if (button == "L") {
                        root.box.view = "bluetooth"
                    }
                }

            }

        }

    }

}
