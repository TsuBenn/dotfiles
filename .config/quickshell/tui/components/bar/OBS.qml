import qs.config
import qs.modules
import qs.services

import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

CellText {

    Timer {
        id: blinking

        property bool on: false

        running: OBSInfo.recording || OBSInfo.streaming
        repeat: true
        interval: 500
        onTriggered: {
            blinking.on = !blinking.on
        }
    }

    text: ` ${OBSInfo.paused ? "!" : ""}${OBSInfo.recording ? "*" : ""}${OBSInfo.streaming ? "^" : ""}${blinking.running ? "OBS" : "obs"}${OBSInfo.virtualCam ? ">" : ""} `
    font: Cell.fontB

    color: OBSInfo.connected ? (OBSInfo.recording || OBSInfo.streaming || OBSInfo.virtualCam ? (blinking.on ? Colors.danger : Colors.warning) : Colors.fgBase) : Colors.fgSubtle

    bg: Colors.bgOverlay

    MouseControl {

        anchors.fill: parent

        onReleased: (button) => {
            if (button == "L") {
                for (const workspace of Object.keys(HyprInfo.workspaces)) {
                    for (const window of HyprInfo.workspaces[workspace]) {
                        if (window.windowclass == "com.obsproject.Studio") {
                            Hyprland.dispatch(`hl.dsp.focus({window = "address:${window.address}"})`)
                            return
                        }
                    }
                }
                SystemInfo.runDetached(["obs"])
            }
        }

    }

}
