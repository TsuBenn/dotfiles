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

    visible: !SettingsInfo.quickStart && !SettingsInfo.dependenciesChecked

    title: "tsubenn_tui_qs_depcheck"

    onClosed: {
        SystemInfo.runDetached(["bash", SystemInfo.configdir + "/scripts/quit.sh"]);
    }

    implicitWidth: Cell.w(box.w) + Cell.w(1)
    implicitHeight: Cell.h(box.h) + Cell.h(1)

    maximumSize: Qt.size(implicitWidth, implicitHeight)
    minimumSize: Qt.size(implicitWidth, implicitHeight)

    color: Colors.bgSurface

    Component.onCompleted: {
        init_delay.start();
    }

    Timer {
        id: init_delay
        interval: 200 * !SettingsInfo.quickStart
        onTriggered: {
            checker.running = true;
        }
    }

    SequentialAnimation {
        id: success_timer
        ScriptAction {
            script: {
                if (SettingsInfo.quickStart)
                    SettingsInfo.dependenciesChecked = true;
            }
        }
        PauseAnimation {
            duration: 800
        }
        ScriptAction {
            script: {
                status.text = "Starting config...";
            }
        }
        PauseAnimation {
            duration: 300
        }
        ScriptAction {
            script: {
                SettingsInfo.dependenciesChecked = true;
                if (SettingsInfo.sfx)
                    AudioInfo.playSound("wow", 1);
            }
        }
    }

    SequentialAnimation {
        id: unstable_timer
        ScriptAction {
            script: {
                status.color = Colors.danger;
                status.font = Cell.fontBB;
                status.text = "Don't say I didn't warn ya...";
            }
        }
        PauseAnimation {
            duration: 800
        }
        ScriptAction {
            script: {
                SettingsInfo.dependenciesChecked = true;
            }
        }
    }

    Item {
        id: dep

        property var results: []
    }

    Cells {
        id: box

        anchors.centerIn: parent

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
                    color: Colors.secondary
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
                bg: "transparent"
                connectEnd: true
                connectStart: true
            }

            CellScrollList {
                id: list

                w: box.w
                h: box.h - 3 - Cell.hCount(footer.implicitHeight)

                model: [...dep.results]

                delegate: Cells {
                    id: dependency

                    property var modelData
                    property string status: modelData.status
                    property string manager: modelData.manager
                    property string pkg: modelData.pkg
                    property string name: modelData.name
                    property string description: modelData.description

                    color: "transparent"

                    w: list.contentW
                    h: Cell.hCount(layout.implicitHeight)

                    ColumnLayout {
                        id: layout

                        spacing: 0

                        CellText {
                            text: ` ${dependency.name} (${dependency.status == "START" ? "CHECKING" : dependency.status})`
                            preferedW: list.contentW
                            font: Cell.fontB
                            color: {
                                if (dependency.status == "OK") {
                                    return Colors.success;
                                } else if (dependency.status == "MISSING") {
                                    return Colors.danger;
                                }
                                return Colors.fgBase;
                            }
                        }

                        Loader {

                            active: dependency.status == "MISSING"

                            sourceComponent: ColumnLayout {

                                spacing: 0

                                CellText {
                                    text: ` Install by: ${dependency.manager == "pacman" ? "sudo pacman -S" : "yay/paru -S"} ${dependency.pkg}`
                                    preferedW: list.contentW
                                    color: Colors.fgDim
                                }

                                CellText {
                                    text: " " + dependency.description
                                    wrap: true
                                    preferedW: list.contentW
                                    color: Colors.fgSubtle
                                }
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

            CellSeparator {
                w: box.w
                type: 0
                color: Colors.accentStrong
            }

            ColumnLayout {
                id: footer

                property bool error: false
                property bool unstable: false

                spacing: 0

                CellText {
                    id: status
                    Layout.leftMargin: Cell.w(1)
                    text: "Initializing dependencies check..."
                    color: Colors.info
                    preferedW: box.w - 2
                    wrap: true
                }

                CellSeparator {
                    visible: parent.error
                    w: box.w
                    type: 0
                    color: Colors.bgOverlay
                }

                RowLayout {

                    visible: parent.error

                    Layout.alignment: Qt.AlignRight
                    Layout.rightMargin: Cell.w(1)

                    spacing: Cell.w(1)

                    CellButton {

                        text: "Retry"

                        clickable: !footer.unstable

                        color: footer.unstable ? Colors.bgOverlay : [Colors.accentStrong, Colors.bgOverlay]
                        fg: footer.unstable ? Colors.fgSubtle : [Colors.onAccent, Colors.fgBase]

                        onReleased: button => {
                            if (button == "L") {
                                SystemInfo.runDetached(["bash", SystemInfo.configdir + "/scripts/revive.sh"]);
                            }
                        }
                    }

                    CellButton {

                        text: "Continue anyway"

                        clickable: !footer.unstable

                        color: footer.unstable ? Colors.bgOverlay : [Colors.bgOverlay, Colors.fgBase]
                        fg: footer.unstable ? Colors.fgSubtle : [Colors.fgBase, Colors.bgSurface]

                        onReleased: button => {
                            if (button == "L") {
                                footer.unstable = true;
                                unstable_timer.start();
                            }
                        }
                    }

                    CellButton {

                        text: "Quit"

                        clickable: !footer.unstable

                        color: footer.unstable ? Colors.bgOverlay : [Colors.bgOverlay, Colors.fgBase]
                        fg: footer.unstable ? Colors.fgSubtle : [Colors.fgBase, Colors.bgSurface]

                        onReleased: button => {
                            if (button == "L") {
                                SystemInfo.runDetached(["bash", SystemInfo.configdir + "/scripts/quit.sh"]);
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: checker

        command: [SystemInfo.configdir + "/scripts/dependencies_checker.sh", SettingsInfo.quickStart ? "fast" : "stream"]

        stdout: SplitParser {
            onRead: text => {
                if (text == "TERMINATE") {
                    const missing_pkg = dep.results.filter(item => item.status == "MISSING");

                    let result = "Dependencies checked... ";

                    title.text = `Checked dependencies (${missing_pkg.length > 0 ? "ERROR" : "SUCCESS"})`;
                    title.color = missing_pkg.length > 0 ? Colors.danger : Colors.success;

                    title_loading.visible = false;

                    if (missing_pkg.length == 0) {
                        result += "No missing packages found!";
                        status.color = Colors.success;
                    } else {
                        footer.error = true;
                        root.visible = true;
                        result += `${missing_pkg.length} package${missing_pkg.length > 1 ? "s" : ""} missing`;
                        status.color = Colors.danger;
                    }

                    status.text = result;

                    const missingItems = dep.results.filter(item => item.status === "MISSING");
                    const otherItems = dep.results.filter(item => item.status !== "MISSING");

                    dep.results = [...missingItems, ...otherItems];
                    dep.resultsChanged();

                    if (missing_pkg.length == 0)
                        success_timer.start();

                    return;
                }

                const data = text.split(":");

                const object = {
                    "status": data[0],
                    "manager": data[1],
                    "pkg": data[2],
                    "name": data[3],
                    "description": data[4]
                };

                if (object.status == "START") {
                    status.text = `Checking: Looking for package ${object.pkg}...`;
                    status.color = Colors.fgBase;
                } else if (object.status == "OK") {
                    status.text = `Success: Found package ${object.pkg}!`;
                    status.color = Colors.success;
                } else if (object.status == "MISSING") {
                    status.text = `Error: Cannot find package ${object.pkg}!`;
                    status.color = Colors.danger;
                }

                for (const i in dep.results) {
                    if (dep.results[i].pkg == object.pkg) {
                        dep.results[i] = object;
                        dep.resultsChanged();
                        return;
                    }
                }

                dep.results.unshift(object);
                dep.resultsChanged();
            }
        }
    }
}
