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

    spacing: 0

    onVisibleChanged: {
        BluetoothInfo.scanOff()
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
                fg: Colors.fgBase
                color: Colors.bgOverlay

                onPressed: {
                    root.back()
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

    CellScrollView {

        id: list

        w: root.box.contentW
        h: root.h - 2 - 2*(bt_report.status != "")

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
