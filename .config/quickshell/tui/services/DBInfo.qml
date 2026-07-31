pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool active: process.running
    property string path: "/scripts/db_worker.py"
    property string db_path: "/scripts/system_data.db"

    property int _nextId: 1
    property var _callbacks: ({})

    function sql(strings, ...values) {
        let text = strings.reduce((acc, str, i) => acc + str + (i < values.length ? "?" : ""), "");
        return {
            sql: text.replace(/\s+/g, " ").trim(),
            params: values
        };
    }

    // Fire-and-forget execution (CREATE TABLE, INSERT, UPDATE, DELETE)
    function exec(query, callback) {
        let id = root._nextId++;

        if (callback) {
            root._callbacks[id] = callback;
        }

        let paramStr = query.params && query.params.length ? JSON.stringify(query.params) : "";
        let payload = `${id}|exec|${query.sql}|${paramStr}\n`;

        process.write(payload);
    }

    // Query on demand with direct data callback (SELECT)
    function query(query, callback) {
        let id = root._nextId++;

        if (callback) {
            root._callbacks[id] = callback;
        }

        let paramStr = query.params && query.params.length ? JSON.stringify(query.params) : "";
        let payload = `${id}|query|${query.sql}|${paramStr}\n`;

        process.write(payload);
    }

    function execMany(statements, callback) {
        let id = root._nextId++;

        if (callback) {
            root._callbacks[id] = callback;
        }

        let payload_array = statements.map(s => [s.sql, s.params || []]);
        let payload = `${id}|exec_many|${JSON.stringify(payload_array)}|\n`;

        process.write(payload);
    }

    Process {
        id: process

        onRunningChanged: {
            if (!running) {
                running = true;
                console.log("DBInfo: Process unexpectedly stopped! Restarting...");
            }
        }

        running: true
        command: ["python", SystemInfo.configdir + root.path, "--db", SystemInfo.configdir + root.db_path]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!data || data.trim() === "")
                    return;

                let res;
                try {
                    res = JSON.parse(data);
                } catch (e) {
                    console.error("DBInfo: Failed to parse JSON from worker:", data);
                    return;
                }

                let reqId = res.id;

                // Match response back to caller's callback using reqId
                if (reqId && root._callbacks[reqId]) {
                    let cb = root._callbacks[reqId];
                    delete root._callbacks[reqId]; // Clean up memory

                    if (res.status === "ok") {
                        cb(res.data !== undefined ? res.data : null);
                    } else {
                        console.error(`DBInfo: Error on request #${reqId}:`, res.message);
                        cb(null); // or cb(undefined, res.message) if you want to pass the error through
                    }
                }
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: data => console.error("DBInfo error: ", data)
        }
    }
}
