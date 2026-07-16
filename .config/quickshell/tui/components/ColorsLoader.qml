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

    visible: processLog.length > 0

    implicitWidth: Cell.w(box.w) + Cell.w(1)
    implicitHeight: Cell.h(box.h) + Cell.h(1)

    maximumSize: Qt.size(implicitWidth, implicitHeight)
    minimumSize: Qt.size(implicitWidth, implicitHeight)

    color: Colors.bgSurface

    property var processLog: []

    onClosed: {
        SystemInfo.runDetached(["bash", SystemInfo.configdir + "/scripts/quit.sh"]);
    }

    Cells {
        id: box

        anchors.centerIn: parent

        w: 60
        h: 20

        color: "transparent"

        ColumnLayout {

            spacing: 0

            CellText {

                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                text: "Processing color themes"
                font: Cell.fontB
            }

            CellSeparator {
                w: box.w
                bg: "transparent"
            }

            CellScrollList {
                id: list

                snapToMax: true

                w: box.w
                h: box.h - 4

                model: [...root.processLog]

                itemH: 2

                delegate: Cells {
                    id: item

                    property var modelData

                    property string mode: modelData.mode
                    property string type: modelData.type
                    property string target: modelData.target

                    w: list.contentW
                    h: 2
                    color: "transparent"

                    ColumnLayout {

                        spacing: 0

                        CellText {
                            text: {
                                if (item.type == "prewarm") {
                                    return " Generating palette for " + item.target;
                                } else {
                                    return " Loading palette " + item.target;
                                }
                            }
                            color: "white"
                            preferedW: box.w - 2
                        }

                        CellSeparator {
                            w: list.contentW
                            color: Colors.bgOverlay
                            bg: "transparent"
                        }
                    }
                }
            }

            CellSeparator {
                w: box.w
                bg: "transparent"
            }

            CellText {
                id: status
                property var log: root.processLog[root.processLog.length - 1]
                text: {
                    if (log?.type == "prewarm") {
                        return " Generating palette for " + log?.target;
                    } else if (log?.type == "pipeline") {
                        return " Loading palette " + log?.target;
                    } else {
                        return " Processing..." + log?.target;
                    }
                }
                preferedW: box.w - 2
            }
        }
    }

    Timer {
        id: log_delay
        interval: SettingsInfo.frameTime
    }
    Timer {
        id: log_finalize
        interval: 50
        onTriggered: {
            root.processLogChanged();
        }
    }

    Timer {
        id: success
        interval: 1000 * (root.processLog.length > 0)
        onTriggered: {
            root.visible = false;
            console.log("Colors loaded successfully!");
            Colors.init();
        }
    }

    Process {
        id: loader

        command: ["python", SystemInfo.configdir + `/scripts/color_manager.py`, "--config-dir", SystemInfo.configdir, "--wallpaper-dir", SystemInfo.homedir + WallpaperInfo.cache_path]

        running: true

        onExited: {
            status.text = " Colors loaded successfully! Resolving dependencies...";
            success.restart();
        }

        stderr: SplitParser {
            onRead: text => {
                if (text) {
                    //console.log(text)
                    if (text.startsWith("[prewarm]")) {
                        const log = text.match(/\[prewarm\]\s+OK:\s+(.*)\s+→\s+(dark|light)/);
                        if (log) {
                            root.processLog.push({
                                "type": "prewarm",
                                "mode": log[2],
                                "target": log[1]
                            });
                        }
                    } else if (text.startsWith("[pipeline]")) {
                        return;
                    }
                    if (!log_delay.running) {
                        root.processLogChanged();
                        log_delay.restart();
                    }
                    log_finalize.restart();
                }
            }
        }
    }
}
