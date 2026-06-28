pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string path: SystemInfo.configdir + "/scripts/obs_status.py"

    // ─── State ───────────────────────────────────────────────────────────────

    property bool connected:    false
    property bool recording:    false
    property bool paused:       false
    property bool streaming:    false
    property bool virtualCam:   false
    property bool replayBuffer: false

    // derived
    property bool active: recording || streaming
    property bool idle:   connected && !active

    // ─── Status string ───────────────────────────────────────────────────────

    property string status: {
        if (!connected)  return "disconnected"
        if (recording && paused) return "paused"
        if (recording)   return "recording"
        if (streaming)   return "streaming"
        if (virtualCam)  return "virtualcam"
        return "idle"
    }

    // ─── Process ─────────────────────────────────────────────────────────────

    Process {
        id: proc
        command: ["python", root.path]
        running: true

        stdout: SplitParser {
            onRead: (line) => {
                try {
                    const data = JSON.parse(line)
                    root.connected    = data.connected    ?? false
                    root.recording    = data.recording    ?? false
                    root.paused       = data.paused       ?? false
                    root.streaming    = data.streaming    ?? false
                    root.virtualCam   = data.virtualCam   ?? false
                    root.replayBuffer = data.replayBuffer ?? false
                } catch (e) {}
            }
        }

        stderr: SplitParser {
            onRead: (line) => {
                if (line && !line.includes("Errno 111")) console.warn("OBSInfo:", line)
            }
        }
    }
}
