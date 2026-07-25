pragma Singleton

import qs.services
import qs.config

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var sessions: []
    property var activeSession: null

    Connections {
        target: SettingsInfo
        function onDebugSig() {
            console.log(JSON.stringify(root.normalizeSessions([...root.sessions, root.resolveActiveSession(root.activeSession)]), null, 2));
        }
    }

    Connections {
        target: PowerManager
        function onCalled(mode, countdown) {
            root.save();
        }
    }

    Connections {
        target: SystemInfo
        function onIdleChanged() {
            if (SystemInfo.idle) {
                root.pauseTracking();
            } else {
                root.resumeTracking();
            }
        }
        function onLockRequest() {
            root.pauseTracking();
        }
        function onUnlockRequest() {
            root.resumeTracking();
        }
    }

    function pauseTracking() {
        if (activeSession) {
            // Save duration up to lock time
            sessions = [...sessions, resolveActiveSession(activeSession)];
            activeSession = null; // Stops counting
            root.save();
        }
    }

    function resumeTracking() {
        // Re-trigger switchSession to pick up focused app on unlock
        switchSession();
    }

    Connections {
        target: HyprInfo
        function onFocusedClientChanged() {
            root.switchSession();
            // console.log(JSON.stringify(root.normalizeSessions(root.getTodaySessions()), null, 2));
        }
    }

    // --- DATE HELPERS ---

    function getDateString(d = new Date()) {
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, "0");
        const day = String(d.getDate()).padStart(2, "0");
        return `${year}-${month}-${day}`;
    }

    // --- FILTERING ---

    function getTodaySessions() {
        const today = getDateString();
        return getLiveSessions().filter(s => s.date === today);
    }

    function getWeekSessions() {
        const now = new Date();
        const dayOfWeek = now.getDay(); // 0 = Sun, 1 = Mon...
        const distanceToMon = (dayOfWeek === 0 ? 6 : dayOfWeek - 1);

        // Safe JS Date arithmetic (handles month boundaries automatically)
        const monday = new Date(now);
        monday.setDate(now.getDate() - distanceToMon);

        const sunday = new Date(monday);
        sunday.setDate(monday.getDate() + 6);

        const startWeek = getDateString(monday);
        const endWeek = getDateString(sunday);

        return getLiveSessions().filter(s => s.date >= startWeek && s.date <= endWeek);
    }

    function getMonthSessions() {
        const now = new Date();
        const thisMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
        return getLiveSessions().filter(s => s.date.startsWith(thisMonth));
    }

    // Includes the ongoing activeSession with its live duration!
    function getLiveSessions() {
        let list = [...sessions];
        if (activeSession) {
            list.push(resolveActiveSession(activeSession));
        }
        return list;
    }

    // --- AGGREGATION ---

    function normalizeSessions(sList: var): var {
        let result = [];
        for (const app of sList) {
            let index = result.findIndex(item => item.class === app.class && item.date === app.date);
            if (index !== -1) {
                result[index].duration += app.duration;
            } else {
                result.push({
                    "class": app.class,
                    "name": app.name,
                    "date": app.date // Preserves session's actual date
                    ,
                    "duration": app.duration
                });
            }
        }
        return result;
    }

    function calculateDuration(start_time: var): int {
        return Math.floor((Date.now() - start_time) / 1000); // Converted to seconds
    }

    function resolveActiveSession(session: var): var {
        if (!session)
            return null;
        return {
            "class": session.class,
            "title": session.title,
            "name": session.name,
            "date": session.date,
            "start_time": session.start_time,
            "duration": calculateDuration(session.start_time)
        };
    }

    function switchSession() {
        if (activeSession) {
            const completed = resolveActiveSession(activeSession);
            if (completed.duration >= 3) {
                sessions = [...sessions, completed];
            }
        }

        let client = HyprInfo.focusedClient ? HyprInfo.objClient(HyprInfo.focusedClient) : null;

        activeSession = {
            "class": client?.class || "desktop",
            "title": client?.title || "Desktop",
            "name": client ? DesktopEntries.byId(client?.class).name : "Desktop",
            "date": getDateString(),
            "start_time": Date.now(),
            "duration": 0
        };
    }

    function save() {
        console.log("ScreenTimeInfo: Saving activity...");
        if (activeSession)
            loader.setText(JSON.stringify([...sessions, resolveActiveSession(activeSession)], null, 2));
        else
            loader.setText(JSON.stringify(sessions, null, 2));
    }

    Timer {
        running: true
        interval: 300000
        repeat: true
        onTriggered: {
            root.save();
        }
    }

    FileView {
        id: loader

        path: SystemInfo.configdir + "/scripts/activity.json"

        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                setText("[]");
            }
        }

        onLoaded: {
            root.sessions = JSON.parse(text());
            root.switchSession();
        }
    }
}
