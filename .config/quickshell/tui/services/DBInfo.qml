pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string path: "/scripts/db_worker.py"
    property string db_path: "/scripts/system_data.db"

    property int _nextId: 1
    property var _callbacks: ({})

    // Fire-and-forget execution (CREATE TABLE, INSERT, UPDATE, DELETE)
    function exec(sql, params, callback) {
        let id = root._nextId++;

        if (callback) {
            root._callbacks[id] = callback;
        }

        let paramStr = params ? JSON.stringify(params) : "";
        // Protocol: <id>|<action>|<sql>|[params_json]\n
        let payload = `${id}|exec|${sql}|${paramStr}\n`;

        process.write(payload);
    }

    // Query on demand with direct data callback (SELECT)
    function query(sql, params, callback) {
        let id = root._nextId++;

        if (callback) {
            root._callbacks[id] = callback;
        }

        let paramStr = params ? JSON.stringify(params) : "";
        // Protocol: <id>|<action>|<sql>|[params_json]\n
        let payload = `${id}|query|${sql}|${paramStr}\n`;

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
            splitMarker: ""
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
                    }
                }
            }
        }

        stderr: SplitParser {
            splitMarker: ""
            onRead: data => console.error("DBInfo error: ", data)
        }
    }
}
