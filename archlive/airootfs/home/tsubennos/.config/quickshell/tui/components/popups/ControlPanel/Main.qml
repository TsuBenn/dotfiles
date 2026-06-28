import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    required property var box

    spacing: 0

    onVisibleChanged: {
        BrightnessInfo.get()
    }

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

                color: [Colors.accentStrong, Colors.bgOverlay]
                fg: [Colors.onAccent, Colors.fgBase]

                onReleased: (button) => {
                    if (button == "L") {
                        PopupManager.open("power")
                    }
                }

            }

        }

    }

    CellSeparator {

        w: root.box.contentW
        padding: 0
        color: Colors.accentStrong

    }

    RowLayout {

        spacing: 0

        CellText {
            text: " "
        }

        CellButton {

            padding: 0

            text: SystemInfo.wifi.ethernet ? " Ethernet  " : " WiFi      "
            color: ["transparent", Colors.bgOverlay, Colors.fgBase]
            fg: [ SystemInfo.wifi.enabled ? Colors.fgBase : Colors.fgDim, Colors.bgSurface]

            clickable: !SystemInfo.wifi.ethernet

            centered: false

            onReleased: (button) => {
                if (button == "L") {
                    WifiInfo.toggle()
                }
            }

        }

        CellText {

            text: " █"

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

                    preferedW: root.box.contentW - 12 - 7

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

                    text: " >"
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

    CellSeparator {

        visible: true

        w: root.box.contentW
        type: 0

        padding: 2
        color: Colors.bgOverlay

    }

    RowLayout {

        spacing: 0

        CellText {
            text: " "
        }

        CellButton {

            padding: 0
            text: " Bluetooth "

            centered: false

            color: ["transparent", Colors.bgOverlay, Colors.fgBase]
            fg: [SystemInfo.bluetooth.enabled ? Colors.fgBase : Colors.fgDim, Colors.bgSurface]

            onReleased: (button) => {
                if (button == "L") {
                    BluetoothInfo.toggle()
                }
            }

        }

        CellText {

            text: " █"

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

                    preferedW: root.box.contentW - 12 - 7

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

                    text: " >"
                    color: SystemInfo.bluetooth.enabled ? Colors.fgBase : Colors.fgSubtle

                }
            }

            MouseControl {

                visible: SystemInfo.bluetooth.enabled

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

    CellSeparator {

        type: 0
        padding: 0
        w: root.box.contentW
        color: Colors.accentDim

    }

    CellSeparator {

        type: 0
        padding: 1
        w: root.box.contentW
        color: Qt.darker(Colors.fgSubtle,1.5)
        title.text: "BRIGHTNESS"
        title.font: Cell.fontB

    }

    RowLayout {

        Layout.leftMargin: Cell.centerWCell(implicitWidth,parent.implicitWidth)

        spacing: 0

        CellText{
            text: "["
            color: Colors.fgSubtle
        }

        CellProgressSquare {

            w: root.box.w - 6
            percent: BrightnessInfo.brightness
            interactive: true
            syncDelay: 200
            adjustOnHold: false
            cellInterval: 2

            onAdjusted: (percent) => {
                BrightnessInfo.set(percent)
            }

        }

        CellText{
            text: "]"
            color: Colors.fgSubtle
        }
    }

    CellSeparator {

        visible: true

        w: root.box.contentW
        type: 2

        padding: 0
        color: Colors.accentStrong

    }

    CellTabs {

        id: tab

        Component.onCompleted: {
            PopupManager.signalSent.connect((id, sig) => {
                if (id == "control_panel") {
                    if (sig == "mixer") {
                        selected = 0
                    } else if (sig == "notif") {
                        selected = 1
                    }
                }
            })
        }

        padding: 1
        type: 0
        w: root.box.contentW
        color.fg: Colors.bgOverlay
        items: [
            "Audio",
            "Notifications"
        ]

    }

    Audio {

        box: root.box

        visible: tab.selected == 0

    }

    Notifications {

        box: root.box

        visible: tab.selected == 1

    }

    CellSeparator {

        w: root.box.contentW
        padding: 0
        color: Colors.accentStrong

    }

    RowLayout {
        spacing: 0

        CellText {
            text: ` ${SystemInfo.username}@${SystemInfo.hostname}`
            color: Colors.fgSubtle
        }
    }

}
