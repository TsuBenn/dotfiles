pragma Singleton

import qs.services

import QtQuick
import Quickshell

Singleton {
    id: root

    property var apps: DesktopEntries.applications.values

    function fetchIcon(queries, intensity) {
        let qs;
        if (typeof queries == "string") {
            qs = [queries];
        } else {
            qs = queries;
        }
        for (let q of qs) {
            q = q.toLowerCase();
            if (q == "")
                continue;
            if (/^steam_app_\d+$/.test(q)) {
                q = q.replace("steam_app_", "steam_icon_");
            }
            let icon = apps.find(s => s.icon.toLowerCase() == q || s.id.toLowerCase() == q)?.icon ?? null;
            if (icon) {
                return icon;
            }
        }
        return "unknown";
    }

    function fetchEntry(queries, intensity) {
        let qs;
        if (typeof queries == "string") {
            qs = [queries];
        } else {
            qs = queries;
        }
        for (let q of qs) {
            if (q == "")
                continue;
            let q2;
            if (q == "desktop") {
                return "Desktop";
            }
            if (/^steam_app_\d+$/.test(q)) {
                q2 = q.replace("steam_app_", "steam_icon_");
            }
            let icon = apps.find(s => s.icon == q || s.icon == q2 || s.id == q)?.name ?? null;
            if (icon) {
                return icon;
            }
        }
        return null;
    }

    // Connections {
    //     target: SettingsInfo
    //     function onDebugSig() {
    //         console.log(JSON.stringify(root.apps, null, 2));
    //     }
    // }
}
