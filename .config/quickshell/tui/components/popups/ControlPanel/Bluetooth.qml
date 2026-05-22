pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    required property var box

    property int h: 20

    spacing: 0

    onVisibleChanged: {
        if (visible) {
            BluetoothInfo.scanOn()
        } else {
            BluetoothInfo.scanOff()
        }
        BluetoothInfo.refresh()
    }

    function back() {
        root.box.view = "main"
    }

    Component.onCompleted: {
        BluetoothInfo.scanningChanged.connect(() => {
            bt_report.status = "Info"
            if (BluetoothInfo.scanning) {
                bt_report.report = "Scanning for devices"
                return
            }
            bt_report.report = "Stopped scanning"
        })
    }

    Timer {
        id: refresh_timer

        running: root.visible
        interval: 1000
        onTriggered: BluetoothInfo.refresh()
    }

    Cells {

        w: root.box.contentW
        h: 1

        color: "transparent"


        RowLayout {

            spacing: 0

            CellText {

                text: " "

            }

            CellButton {

                text: "<"
                fg: [Colors.onAccent, Colors.fgBase]
                color: [Colors.accentStrong, Colors.bgOverlay]

                onReleased: (button) => {
                    if (button == "L") {
                        root.back()
                    }
                }

            }

            CellText {

                text: "  Bluetooth"
                font: Cell.fontB

            }

        }

        RowLayout {

            anchors.right: parent.right
            anchors.rightMargin: Cell.w(1)

            spacing: Cell.w(1)

            CellLoading {
                visible: BluetoothInfo.scanning
                style: 2
            }

            CellText {

                text: `█`
                color: BluetoothInfo.scanning && scan.on ? Colors.info : Colors.bgOverlay

            }

            CellButton {

                text: "Scan"
                fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle
                color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay

                onPressed: (button) => {
                    if (button == "L") {
                        BluetoothInfo.scanToggle()
                    }
                }

            }

            Timer {

                id: scan

                property bool on: true

                running: BluetoothInfo.scanning
                repeat: true
                interval: 500
                onTriggered: {
                    on = !on
                }
            }

        }

    }

    CellSeparator {

        w: root.box.contentW

    }

    signal collapse()

    component Device: Cells {

        id: dev
        required property string name
        required property string mac

        property bool connected: BluetoothInfo.isConnected(mac)
        property bool saved: BluetoothInfo.isSaved(mac)

        h: Cell.hCount(dev_button.implicitHeight)

        color: "transparent"

        property bool confirmation: false
        property bool confirmation_pair: false

        Component.onCompleted: {
            BluetoothInfo.agent.connect((text, mac) => {
                if (mac == dev.mac) {
                    pass.key = text
                    confirmation = true
                }
            })
            BluetoothInfo.error.connect((text) => {
                bt_report.status = "Error"
                bt_report.report = text
            })
            BluetoothInfo.success.connect((text) => {
                bt_report.status = "Success"
                bt_report.report = text
            })
            BluetoothInfo.info.connect((text) => {
                bt_report.status = "Info"
                bt_report.report = text
            })
        }

        ColumnLayout {

            id: dev_button

            spacing: 0

            Cells {

                w: dev.w
                h: 1

                color: "transparent"

                Cells {

                    id: select

                    x: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                    w: dev.w - 2
                    h: 1

                    color: "transparent"

                }

                RowLayout {

                    spacing: 0

                    CellText {

                        text: ` █  `
                        color: dev.connected ? Colors.success : dev.saved ? Colors.info : Colors.bgOverlay

                    }

                    CellText {

                        id: dev_name

                        text: `${dev.name}`
                        preferedW: dev.w - 25
                        color: !BluetoothInfo.refreshing ? (dev.connected ? Colors.success : Colors.fgBase) : Colors.fgSubtle
                        font: dev.connected ? Cell.fontB : Cell.font

                    }

                    CellText {

                        visible: dev_name.text.length < 42

                        text: ` [${dev.mac}]`
                        color: Colors.fgSubtle
                        font: Cell.font

                    }

                }

            }

            ColumnLayout {
                spacing: 0
                visible: dev.confirmation

                CellText {
                    text: ""
                }

                CellText {

                    Layout.leftMargin: Cell.centerWCell(implicitWidth,dev.implicitWidth)

                    id: pass

                    property int key: 0
                    text: "Confirm passkey " + key
                    font: Cell.fontB

                }

                CellText {
                    text: ""
                }

                RowLayout {

                    Layout.leftMargin: Cell.centerWCell(implicitWidth,dev.implicitWidth)

                    spacing: Cell.w(6)

                    CellButton {
                        text: "Pair"
                        color: [Colors.accentStrong, Colors.bgOverlay]
                        fg: [Colors.onAccent, Colors.fgBase]

                        onPressed: (button) => {
                            dev.confirmation = false
                            if (button == "L") {
                                BluetoothInfo.send("yes")
                                dev.confirmation_pair = true
                            }
                        }
                    }

                    CellButton {
                        text: "Decline"
                        color: [Colors.accentStrong, Colors.bgOverlay]
                        fg: [Colors.onAccent, Colors.fgBase]

                        onPressed: (button) => {
                            dev.confirmation = false
                            if (button == "L") {
                                BluetoothInfo.send("no")
                            }
                        }
                    }

                }

                CellText {
                    text: ""
                }
            }

            ColumnLayout {
                spacing: 0

                visible: dev.confirmation_pair && BluetoothInfo.refreshing

                property bool pairing: BluetoothInfo.refreshing

                onPairingChanged: {
                    if (!pairing) {
                        dev.confirmation_pair = false
                    }
                }

                CellText {
                    text: ""
                }

                RowLayout {

                    spacing: 0

                    CellText {

                        Layout.leftMargin: Cell.centerWCell(implicitWidth,dev.implicitWidth)

                        text: "Pairing "

                    }

                    CellLoading {
                        style: 2
                    }

                }

                CellText {
                    text: ""
                }

            }

            CellSeparator {

                padding: 1
                type: 2
                w: dev.w
                color: Colors.bgOverlay

            }

        }

        MouseControl {

            visible: !BluetoothInfo.refreshing

            y: -Cell.h(0.5)

            implicitWidth: Cell.w(dev.w)
            implicitHeight: Cell.h(2)

            onEntered: {
                select.color = Colors.bgOverlay
            }
            onExited: {
                select.color = "transparent"
            }

            onPressed: (button) => {
                const global = mapToGlobal(mouseX, mouseY)
                if (button == "L") {
                    if (dev.connected) return
                    BluetoothInfo.connect(dev.mac)
                } else if (button == "R") {
                    if (dev.connected) {
                        ContextMenuManager.show([
                            {label: "Disconnect", action: () => BluetoothInfo.disconnect(dev.mac)},
                            {label: "Unpair", action: () => BluetoothInfo.unpair(dev.mac)}
                        ],global.x,global.y,undefined,dev.name)
                        return
                    }
                    if (dev.saved) {
                        ContextMenuManager.show([
                            {label: "Connect", action: () => BluetoothInfo.connect(dev.mac)},
                            {label: "Unpair", action: () => BluetoothInfo.unpair(dev.mac)}
                        ],global.x,global.y,undefined,dev.name)
                        return
                    }
                    ContextMenuManager.show([
                        {label: "Connect", action: () => BluetoothInfo.connect(dev.mac)},
                    ],global.x,global.y,undefined,dev.name)
                    return
                }

            }

        }

    }

    CellScrollView {

        id: list

        w: root.box.contentW
        h: root.h - 2 - 2*(bt_report.status != "")

        source: Loader {

            active: root.visible || !root.optimizeMemory

            sourceComponent: ColumnLayout {

                spacing: 0

                CellSeparator {

                    visible: BluetoothInfo.bluetooth_paired.length > 0

                    title.text: "Paired"
                    w: list.contentW

                    type: 1

                    padding: 1
                    title.color: Colors.fgSubtle
                    color: Colors.bgOverlay

                }

                ColumnLayout {

                    spacing: 0

                    Repeater {

                        model: BluetoothInfo.bluetooth_paired

                        delegate: Device {
                            w: list.contentW
                        }

                    }

                }

                CellSeparator {

                    title.text: "Scan"
                    w: list.contentW

                    type: 1

                    padding: 1
                    title.color: Colors.fgSubtle
                    color: Colors.bgOverlay

                }

                ColumnLayout {

                    spacing: 0

                    Repeater {

                        model: BluetoothInfo.bluetooth_scan

                        delegate: Device {
                            w: list.contentW
                        }

                    }

                }

            }
        }

    }


    CellSeparator {

        visible: bt_report.status != ""

        w: root.box.contentW

    }

    Timer {

        id: report_cooldown

        interval: 5000
        onTriggered: {
            bt_report.status = ""
        }

    }

    CellText {

        id: bt_report

        visible: status != ""

        onTextChanged: {
            report_cooldown.start()
        }

        property string report: ""
        property string status: ""

        text: " " + status + ": " + report
        preferedW: root.box.contentW - 2

        color: {
            if (status == "Error") {
                return Colors.danger
            } else if (status == "Success") {
                return Colors.success
            } else if (status == "Info") {
                return Colors.info
            } else if (status == "Warning") {
                return Colors.warning
            }
            return Colors.fgBase
        }

    }

}
