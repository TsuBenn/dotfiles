pragma Singleton

import qs.services
import qs.config

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var db: null

    Timer {
        id: switching_delay
        interval: 100
        onTriggered: {
            root.startSession(HyprInfo.focusedClient?.wayland.appId ?? "desktop");
        }
    }

    Timer {
        id: autoSave
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            root.autoSaveSession();
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
            root.splitSession();
        }
    }

    Connections {
        target: PopupManager
        function onOpened(name) {
            if (name == "power") {
                // console.log("on");
                root.endSession();
            }
        }
        function onClosed(name) {
            if (name == "power") {
                // console.log("off");
                switching_delay.restart();
            }
        }
    }

    Connections {
        target: SystemInfo
        function onIdleChanged() {
            if (SystemInfo.idle) {
                root.endSession();
            } else {
                switching_delay.restart();
            }
        }
        function onLockRequest() {
            root.endSession();
        }
        function onUnlockRequest() {
            root.startSession();
        }
    }

    // Connections {
    //     target: SettingsInfo
    //     function onDebugSig() {
    //         let day = root.getDay(-3);
    //         // root.getAverageScreenTime(root.getStartWeek(day), root.getEndWeek(day), "week", function (d) {
    //         //     console.log(JSON.stringify(d));
    //         // });
    //         // root.getDayTimeline(day, function (d) {
    //         //     console.log(JSON.stringify(d, null, 2));
    //         // });
    //         root.getWeekSessions(day, function (d) {
    //             console.log(JSON.stringify(d, null, 2));
    //         });
    //         // root.getWeekDistribution(day, function (d) {
    //         //     console.log(JSON.stringify(d, null, 2));
    //         // });
    //         // root.getWeekDistribution(day, function (d) {
    //         //     console.log(JSON.stringify(d, null, 2));
    //         // });
    //     }
    // }

    Connections {
        target: DBInfo
        function onActiveChanged() {
            if (DBInfo.active) {
                root.initDB(() => {
                    root.recoverSession(() => {
                        switching_delay.restart();
                    });
                });
            }
        }
    }

    property int count: 0

    function initDB(callback) {
        DBInfo.execMany([DBInfo.sql`
                CREATE TABLE IF NOT EXISTS raw_sessions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    app_class TEXT NOT NULL,
                    start_time INTEGER DEFAULT (CAST(unixepoch('subsecond')*1000 AS INTEGER)),
                    rec_end_time INTEGER NOT NULL DEFAULT 0,
                    end_time INTEGER
                )
            `, DBInfo.sql`
                CREATE VIEW IF NOT EXISTS sessions AS
                    SELECT
                    id,
                    app_class,
                    start_time,
                    COALESCE(end_time, CAST(unixepoch('subsec')*1000 AS INTEGER)) AS end_time,
                    CAST((COALESCE(end_time, (CAST(unixepoch('subsec')*1000 AS INTEGER))) - start_time) / 1000 AS INTEGER) AS duration
                FROM raw_sessions
            `, DBInfo.sql`
                CREATE INDEX IF NOT EXISTS idx_raw_sessions_start_app
                ON raw_sessions(start_time, app_class)
            `, DBInfo.sql`
                CREATE INDEX IF NOT EXISTS idx_raw_sessions_app_end
                ON raw_sessions(app_class, end_time DESC)
            `, DBInfo.sql`
                CREATE INDEX IF NOT EXISTS idx_raw_sessions_end_start
                ON raw_sessions(end_time, start_time DESC)
        `], callback);
    }

    // Used for passing midnight purpose
    function splitSession(callback) {
        endSession(() => {
            DBInfo.exec(DBInfo.sql`
                INSERT INTO raw_sessions (app_class) VALUES (SELECT app_class FROM raw_sessions ORDER BY end_time DESC LIMIT 1)
            `, callback);
        });
    }

    function startSession(name = "", callback) {
        endSession(() => {
            DBInfo.query(DBInfo.sql`
                SELECT (CAST(unixepoch('subsec')*1000 AS INTEGER)) - end_time AS gap
                FROM raw_sessions
                WHERE app_class = ${name} AND end_time IS NOT NULL
                ORDER BY end_time DESC LIMIT 1
            `, d => {
                // console.log(JSON.stringify(d));
                if (d.length == 0 || d[0].gap >= 3000) {
                    DBInfo.exec(DBInfo.sql`
                        INSERT INTO raw_sessions (app_class) VALUES (${name})
                    `, callback);
                } else {
                    DBInfo.exec(DBInfo.sql`
                        UPDATE raw_sessions
                        SET end_time = NULL
                        WHERE id = (SELECT id FROM raw_sessions WHERE app_class = ${name} ORDER BY end_time DESC LIMIT 1)
                    `, callback);
                }
            });
        });
    }

    function endSession(callback) {
        DBInfo.execMany([DBInfo.sql`
            UPDATE raw_sessions
            SET end_time = (CAST(unixepoch('subsec') * 1000 AS INTEGER))
            WHERE id = (SELECT id FROM raw_sessions WHERE end_time IS NULL ORDER BY start_time DESC LIMIT 1)
        `, DBInfo.sql`
            DELETE FROM raw_sessions
            WHERE (end_time - start_time) < 3000 AND id = (SELECT id FROM raw_sessions ORDER BY start_time DESC LIMIT 1)
        `], callback);
    }

    function recoverSession(callback) {
        DBInfo.execMany([DBInfo.sql`
            UPDATE raw_sessions
            SET end_time = rec_end_time
            WHERE end_time IS NULL
              AND (rec_end_time - start_time) >= 3000
        `, DBInfo.sql`
            DELETE FROM raw_sessions
            WHERE end_time IS NULL OR app_class = ''
              AND (rec_end_time - start_time) < 3000
        `], callback);
    }

    function autoSaveSession(callback) {
        DBInfo.exec(DBInfo.sql`
            UPDATE raw_sessions
            SET rec_end_time = (CAST(unixepoch('subsec') * 1000 AS INTEGER))
            WHERE id = (SELECT id FROM raw_sessions WHERE end_time IS NULL ORDER BY end_time DESC LIMIT 1)
        `, callback);
    }

    function getTotalScreenTime(start = DateTime.getStartDay(), end = DateTime.getEndDay(), callback) {
        DBInfo.query(DBInfo.sql`SELECT SUM(duration) AS total FROM sessions WHERE start_time BETWEEN ${start.getTime()} AND ${end.getTime()}`, function (d) {
            callback(d[0].total);
        });
    }

    function getAverageScreenTime(date = DateTime.getDay(), range = "week", callback) {
        range = range.toLowerCase();

        // 1. Guard check & default fallback
        if (!["week", "month"].includes(range)) {
            console.error("Invalid range provided. Expected 'week' or 'month'.");
            return;
        }

        let start;
        let end;

        if (range == "week") {
            start = DateTime.getStartWeek(date);
            end = DateTime.getEndWeek(date);
        } else if (range == "month") {
            start = DateTime.getStartMonth(date);
            end = DateTime.getEndMonth(date);
        }

        getTotalScreenTime(start, end, function (totalDuration) {
            let divisor;

            if (range === "week") {
                // Calculate actual days in range instead of hardcoding 7
                const diffTime = Math.abs(end - start);
                const actualDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) || 1;
                divisor = actualDays;
            } else if (range === "month") {
                // Option A: Use actual days in range
                const diffTime = Math.abs(end - start);
                const actualDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) || 1;

                // Option B: Total days in month (if start is a Date object)
                // const year = startDate.getFullYear();
                // const month = startDate.getMonth() + 1;
                // divisor = new Date(year, month, 0).getDate();

                divisor = actualDays;
            }

            callback(totalDuration / divisor);
        });
    }

    function getDistributedDuration(start = DateTime.getStartDay(), end = DateTime.getEndDay(), labels, callback) {
        start = start.getTime();
        end = end.getTime();
        let interval = (end - start) / labels.length;
        DBInfo.query(DBInfo.sql`
            SELECT
                app_class,
                CAST(((start_time - ${start}) / ${interval}) AS INTEGER) AS slot,
                SUM(duration) AS total
            FROM sessions
            WHERE start_time BETWEEN ${start} AND ${end}
            GROUP BY app_class, slot
            ORDER BY total DESC
        `, function (d) {
            let data = {};
            for (const {
                app_class,
                slot,
                total
            } of d) {
                if (!data[app_class]) {
                    data[app_class] = labels.map(label => ({
                                label,
                                duration: 0
                            }));
                }
                if (data[app_class][slot])
                    data[app_class][slot].duration = total;
            }

            callback(Object.entries(data).map(([app_class, blocks]) => ({
                        app_class,
                        blocks
                    })));
        });
    }

    function getDayDistribution(date = DateTime.getDay(), callback) {
        getDistributedDuration(DateTime.getStartDay(date), DateTime.getEndDay(date), ["00-04", "04-08", "08-12", "12-16", "16-20", "20-24"], function (d) {
            callback(d);
        });
    }
    function getWeekDistribution(date = DateTime.getDay(), callback) {
        getDistributedDuration(DateTime.getStartWeek(date), DateTime.getEndWeek(date), ["MO", "TU", "WE", "TH", "FR", "SA", "SU"], function (d) {
            callback(d);
        });
    }
    function getMonthDistribution(date = DateTime.getDay(), callback) {
        getDistributedDuration(DateTime.getStartMonth(date), DateTime.getEndMonth(date), ["W1", "W2", "W3", "W4", "W5"], function (d) {
            callback(d);
        });
    }

    function getDayTimeline(date = DateTime.getDay(), callback) {
        let start = DateTime.getStartDay(date).getTime();
        let end = DateTime.getEndDay(date).getTime();
        DBInfo.query(DBInfo.sql`
            SELECT
                app_class,
                start_time,
                end_time,
                duration
            FROM sessions
            WHERE start_time BETWEEN ${start} AND ${end}
            ORDER BY SUM(duration) OVER (PARTITION BY app_class) DESC
        `, function (d) {
            let result = Object.values(d.reduce((acc, {
                    app_class,
                    start_time,
                    end_time,
                    duration
                }) => {
                if (!acc[app_class]) {
                    acc[app_class] = {
                        app_class,
                        blocks: []
                    };
                }
                acc[app_class].blocks.push({
                    start_time,
                    end_time,
                    duration
                });
                return acc;
            }, {}));
            // console.log(JSON.stringify(result, null, 2));
            callback(result);
        });
    }

    function compressBlocks(blocks, thresholdMs) {
        if (!blocks || blocks.length === 0)
            return [];

        // 1. Sort by start_time just to be safe
        const sorted = [...blocks].sort((a, b) => a.start_time - b.start_time);

        // 2. Start our merged list with the very first block
        const merged = [sorted[0]];

        // 3. Loop through the rest of the blocks
        for (let i = 1; i < sorted.length; i++) {
            const current = sorted[i];
            const lastMerged = merged[merged.length - 1];

            // Calculate the gap between the last ending and current starting
            const gap = current.start_time - lastMerged.end_time;

            if (gap < thresholdMs) {
                // They are close enough! Stretch the previous block's end time
                lastMerged.end_time = current.end_time;
                lastMerged.duration = lastMerged.end_time - lastMerged.start_time;
            } else {
                // Gap is too big, keep it as a separate block
                merged.push(current);
            }
        }

        return merged;
    }

    function getSessions(start = DateTime.getStartDay(), end = DateTime.getEndDay(), callback) {
        DBInfo.query(DBInfo.sql`
            SELECT
                app_class,
                SUM(duration) as total
            FROM sessions
            WHERE start_time BETWEEN ${start.getTime()} AND ${end.getTime()}
            GROUP BY app_class
            ORDER BY total DESC
        `, callback);
    }

    function getDaySessions(date = DateTime.getDay(), callback) {
        getSessions(DateTime.getStartDay(date), DateTime.getEndDay(date), callback);
    }

    function getWeekSessions(date = DateTime.getDay(), callback) {
        getSessions(DateTime.getStartWeek(date), DateTime.getEndWeek(date), callback);
    }

    function getMonthSessions(date = DateTime.getDay(), callback) {
        getSessions(DateTime.getStartMonth(date), DateTime.getEndMonth(date), callback);
    }
}
