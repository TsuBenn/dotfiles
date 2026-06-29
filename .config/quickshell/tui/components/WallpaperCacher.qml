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

    maximumSize: Qt.size(implicitWidth,implicitHeight)
    minimumSize: Qt.size(implicitWidth,implicitHeight)

    color: Colors.bgSurface

    property var processLog: []

    onClosed: {
        SystemInfo.runDetached(["bash", SystemInfo.configdir + "/scripts/quit.sh"])
    }

    Cells {

        anchors.centerIn: parent

        id: box

        w: 60
        h: 20

        color: "transparent"

        ColumnLayout {

            spacing: 0

            CellText {

                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                text: "Processing wallpapers (New wallpaper(s) found)"
                font: Cell.fontB

            }

            CellSeparator {
                w: box.w
                bg: "transparent"
            }

            CellScrollView {

                id: list

                snapToMax: true

                w: box.w
                h: box.h - 4

                source: ColumnLayout {

                    spacing: 0

                    Repeater {

                        model: root.processLog

                        delegate: Cells {

                            id: item

                            required property string type
                            required property string target

                            w: list.contentW
                            h: 2
                            color: "transparent"

                            ColumnLayout {

                                spacing: 0

                                CellText {
                                    text: {
                                        if (item.type == "image") {
                                            return " Wallpaper found: " + item.target
                                        } else {
                                            return " Live wallpaper found: " + item.target
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

                }
            }

            CellSeparator {
                w: box.w
                bg: "transparent"
            }

            CellText {
                id: status
                property var log: root.processLog[root.processLog.length-1]
                text: ` Processing ${log?.type == "image" ? "image" : "video"}: ${log?.target}`
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
            root.processLogChanged()
        }
    }

    Timer {
        id: success
        interval: 1000*(root.processLog.length > 0)
        onTriggered: {
            root.visible = false
            console.log("Wallpapers cached successfully!")
            WallpaperInfo.init()
        }
    }

    Process {

        id: cacher

        command: [SystemInfo.configdir + "/scripts/wallpapers_cacher.sh", SystemInfo.homedir + WallpaperInfo.path, SystemInfo.cputhreads]

        
        Component.onCompleted: {
            SystemInfo.cputhreadsChanged.connect(()=> {
                if (SystemInfo.cputhreads > 0) {
                    cacher.running = true
                }
            })
        }

        onExited: {
            status.text = " Wallpapers fully cached! Moving on to processing colors"
            success.restart()
        }

        stdout: SplitParser {
            onRead: (text) => {
                if (text) {
                    //console.log(text)
                    const match = text.match(/Processing\s+(.*):\s+(.*)/)
                    if (match) {
                        root.processLog.push({
                            "type": match[1],
                            "target": match[2],
                        })
                        if (!log_delay.running) {
                            root.processLogChanged()
                            log_delay.restart()
                        }
                        log_finalize.restart()
                    }
                }
            }
        }

    }
    
}
