pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.components.bar
import qs.services

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {

    Item {
        Component.onCompleted: {
            init()
            Colors.applied.connect(() => {
                init()
            })
            SettingsInfo.hyprAnimChanged.connect(() => {
                init()
            })
            SettingsInfo.hyprBlurChanged.connect(() => {
                init()
            })
        }

        function init() {
            const active_border = "rgba(" + Colors.borderActive.toString().slice(1) + "ff)"
            const inactive_border = "rgba(" + Colors.borderInactive.toString().slice(1) + "ff)"
            process.exec(["bash", SystemInfo.configdir + "/scripts/init.sh", active_border, inactive_border, SettingsInfo.hyprAnim.toString() ?? false.toString(), SettingsInfo.hyprBlur.toString() ?? false.toString()])
        }
    }

    Bar {}

    FloatingWindow {

        visible: false

        minimumSize: Qt.size(Cell.w(80),Cell.h(30))
        maximumSize: Qt.size(Cell.w(80),Cell.h(30))

        color: Colors.bgSurface

        Cells {
            w: 80
            h: 30
            grid: true
            ColumnLayout {

                spacing: 0

                CellText {
                    text: "😭"
                    pure: false
                    lockPure: true
                }

                Text {
                    text: "😭"
                    font.pointSize: 12
                    font.family: "Apple Color Emoji"
                }

            }
        }

    }

    Process {
        id: process 

        stdout: StdioCollector {
            onStreamFinished: {
                console.log(text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) console.error(text)
            }
        }
    }
}

