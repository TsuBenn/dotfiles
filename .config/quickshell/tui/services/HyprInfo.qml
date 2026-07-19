pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

Singleton {
    id: root

    function fmt(str, ...args) {
        return str.replace(/{}/g, () => args.shift());
    }

    property list<HyprlandWorkspace> specialWorkspaces: Hyprland.workspaces.values.filter(ws => ws.id < 0)
    property list<HyprlandWorkspace> workspaces: Hyprland.workspaces.values.filter(ws => ws.id >= 0)
    property list<HyprlandMonitor> monitors: Hyprland.monitors.values
    property list<HyprlandToplevel> clients: Hyprland.toplevels.values

    // property var workspacesObj: listWorkspaces()
    // property var specialWorkspacesObj: listSpecialWorkspaces()
    // property var monitorsObj: listMonitors()
    // property var clientsObj: listClients()

    property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor

    property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    property HyprlandWorkspace focusedSpecialWorkspace: null

    property HyprlandToplevel focusedClient: Hyprland.activeToplevel

    signal hyprEvent(event: string)

    onFocusedWorkspaceChanged: {
        if (focusedSpecialWorkspace) {
            switchWorkspace(focusedSpecialWorkspace.name.replace("special:", ""));
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            root.hyprEvent(event.name);
            switch (event.name) {
            case "activespecialv2":
                {
                    const data = event.data.split(",")[0];
                    if (data != "") {
                        root.focusedSpecialWorkspace = root.matchWorkspace(parseInt(data));
                    } else {
                        root.focusedSpecialWorkspace = null;
                    }
                }
            }
        }
    }

    property bool active: true

    function isFocusedMonitor(monitor: var): bool {
        if (!monitor)
            return false;
        if (monitor instanceof HyprlandMonitor)
            return monitor.id == root.focusedMonitor?.id;
        const m = matchMonitor(monitor);
        return m ? m.id == root.focusedMonitor?.id : false;
    }

    function switchWorkspace(workspace) {
        if (workspace instanceof HyprlandWorkspace) {
            workspace.activate();
            return true;
        }
        if (Number.isInteger(workspace)) {
            Hyprland.dispatch(root.fmt("hl.dsp.focus({workspace = {}})", workspace));
            return true;
        } else if (matchWorkspace(workspace)) {
            Hyprland.dispatch(root.fmt(`hl.dsp.workspace.toggle_special("{}")`, workspace));
            return true;
        }
        return false;
    }

    function listMonitors() {
        let result = [];
        for (const m of monitors) {
            result.push(objMonitor(m));
        }
        return result;
    }

    function listSpecialWorkspaces() {
        let result = [];
        for (const w of specialWorkspaces) {
            result.push(objWorkspace(w));
        }
        return result;
    }

    function listWorkspaces() {
        let result = [];
        for (const w of workspaces) {
            result.push(objWorkspace(w));
        }
        return result;
    }

    function listClients() {
        let result = [];
        for (const c of clients) {
            result.push(objClient(c));
        }
        return result;
    }

    function objMonitor(m: HyprlandMonitor): var {
        if (!m)
            return null;
        return {
            id: m.id,
            x: m.x,
            y: m.y,
            name: m.name,
            width: m.width,
            height: m.height,
            scale: m.scale,
            focused: m.id == root.focusedMonitor?.id
        };
    }

    function matchMonitor(id: var): var {
        if (typeof id == "string")
            return monitors.find(item => RegExp(id).test(item.name)) ?? null;
        return monitors.find(item => item.id == id) ?? null;
    }

    function resolveWorkpsaceSelector(w: HyprlandWorkspace): var { // Used for dispatcher since they don't take negative id as special workspaces
        if (!w)
            return null;
        if (w.id >= 0) {
            return w.id;
        } else {
            return w.name;
        }
    }

    function objWorkspace(w: HyprlandWorkspace): var {
        if (!w)
            return null;
        return {
            id: w.id,
            name: w.name,
            focused: w.focused,
            active: w.active,
            urgent: w.urgent,
            monitor: w.monitor?.id,
            clients: w.toplevels.values.length
        };
    }

    function clientCount(workspace = null): var {
        if (!workspace)
            return objWorkspace(focusedWorkspace)?.clients ?? 0;
        return objWorkspace(matchWorkspace(workspace))?.clients ?? 0;
    }

    function matchWorkspace(id: var): var {
        const all = [...specialWorkspaces, ...workspaces];
        if (typeof id == "string")
            return all.find(item => RegExp(id).test(item.name)) ?? null;
        return all.find(item => item.id == id) ?? null;
    }

    function objClient(c: HyprlandToplevel): var {
        if (!c)
            return null;
        return {
            title: c.title,
            class: c.wayland?.appId ?? "",
            address: c.address,
            workspace: c.workspace?.id ?? null,
            monitor: c.monitor?.id ?? null,
            active: c.activated,
            urgent: c.urgent,
            maximized: c.wayland?.maximized ?? false
        };
    }

    function getClients(workspace = null) {
        if (workspace == null) {
            return focusedWorkspace.toplevels.values;
        }
        let idx = workspaces.findIndex(item => item.id == workspace || item.name == workspace);
        if (idx != -1) {
            return workspaces[idx].toplevels.values;
        }
        return [];
    }

    function matchClient(wClass = "", wTitle = "") {
        let idx = clients.findIndex(item => (wTitle != "" ? RegExp(wTitle).test(item?.title) : true) && (wClass != "" ? RegExp(wClass).test(item?.wayland.appId) : true));
        if (idx != -1) {
            return clients[idx];
        }
        return null;
    }

    function getClient(wAddress = "") {
        if (wAddress != "") {
            let idx = clients.findIndex(item => item.address == wAddress);
            if (idx != -1) {
                return clients[idx];
            }
        }
        return null;
    }

    function moveClient(client: HyprlandToplevel, workspace: var): bool {
        if (!client) {
            console.warn("HyprInfo: cannot move null client");
            return false;
        }
        if (!workspace) {
            console.warn("HyprInfo: cannot move client to a null workspace");
            return false;
        }
        if (workspace instanceof HyprlandWorkspace) {
            workspace = resolveWorkpsaceSelector(workspace);
        } else {
            console.warn("HyprInfo: cannot move client to something that's not a workspace");
            return false;
        }
        Hyprland.dispatch(root.fmt("hl.dsp.window.move({workspace = \"{}\", window = \"address:0x{}\"})", workspace, objClient(client).address));
        return true;
    }

    function focusClient(wClass, wTitle): bool {
        const c = matchClient(wClass, wTitle);
        if (!c) {
            console.warn("HyprInfo: cannot focus a null client");
            return false;
        }
        c.wayland.activate();
        return true;
    }
    function closeClient(wClass, wTitle) {
        const c = matchClient(wClass, wTitle);
        if (!c) {
            console.warn("HyprInfo: cannot close a null client");
            return false;
        }
        c.wayland.close();
        return true;
    }

    // Connections {
    //     target: SettingsInfo
    //     function onDebugSig() {
    //         console.log(JSON.stringify(root.listClients(), null, 2));
    //     }
    // }
}
