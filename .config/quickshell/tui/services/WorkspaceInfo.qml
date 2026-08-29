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

    signal event(event: string)

    function requestAuth() {
        if (root.isLocked(HyprInfo.focusedWorkspace) && HyprInfo.focusedSpecialWorkspace == null) {
            close_delay.stop();
            // if (FloatsManager.isOpen("ws_auth"))
            //     FloatsManager.close("ws_auth");
            FloatsManager.open("ws_auth");
        } else if (locked.length == 0) {
            // close_delay.restart();
            FloatsManager.close("ws_auth");
        }
    }

    Timer {
        id: close_delay
        interval: 500
        onTriggered: {
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
            // console.log(FloatsManager.isOpen("ws_auth"));
            root.update();
            root.requestAuth();
        }
        function onFocusedSpecialWorkspaceChanged() {
            if (root._temp) {
                root.update();
                return;
            }
            root.update();
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
        return ws instanceof HyprlandWorkspace ? (ws.id?.toString() ?? null) : (ws?.toString() ?? null);
    }

    function toggle(workspace) {
        const id = getId(workspace);
        if (!id)
            return;
        if (!locked.delete(id)) {
            locked.add(id);
            event("lock," + id);
        } else {
            event("unlock," + id);
        }
        update();
    }

    function lock(workspace) {
        const id = getId(workspace);
        if (!id)
            return;
        locked.add(id);
        event("lock," + id);
        update();
    }

    function unlock(workspace) {
        const id = getId(workspace);
        if (!id)
            return;
        locked.delete(id);
        event("unlock," + id);
        update();
    }
}
