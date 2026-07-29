pragma Singleton

import qs.services
import qs.config

import QtQuick
import QtQuick.LocalStorage
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var sessions: []
    property var activeSession: null
    property var db: null

    Connections {
        target: SettingsInfo
        function onDebugSig() {
            DBInfo.select("sessions", {
                orderBy: "id DESC",
                limit: 2
            }, function (d) {
                console.log(JSON.stringify(d));
            });
        }
    }

    property int count: 0

    Component.onCompleted: {
        initDatabase();
        loadSessionsFromDb();
        root.switchSession();
    }

    function initDatabase() {
        // Opens local sqlite db file automatically handled by Qt
        db = LocalStorage.openDatabaseSync("ScreenTimeDB", "1.0", "Screen Time Tracker", 5000000);
        db.transaction(function (tx) {
            tx.executeSql(`
                CREATE TABLE IF NOT EXISTS sessions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    app_class TEXT,
                    title TEXT,
                    name TEXT,
                    date TEXT,
                    start_time INTEGER,
                    duration INTEGER
                )
            `);
        });
    }

    function loadSessionsFromDb() {
        let loaded = [];
        db.readTransaction(function (tx) {
            // Load history. For performance over months, you could scope this or load dynamically.
            let rs = tx.executeSql("SELECT app_class, title, name, date, start_time, duration FROM sessions ORDER BY start_time ASC");
            for (let i = 0; i < rs.rows.length; i++) {
                let row = rs.rows.item(i);
                loaded.push({
                    "app_class": row.app_class,
                    "title": row.title,
                    "name": row.name,
                    "date": row.date,
                    "start_time": row.start_time,
                    "duration": row.duration
                });
            }
        });
        root.sessions = loaded;
    }

    Connections {
        target: PopupManager
        function onOpened(name) {
            if (name == "power") {
                // console.log("on");
                root.pauseTracking();
            }
        }
        function onClosed(name) {
            if (name == "power") {
                // console.log("off");
                root.resumeTracking();
            }
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
            sessions = [...sessions, resolveActiveSession(activeSession)];
            activeSession = null;
            // root.save();
        }
    }

    function resumeTracking() {
        switchSession();
    }

    Timer {
        id: switching_delay
        interval: 100
        onTriggered: {
            root.switchSession();
        }
    }

    Connections {
        target: HyprInfo
        function onFocusedClientChanged() {
            switching_delay.restart();
        }
    }

    Connections {
        target: DateTime
        function onDateChanged() {
            root.switchSession();
        }
    }

    function getTotalScreenTime(sessionsList) {
        if (!sessionsList || sessionsList.length === 0)
            return 0;
        return sessionsList.reduce((total, session) => total + session.duration, 0);
    }

    function calculateTimeDivisions(daysModel, steps = 4) {
        if (!daysModel || daysModel.length === 0) {
            return {
                axisMaxSeconds: 3600
            };
        }
        let realMax = Math.max(...daysModel.map(d => d.duration || 0));
        if (realMax === 0)
            return {
                axisMaxSeconds: 3600
            };

        let paddedMax = realMax * 1.15;
        let axisMaxSeconds;

        if (paddedMax <= 3600) {
            axisMaxSeconds = Math.ceil(paddedMax / 900) * 900;
        } else {
            let stepInSeconds = 7200;
            axisMaxSeconds = Math.ceil(paddedMax / stepInSeconds) * stepInSeconds;
        }
        return {
            axisMaxSeconds
        };
    }

    function getPeriodDayCount(range, date = new Date()) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        let periodStart, periodLength;

        if (range === 0) {
            return 1;
        } else if (range === 1) {
            const d = new Date(date);
            const monOffset = (d.getDay() === 0) ? 6 : d.getDay() - 1;
            periodStart = new Date(d);
            periodStart.setDate(d.getDate() - monOffset);
            periodStart.setHours(0, 0, 0, 0);
            periodLength = 7;
        } else {
            periodStart = new Date(date.getFullYear(), date.getMonth(), 1);
            periodLength = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
        }

        const periodEnd = new Date(periodStart);
        periodEnd.setDate(periodStart.getDate() + periodLength - 1);

        if (periodEnd < today)
            return periodLength;

        const elapsed = Math.floor((today - periodStart) / 86400000) + 1;
        return Math.min(elapsed, periodLength);
    }

    function getAverageScreenTime(sessionsList, range, date = new Date()) {
        const total = getTotalScreenTime(sessionsList);
        const days = getPeriodDayCount(range, date);
        return days > 0 ? total / days : 0;
    }

    function formatDuration(totalSeconds) {
        if (!totalSeconds || totalSeconds < 1)
            return "0s";

        let days = Math.floor(totalSeconds / 86400);
        let hours = Math.floor((totalSeconds % 86400) / 3600);
        let minutes = Math.floor((totalSeconds % 3600) / 60);
        let seconds = Math.floor(totalSeconds % 60);

        if (days > 0)
            return hours > 0 ? `${days}d${hours}h` : `${days}d`;
        if (hours > 0)
            return minutes > 0 ? `${hours}h${minutes}m` : `${hours}h`;
        if (minutes > 0)
            return seconds > 0 ? `${minutes}m${seconds}s` : `${minutes}m`;
        return `${seconds}s`;
    }

    function getDayStartMs(date = new Date()) {
        const d = new Date(date);
        d.setHours(0, 0, 0, 0);
        return d.getTime();
    }

    function getDayEndMs(date = new Date()) {
        return getDayStartMs(date) + 86400000;
    }

    function getAppDayBuckets(app_class, targetDate = new Date(), bucketHours = 2) {
        if (!app_class)
            return [];

        const bucketCount = Math.ceil(24 / bucketHours);
        const buckets = [];
        for (let i = 0; i < bucketCount; i++) {
            const startH = i * bucketHours;
            const endH = Math.min(startH + bucketHours, 24);
            buckets.push({
                day: `${String(startH).padStart(2, '0')}-${String(endH).padStart(2, '0')}`,
                duration: 0
            });
        }

        const isAll = (app_class === "all");
        const daySessions = getDaySessions(targetDate.getFullYear(), targetDate.getMonth() + 1, targetDate.getDate()).filter(s => isAll || s.app_class === app_class);

        const dayStartMs = getDayStartMs(targetDate);
        const dayEndMs = getDayEndMs(targetDate);

        daySessions.forEach(session => {
            let segStart = Math.max(session.start_time, dayStartMs);
            let segEnd = Math.min(session.start_time + session.duration * 1000, dayEndMs);
            if (segEnd <= segStart)
                return;

            let cursor = segStart;
            while (cursor < segEnd) {
                const hoursSinceMidnight = (cursor - dayStartMs) / 3600000;
                const bucketIndex = Math.min(Math.floor(hoursSinceMidnight / bucketHours), bucketCount - 1);
                const bucketEndMs = dayStartMs + (bucketIndex + 1) * bucketHours * 3600000;
                const sliceEnd = Math.min(segEnd, bucketEndMs);

                buckets[bucketIndex].duration += (sliceEnd - cursor) / 1000;
                cursor = sliceEnd;
            }
        });

        return buckets;
    }

    function getAppWeeklyDays(app_class, targetDate = new Date()) {
        if (!app_class)
            return [];

        function toLocalISO(dateObj) {
            let y = dateObj.getFullYear();
            let m = String(dateObj.getMonth() + 1).padStart(2, '0');
            let d = String(dateObj.getDate()).padStart(2, '0');
            return `${y}-${m}-${d}`;
        }

        let now = new Date(targetDate);
        let dayOfWeek = now.getDay();
        let monOffset = (dayOfWeek === 0) ? 6 : dayOfWeek - 1;

        let monday = new Date(now);
        monday.setDate(now.getDate() - monOffset);
        monday.setHours(0, 0, 0, 0);

        let weekSessions = getWeekSessions(now.getFullYear(), now.getMonth() + 1, now.getDate());
        let isAll = (app_class === "all");
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
        let result = [];

        for (let i = 0; i < 7; i++) {
            let currentDay = new Date(monday);
            currentDay.setDate(monday.getDate() + i);
            let dateStr = toLocalISO(currentDay);

            let dayDuration = weekSessions.filter(s => (isAll || s.app_class === app_class) && s.date === dateStr).reduce((sum, s) => sum + s.duration, 0);

            result.push({
                "day": dayNames[i],
                "date": dateStr,
                "duration": dayDuration
            });
        }
        return result;
    }

    function getAppMonthlyWeeks(app_class, year, month) {
        let monthSessions = getMonthSessions(year, month);
        let isAll = (app_class === "all");
        let appSessions = monthSessions.filter(s => isAll || s.app_class === app_class);
        let weeks = [
            {
                day: "W1",
                duration: 0
            },
            {
                day: "W2",
                duration: 0
            },
            {
                day: "W3",
                duration: 0
            },
            {
                day: "W4",
                duration: 0
            },
            {
                day: "W5",
                duration: 0
            }
        ];

        appSessions.forEach(session => {
            let dayOfMonth = new Date(session.start_time).getDate();
            let weekIndex = Math.min(Math.floor((dayOfMonth - 1) / 7), 4);
            weeks[weekIndex].duration += session.duration;
        });

        return weeks;
    }

    function formatTimestampToHHMM(timestampMs = Date.now()) {
        if (!timestampMs)
            return "00:00";
        const date = new Date(timestampMs);
        const hours = date.getHours();
        const minutes = date.getMinutes();
        return (hours < 10 ? "0" + hours : hours) + ":" + (minutes < 10 ? "0" + minutes : minutes);
    }

    function getDayTimelineByApp(date = new Date()) {
        const dayStr = getDateString(date);
        const daySessions = getLiveSessions().filter(s => s.date === dayStr);

        const rows = {};
        daySessions.forEach(s => {
            // console.log(JSON.stringify(s.name));
            if (!rows[s.app_class]) {
                rows[s.app_class] = {
                    app_class: s.app_class,
                    name: s.name,
                    blocks: []
                };
            }
            rows[s.app_class].name = s.name;
            rows[s.app_class].blocks.push({
                start: s.start_time,
                end: s.start_time + s.duration * 1000,
                rawDurationMs: s.duration * 1000,
                sessionCount: 1
            });
        });

        return Object.values(rows).sort((a, b) => {
            const totalA = a.blocks.reduce((sum, blk) => sum + (blk.end - blk.start), 0);
            const totalB = b.blocks.reduce((sum, blk) => sum + (blk.end - blk.start), 0);
            return totalB - totalA;
        });
    }

    function mergeAdjacentBlocks(blocks, gapToleranceMs = 5000) {
        if (blocks.length === 0)
            return [];
        const sorted = [...blocks].sort((a, b) => a.start - b.start);

        const merged = [
            {
                start: sorted[0].start,
                end: sorted[0].end,
                rawDurationMs: sorted[0].rawDurationMs || (sorted[0].end - sorted[0].start),
                sessionCount: sorted[0].sessionCount || 1
            }
        ];

        for (let i = 1; i < sorted.length; i++) {
            const last = merged[merged.length - 1];
            const current = sorted[i];

            if (current.start - last.end <= gapToleranceMs) {
                last.end = Math.max(last.end, current.end);
                last.rawDurationMs += (current.rawDurationMs || (current.end - current.start));
                last.sessionCount += (current.sessionCount || 1);
            } else {
                merged.push({
                    start: current.start,
                    end: current.end,
                    rawDurationMs: current.rawDurationMs || (current.end - current.start),
                    sessionCount: current.sessionCount || 1
                });
            }
        }
        return merged;
    }

    function getDateString(d = new Date()) {
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, "0");
        const day = String(d.getDate()).padStart(2, "0");
        return `${year}-${month}-${day}`;
    }

    function getDaySessions(year = DateTime.year, month = DateTime.month_numeral, day = DateTime.date) {
        const m = String(month).padStart(2, "0");
        const d = String(day).padStart(2, "0");
        const targetDate = `${year}-${m}-${d}`;
        return getLiveSessions().filter(s => s.date === targetDate);
    }

    function getWeekSessions(year = DateTime.year, month = DateTime.month_numeral, day = DateTime.date) {
        const now = new Date(year, month - 1, day);
        const dayOfWeek = now.getDay();
        const distanceToMon = (dayOfWeek === 0 ? 6 : dayOfWeek - 1);

        const monday = new Date(now);
        monday.setDate(now.getDate() - distanceToMon);

        const sunday = new Date(monday);
        sunday.setDate(monday.getDate() + 6);

        const startWeek = getDateString(monday);
        const endWeek = getDateString(sunday);

        return getLiveSessions().filter(s => s.date >= startWeek && s.date <= endWeek);
    }

    function getMonthSessions(year = DateTime.year, month = DateTime.month_numeral) {
        const now = new Date(year, month - 1);
        const m = String(now.getMonth() + 1).padStart(2, "0");
        const targetMonth = `${now.getFullYear()}-${m}`;
        return getLiveSessions().filter(s => s.date.startsWith(targetMonth));
    }

    function getLiveSessions() {
        let list = [...sessions];
        if (activeSession) {
            list.push(resolveActiveSession(activeSession));
        }
        return list;
    }

    function normalizeSessions(sList) {
        let result = [];
        for (const app of sList) {
            let index = result.findIndex(item => item.app_class === app.app_class);
            if (index !== -1) {
                // 2. Keep the newest resolved name and accumulate duration
                result[index].name = app.name;
                result[index].duration += app.duration;
            } else {
                result.push({
                    "app_class": app.app_class,
                    "name": app.name,
                    "date": app.date,
                    "duration": app.duration
                });
            }
        }

        // Sort descending: highest duration first
        // console.log(JSON.stringify(result, null, 2));
        return result.sort((a, b) => b.duration - a.duration);
    }

    function calculateDuration(start_time: var): int {
        return Math.floor((Date.now() - start_time) / 1000);
    }

    function resolveActiveSession(session: var): var {
        if (!session)
            return null;
        return {
            "app_class": session.app_class,
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
                let merged = false;

                if (sessions.length > 0) {
                    let last = sessions[sessions.length - 1];
                    let endOfLastMs = last.start_time + (last.duration * 1000);
                    let gapSeconds = Math.abs(completed.start_time - endOfLastMs) / 1000;

                    if (last.app_class === completed.app_class && last.title === completed.title && last.date === completed.date && gapSeconds <= 3) {
                        last.duration += completed.duration;
                        merged = true;
                        // Update existing row in DB instead of duplicating
                        updateLastDbSession(last.duration);
                    }
                }

                if (!merged) {
                    sessions = [...sessions, completed];
                    insertDbSession(completed);
                }
            }
        }

        let client = HyprInfo.focusedClient ? HyprInfo.objClient(HyprInfo.focusedClient) : null;

        if (client) {
            let name = DesktopInfo.fetchEntry([client.app_class, client.title], 2);
            activeSession = {
                "app_class": client.app_class,
                "title": client.title,
                "name": name != "" ? name : client.app_class,
                "date": getDateString(),
                "start_time": Date.now(),
                "duration": 0
            };
        } else {
            activeSession = {
                "app_class": "desktop",
                "title": "Desktop",
                "name": "Desktop",
                "date": getDateString(),
                "start_time": Date.now(),
                "duration": 0
            };
        }
    }

    // --- DB WRITE HELPERS ---

    function insertDbSession(session) {
        if (!db)
            return;
        db.transaction(function (tx) {
            tx.executeSql("INSERT INTO sessions (app_class, title, name, date, start_time, duration) VALUES (?, ?, ?, ?, ?, ?)", [session.app_class, session.title, session.name, session.date, session.start_time, session.duration]);
        });
    }

    function updateLastDbSession(newDuration) {
        if (!db)
            return;
        db.transaction(function (tx) {
            // Updates the latest inserted row for duration merging
            tx.executeSql("UPDATE sessions SET duration = ? WHERE id = (SELECT MAX(id) FROM sessions)", [newDuration]);
        });
    }

    // --- CACHE & CRASH RECOVERY ---

    FileView {
        id: activeCacheFile
        path: SystemInfo.configdir + "/scripts/active_cache.json"

        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                setText("");
            }
        }

        onLoaded: {
            let raw = text().trim();
            if (raw.length > 0) {
                try {
                    let cached = JSON.parse(raw);
                    console.log("ScreenTimeInfo: Crash detected! Recovering active session...");

                    // Calculate duration up until the last known heartbeat/crash point
                    let recoveredDuration = Math.floor((Date.now() - cached.start_time) / 1000);
                    if (recoveredDuration >= 3) {
                        cached.duration = recoveredDuration;
                        insertDbSession(cached);
                        console.log("ScreenTimeInfo: Recovered session for " + cached.app_class + " (" + recoveredDuration + "s)");
                    }
                } catch (err) {
                    console.log("ScreenTimeInfo: Failed to parse active cache: " + err);
                }
            }
            // Clear cache on startup after checking
            clearActiveCache();
        }
    }

    function writeActiveCache() {
        if (!activeSession) {
            clearActiveCache();
            return;
        }
        let currentLive = resolveActiveSession(activeSession);
        // Write the current live state to the cache file
        activeCacheFile.setText(JSON.stringify(currentLive));
    }

    function clearActiveCache() {
        activeCacheFile.setText("");
    }

    // Heartbeat timer to update cache every 2 minutes (120000ms)
    Timer {
        running: true
        interval: 60000
        repeat: true
        onTriggered: {
            root.writeActiveCache();
        }
    }
}
