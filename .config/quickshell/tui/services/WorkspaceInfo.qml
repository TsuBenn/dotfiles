pragma Singleton

import qs.config
import qs.services

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool active: true

    property var locked: new Set()

    property bool _temp: false

    function requestAuth() {
        if (root.isLocked(HyprInfo.focusedWorkspace)) {
            FloatsManager.open("ws_auth");
        } else {
            FloatsManager.close("ws_auth");
        }
    }

    Connections {
        target: HyprInfo
        function onFocusedWorkspaceChanged() {
            if (root._temp) {
                root.update();
                return;
            }
            root.requestAuth();
        }
    }

    function isLocked(workspace: var): bool {
        return locked.has(getId(workspace));
    }

    Connections {
        target: SettingsInfo
        function onDebugSig() {
            root.toggle(HyprInfo.focusedWorkspace);
        }
    }

    function tempUnlock(workspace) {
        let set = new Set(locked);
        set.delete(getId(workspace));
        _temp = true;
        HyprInfo.exec(`SetWorkspaceLock(${JSON.stringify([...set]).replace("[", "{").replace("]", "}")})`);
    }

    function update() {
        _temp = false;
        HyprInfo.exec(`SetWorkspaceLock(${JSON.stringify([...locked]).replace("[", "{").replace("]", "}")})`);
        requestAuth();
    }

    function getId(ws) {
        return ws instanceof HyprlandWorkspace ? ws.id : ws;
    }

    function toggle(workspace) {
        const id = getId(workspace);
        if (!locked.delete(id)) {
            locked.add(id);
        }
        update();
    }

    function lock(workspace) {
        locked.add(getId(workspace));
        update();
    }

    function unlock(workspace) {
        locked.delete(getId(workspace));
        update();
    }
}
