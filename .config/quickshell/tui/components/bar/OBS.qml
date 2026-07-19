import qs.config
import qs.modules
import qs.services

import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

CellText {
    id: root

    property bool interactive: true

    Timer {
        id: blinking

        property bool on: false

        running: OBSInfo.recording || OBSInfo.streaming
        repeat: true
        interval: 500
        onTriggered: {
            blinking.on = !blinking.on;
        }
    }

    text: ` ${OBSInfo.paused ? "!" : ""}${OBSInfo.recording ? "*" : ""}${OBSInfo.streaming ? "^" : ""}${blinking.running ? "OBS" : "obs"}${OBSInfo.virtualCam ? ">" : ""} `
    font: Cell.fontB

    color: OBSInfo.connected ? (OBSInfo.recording || OBSInfo.streaming || OBSInfo.virtualCam ? (blinking.on ? Colors.danger : Colors.warning) : Colors.fgBase) : Colors.fgSubtle

    bg: Colors.bgOverlay

    MouseControl {

        visible: root.interactive

        anchors.fill: parent

        onReleased: button => {
            if (button == "L") {
                if (HyprInfo.focusClient("com.obsproject.Studio", ""))
                    return;
                SystemInfo.runDetached(["obs"]);
            }
        }
    }
}
