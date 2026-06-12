pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

FloatingWindow {

    id: root

    visible: true

    implicitWidth: Cell.w(box.w) + Cell.w(0.9)
    implicitHeight: Cell.h(box.h) + Cell.h(0.9)

    maximumSize: Qt.size(implicitWidth,implicitHeight)
    minimumSize: Qt.size(implicitWidth,implicitHeight)

    color: Colors.bgSurface

    Component.onCompleted: {
        init_delay.start()
    }

    Timer {
        id: init_delay
        interval: 200
        onTriggered: {
            checker.running = true
        }
    }

    SequentialAnimation {
        id: success_timer
        PauseAnimation {
            duration: 800
        }
        ScriptAction {
            script: {
                status.text = "Starting config..."
            }
        }
        PauseAnimation {
            duration: 300
        }
        ScriptAction {
            script: {
                SettingsInfo.dependenciesChecked = true
            }
        }
    }

    Item {

        id: dep

        property var results: []

    }

    Cells {

        anchors.centerIn: parent

        id: box

        w: 60
        h: 20

        color: "transparent"

        ColumnLayout {

            spacing: 0

            RowLayout {

                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                spacing: Cell.w(0)

                CellText {
                    id: title
                    text: "Checking dependencies"
                    color: Colors.accentStrong
                    font: Cell.fontB
                }

                CellLoading {
                    id: title_loading
                    style: 2
                    color: Colors.accentStrong
                }

            }

            CellSeparator {
                w: box.w
                type: 2
                color: Colors.accentStrong
            }

            CellScrollView {

                id: list

                w: box.w
                h: box.h - 3 - status.h

                virtualH: true

                source: ListView {

                    interactive: false

                    model: dep.results

                    contentY: list.contentY

                    implicitWidth: Cell.w(list.contentW)
                    implicitHeight: Cell.h(list.h)

                    onContentHeightChanged: list.contentH = contentHeight

                    delegate: Cells {

                        id: dependency

                        required property string status
                        required property string manager
                        required property string pkg
                        required property string name
                        required property string description

                        color: "transparent"

                        w: list.contentW
                        h: Cell.hCount(dep_layout.implicitHeight)

                        ColumnLayout {

                            id: dep_layout

                            spacing: 0

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: 0

                                CellText {
                                    text: "Name: "
                                    color: Colors.fgDim
                                }

                                CellText {
                                    text: dependency.name
                                    color: {
                                        if (dependency.status == "START") {
                                            return Colors.fgBase
                                        } else if (dependency.status == "OK") {
                                            return Colors.success
                                        } else if (dependency.status == "MISSING") {
                                            return Colors.danger
                                        }
                                    }
                                    preferedW: list.contentW - 8 - dependency.pkg.length
                                    font: Cell.fontB
                                }

                                CellText {
                                    text: dependency.pkg
                                    color: Colors.fgSubtle
                                }

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: 0

                                CellText {
                                    text: "Status: "
                                    color: Colors.fgDim
                                }

                                CellText {
                                    text: dependency.status.replace("START","CHECKING")
                                    color: {
                                        if (dependency.status == "START") {
                                            return Colors.fgBase
                                        } else if (dependency.status == "OK") {
                                            return Colors.success
                                        } else if (dependency.status == "MISSING") {
                                            return Colors.danger
                                        }
                                    }
                                    preferedW: list.contentW - 9
                                }

                            }

                            RowLayout {

                                Layout.leftMargin: Cell.w(1)

                                spacing: 0

                                CellText {
                                    Layout.alignment: Qt.AlignTop
                                    text: "Description: "
                                    color: Colors.fgDim
                                }

                                CellText {
                                    text: dependency.description
                                    color: Colors.fgBase
                                    preferedW: list.contentW - 15
                                    wrap: true
                                }

                            }

                            CellSeparator {
                                w: list.contentW
                                type: 2
                                color: Colors.bgOverlay
                            }

                        }

                    }

                }
            }

            CellSeparator {
                w: box.w
                type: 0
                color: Colors.accentStrong
            }

            CellText {
                Layout.leftMargin: Cell.w(1)
                id: status
                text: "Initializing dependencies check..."
                color: Colors.info
                preferedW: box.w - 2
                wrap: true
            }

        }

    }

    Process {

        id: checker

        command: [SystemInfo.configdir + "/scripts/dependencies_checker.sh"]

        stdout: SplitParser {
            onRead: (text) => {

                if (text == "TERMINATE") {

                    const missing_pkg = dep.results.filter(item => item.status == "MISSING")

                    let result = "Dependencies checked... "

                    title.text = `Checked dependencies (${missing_pkg.length > 0 ? "ERROR" : "SUCCESS"})`
                    title.color = missing_pkg.length > 0 ? Colors.danger : Colors.success

                    title_loading.visible = false

                    if (missing_pkg.length == 0) {
                        result += "No missing packages found!"
                        status.color = Colors.success
                    }
                    else {
                        result += `${missing_pkg.length} package${missing_pkg.length > 1 ? "s" : ""} missing`
                        status.color = Colors.danger
                    }


                    for (const pkg of missing_pkg) {
                        result += `\n---\nName: ${pkg.name}\nInstall: ${pkg.manager == "pacman" ? "sudo pacman" : "yay"} -S ${pkg.pkg}\nDescription: ${pkg.description}`
                    }

                    status.text = result

                    const missingItems = dep.results.filter(item => item.status === "MISSING");
                    const otherItems = dep.results.filter(item => item.status !== "MISSING");

                    dep.results = [...missingItems, ...otherItems];
                    dep.resultsChanged()

                    if (missing_pkg.length == 0) success_timer.start()

                    return
                }

                const data = text.split(":")

                const object = {
                    "status"      : data[0],
                    "manager"     : data[1],
                    "pkg"         : data[2],
                    "name"        : data[3],
                    "description" : data[4],
                }

                if (object.status == "START") {
                    status.text = `Checking: Looking for package ${object.pkg}...`
                    status.color = Colors.fgBase
                } else if (object.status == "OK") {
                    status.text = `Success: Found package ${object.pkg}!`
                    status.color = Colors.success
                } else if (object.status == "MISSING") {
                    status.text = `Error: Cannot find package ${object.pkg}!`
                    status.color = Colors.danger
                }

                for (const i in dep.results) {
                    if (dep.results[i].pkg == object.pkg) {
                        dep.results[i] = object
                        dep.resultsChanged()
                        return
                    } 
                }

                dep.results.unshift(object)
                dep.resultsChanged()

            }
        }

    }

}
