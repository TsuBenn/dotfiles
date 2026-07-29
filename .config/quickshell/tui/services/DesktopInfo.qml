pragma Singleton

import qs.services

import QtQuick
import Quickshell

Singleton {
    id: root

    property var apps: DesktopEntries.applications.values
    property var indexedApps: []

    onAppsChanged: updateIndex()
    Component.onCompleted: updateIndex()

    function updateIndex() {
        if (!apps) {
            indexedApps = [];
            return;
        }

        var list = [];
        for (var i = 0; i < apps.length; i++) {
            var entry = apps[i];
            if (!entry)
                continue;

            var id = entry.id || "";
            var name = entry.name || "";
            var icon = entry.icon || "";

            // Split into standalone words for Level 1 precision
            var words = (id + " " + name + " " + icon).toLowerCase().split(/[\s\-_.]+/).filter(Boolean);

            list.push({
                rawEntry: entry,
                name: name,
                icon: icon,
                idExact: id,
                idLower: id.toLowerCase(),
                nameLower: name.toLowerCase(),
                iconLower: icon.toLowerCase(),
                idClean: sanitize(id),
                nameClean: sanitize(name),
                iconClean: sanitize(icon),
                words: words
            });
        }
        indexedApps = list;
    }

    function sanitize(str) {
        return str ? str.replace(/[\s\-_]/g, "").toLowerCase() : "";
    }

    // Core Search with Cascading Precision (0 -> maxIntensity)
    function fetchApp(queries, maxIntensity = 3) {
        var queryList = Array.isArray(queries) ? queries : [queries];

        // 1. SWEEP BY INTENSITY FIRST (Level 0 exact matches happen before Level 3 loose matches)
        for (var level = 0; level <= maxIntensity; level++) {

            // 2. Iterate through provided queries
            for (var i = 0; i < queryList.length; i++) {
                var rawQuery = queryList[i];
                if (!rawQuery)
                    continue;

                var qExact = String(rawQuery).trim();
                if (!qExact)
                    continue;

                var qLower = qExact.toLowerCase();
                var qClean = sanitize(qExact);

                // 3. Test apps at THIS specific level only
                for (var j = 0; j < indexedApps.length; j++) {
                    var app = indexedApps[j];

                    if (matchLevel(app, qExact, qLower, qClean, level)) {
                        return app; // First highest-precision match instantly wins!
                    }
                }
            }
        }

        return null;
    }

    function matchLevel(app, qExact, qLower, qClean, level) {
        // --- Level 0: Direct exact match ---
        if (level === 0) {
            return app.icon === qExact || app.idExact === qExact;
        }

        // --- Level 1: Full string equality OR whole standalone word match ---
        if (level === 1) {
            if (app.idLower === qLower || app.nameLower === qLower || app.iconLower === qLower) {
                return true;
            }
            for (var k = 0; k < app.words.length; k++) {
                if (app.words[k] === qLower)
                    return true;
            }
            return false;
        }

        if (!qClean)
            return false;

        // --- Level 2: Substring match (stripped symbols) ---
        if (level === 2) {
            return app.nameClean.includes(qClean) || app.idClean.includes(qClean) || app.iconClean.includes(qClean);
        }

        // --- Level 3: Mutual substring match ---
        if (level === 3) {
            var isMutual = function (target) {
                return target.length > 0 && (target.includes(qClean) || qClean.includes(target));
            };
            return isMutual(app.nameClean) || isMutual(app.idClean) || isMutual(app.iconClean);
        }

        return false;
    }

    function fetchIcon(queries, maxIntensity = 3) {
        var app = fetchApp(queries, maxIntensity);
        return app ? app.icon : "";
    }

    function fetchEntry(queries, maxIntensity = 3) {
        var app = fetchApp(queries, maxIntensity);
        return app ? app.name : "";
    }

    function fetchRawEntry(queries, maxIntensity = 3) {
        return fetchApp(queries, maxIntensity);
    }

    // Connections {
    //     target: SettingsInfo
    //     function onDebugSig() {
    //         // console.log(JSON.stringify(root.apps.find(item => item.id.includes("Zen")), null, 2));
    //         // console.log(JSON.stringify(root.apps.filter(item => item.icon.includes("zen"))));
    //         console.log(root.fetchEntry(["zen", "Zen Browser"]));
    //     }
    // }
}
