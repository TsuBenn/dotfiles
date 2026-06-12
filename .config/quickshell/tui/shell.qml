pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.components.bar
import qs.components
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

    Loader {

        active: SettingsInfo.dependenciesChecked

        sourceComponent: Bar {}

    }

    Loader {

        active: !SettingsInfo.dependenciesChecked

        sourceComponent: DependenciesChecker {}
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

