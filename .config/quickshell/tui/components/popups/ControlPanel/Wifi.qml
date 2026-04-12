pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

ColumnLayout {

    id: root

    required property var box

    property int h: 20

    onVisibleChanged: {
        if (visible) {
            WifiInfo.scan()
        }
    }

    spacing: 0

    function back() {
        root.box.view = "main"
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

                text: "  WiFi"
                font: Cell.fontB

            }

        }

        RowLayout {

            anchors.right: parent.right
            anchors.rightMargin: Cell.w(1)

            spacing: Cell.w(1)

            CellLoading {
                visible: WifiInfo.scanning
                style: 2
            }

            CellButton {

                text: "Refresh"
                fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle
                color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay

                clickable: !WifiInfo.scanning

                onPressed: (button) => {
                    if (button == "L") {
                        if (WifiInfo.scan(true) == 1) {
                            console.log("Wifi: Still scanning...")
                        }
                    }
                }

            }

        }

    }

    CellSeparator {

        w: root.box.contentW

    }

    CellScrollView {

        id: list

        w: root.box.contentW
        h: root.h - 2 - 2*(wifi_report.status != "")

        signal collapse(wifi: string)

        ColumnLayout {

            spacing: 0

            Repeater {
                model: WifiInfo.wifi_scan
                delegate: Cells {

                    id: wifi

                    required property string name
                    required property string security
                    required property real freq
                    required property int signal
                    required property bool in_use

                    w: list.contentW
                    h: Cell.hCount(wifi_button.implicitHeight)

                    property bool password: false

                    onVisibleChanged: {
                        password = false
                    }

                    color: "transparent"

                    function connect(pass = "") {
                        if (pass.length < 8) {
                            if (!password) {
                                password = true
                                return
                            }
                            wifi_report.status = "Info"
                            wifi_report.report = "Password must be 8 characters or more"
                            return
                        }
                        WifiInfo.connect(name, pass)
                        password = false
                    }

                    Component.onCompleted: {
                        WifiInfo.error.connect((error_wifi) => {
                            wifi_report.status = "Error"
                            wifi_report.report = error_wifi
                        })
                        WifiInfo.success.connect((success_wifi) => {
                            wifi_report.status = "Success"
                            wifi_report.report = success_wifi
                        })
                        WifiInfo.rescanned.connect(() => {
                            list.reset()
                        })
                        list.collapse.connect((name) => {
                            if (!name || !wifi) return
                            if (name != wifi.name) {
                                wifi.password = false
                            }
                        })
                    }

                    ColumnLayout {

                        id: wifi_button

                        spacing: 0

                        Cells {

                            w: list.contentW
                            h: 1

                            color: "transparent"

                            Cells {

                                id: wifi_select

                                x: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                                w: list.contentW - 2
                                h: 1

                                color: "transparent"

                            }

                            RowLayout {

                                spacing: 0

                                CellText {

                                    text: ` █  `
                                    color: wifi.in_use ? Colors.success : WifiInfo.isSaved(wifi.name) ? Colors.info : Colors.bgOverlay

                                }

                                CellText {

                                    text: `${wifi.name}`
                                    preferedW: list.contentW - 12
                                    color: !WifiInfo.scanning ? (wifi.in_use ? Colors.success : Colors.fgBase) : Colors.fgSubtle
                                    font: wifi.in_use ? Cell.fontB : Cell.font

                                }

                                CellText {

                                    text: ` ${wifi.freq >= 5 ? "[5G]" : "[2.4G]"}`
                                    preferedW: list.contentW - 4
                                    color: Colors.fgSubtle

                                }

                            }

                        }

                        CellText {

                            visible: wifi.password
                            text: ""

                        }

                        RowLayout {

                            visible: wifi.password

                            spacing: 0

                            CellText {
                                text: "  Pass: "
                            }

                            Cells {

                                w: list.contentW - 10
                                h: 1

                                color: Colors.bgOverlay

                                CellTextField {
                                    id: pass_input
                                    w: parent.w
                                    h: 1
                                    hidden: true
                                    focus: visible

                                    onEntered: (text) => {
                                        wifi.connect(text)
                                    }
                                }

                            }

                        }

                        CellText {

                            visible: wifi.password
                            text: ""

                        }

                        RowLayout {

                            Layout.leftMargin: Cell.centerWCell(implicitWidth, Cell.w(list.contentW))

                            visible: wifi.password

                            spacing: Cell.w(6)

                            CellButton {
                                text: "Connect"

                                onReleased: (button) => {
                                    if (button == "L") {
                                        wifi.connect(pass_input.text)
                                    }
                                }

                            }

                            CellButton {
                                text: "Cancel"

                                onReleased: (button) => {
                                    if (button == "L") {
                                        wifi.password = !wifi.password
                                    }
                                }

                            }

                        }

                        CellSeparator {

                            padding: 1
                            type: 2
                            w: list.contentW
                            color: Colors.bgOverlay

                        }
                    }

                    MouseControl {

                        visible: !WifiInfo.scanning

                        y: -Cell.h(0.5)

                        implicitWidth: Cell.w(list.contentW)
                        implicitHeight: Cell.h(2)

                        onEntered: {
                            wifi_select.color = Colors.bgOverlay
                        }
                        onExited: {
                            wifi_select.color = "transparent"
                        }

                        onPressed: (button) => {
                            const global = mapToGlobal(mouseX, mouseY)
                            if (button == "L") {
                                if (wifi.in_use) return
                                if (wifi.security == "--" || WifiInfo.isSaved(wifi.name)) {
                                    console.log(WifiInfo.connect(wifi.name))
                                } else {
                                    list.collapse(wifi.name)
                                    wifi.password = !wifi.password
                                }
                            } else if (button == "R") {
                                if (wifi.in_use) {
                                    ContextMenuManager.show([
                                        {label: "Disconnect", action: () => WifiInfo.disconnect(wifi.name)},
                                        {label: "Forget network", action: () => WifiInfo.forget(wifi.name)}
                                    ],global.x,global.y,undefined,wifi.name)
                                    return
                                } 
                                if (WifiInfo.isSaved(wifi.name)) {
                                    ContextMenuManager.show([
                                        {label: "Connect", action: () => WifiInfo.connect(wifi.name)},
                                        {label: "Forget network", action: () => WifiInfo.forget(wifi.name)}
                                    ],global.x,global.y,undefined,wifi.name)
                                    return
                                } 
                                ContextMenuManager.show([
                                    {label: "Connect", action: () => wifi.connect()}
                                ],global.x,global.y,undefined,wifi.name)
                            }

                        }

                    }
                }
            }

        }

    }

    CellSeparator {

        visible: wifi_report.status != ""

        w: root.box.contentW

    }

    Timer {

        id: report_cooldown

        interval: 5000
        onTriggered: {
            wifi_report.status = ""
        }

    }

    CellText {

        id: wifi_report

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
