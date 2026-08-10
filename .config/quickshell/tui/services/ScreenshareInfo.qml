pragma Singleton

import qs.services

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false

    property var whitelist_apps: ["discord"]

    property var sensitive_apps_class: ["discord", "vesktop"]
    property var sensitive_apps_re: [".*messenger.*"]

    property var _prev_lockedWS: new Set()
    property bool _prev_safeNotif: false

    Connections {
        target: HyprInfo
        function onClientsChanged() {
        }
    }

    Connections {
        target: WorkspaceInfo
        function onEvent(event) {
            // Ignore events if lockdown isn't active
            if (!root.active)
                return;

            const [mode, workspace] = event.split(",");
            const wsId = workspace.toString(); // Normalize to string for Set strict equality

            if (mode === "lock") {
                root._prev_lockedWS.add(wsId);
            } else if (mode === "unlock") {
                root._prev_lockedWS.delete(wsId);
            }
        }
    }

    function lockDown() {
        if (active)
            return;
        _prev_safeNotif = SettingsInfo.safeNotifications;
        SettingsInfo.safeNotifications = true;

        // 1. Take snapshot of existing locks BEFORE activating tracking
        _prev_lockedWS.clear();
        WorkspaceInfo.locked.forEach(item => _prev_lockedWS.add(String(item)));

        // 2. Lock sensitive workspaces
        const toplevels = HyprInfo.listClients();
        for (const c of toplevels) {
            if (sensitive_apps_class.includes(c.class)) {
                WorkspaceInfo.lock(c.workspace);
            } else {
                for (const re of sensitive_apps_re) {
                    let regex = new RegExp(re, "i");
                    if (regex.test(c.title)) {
                        WorkspaceInfo.lock(c.workspace);
                    }
                }
            }
        }
        active = true;
    }

    function revert() {
        if (!active)
            return;
        root.active = false;
        SettingsInfo.safeNotifications = _prev_safeNotif;
        WorkspaceInfo.locked.clear();
        _prev_lockedWS.forEach(item => WorkspaceInfo.locked.add(item));
        WorkspaceInfo.update();
    }

    Process {
        id: process

        onRunningChanged: {
            if (!running) {
                console.log("ScreenshareInfo: Process shutdown unexpectedly, restarting...");
                running = true;
            }
        }

        running: true
        command: [SystemInfo.configdir + "/scripts/pwmon"]

        stdout: SplitParser {
            onRead: text => {
                const data = JSON.parse(text).filter(item => {
                    for (const a of root.whitelist_apps) {
                        let re = new RegExp(a, "i");
                        if (re.test(item.app_name))
                            return false;
                    }
                    return true;
                });
                if (data.length == 0) {
                    root.revert();
                } else {
                    root.lockDown();
                }
            }
        }
    }
}
