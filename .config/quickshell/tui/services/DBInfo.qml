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

    // Create table from schema object: { col1: "TYPE", col2: "TYPE" }
    function createTable(tableName, schemaObj, callback) {
        let cols = Object.keys(schemaObj).map(k => `${k} ${schemaObj[k]}`).join(", ");
        let sql = `CREATE TABLE IF NOT EXISTS ${tableName} (${cols});`;
        exec(sql, [], callback);
    }

    // Insert record from JS object: { col1: val1, col2: val2 }
    function insert(tableName, recordObj, callback) {
        let keys = Object.keys(recordObj);
        let placeholders = keys.map(() => "?").join(", ");
        let values = keys.map(k => recordObj[k]);

        let sql = `INSERT INTO ${tableName} (${keys.join(", ")}) VALUES (${placeholders});`;
        exec(sql, values, callback);
    }

    // Query with structured options: { where: { col: val }, orderBy: "col DESC", limit: 10 }
    function select(tableName, options, callback) {
        options = options || {};
        let sql = `SELECT * FROM ${tableName}`;
        let params = [];

        // Build WHERE clause
        if (options.where && Object.keys(options.where).length > 0) {
            let whereKeys = Object.keys(options.where);
            let whereClause = whereKeys.map(k => `${k} = ?`).join(" AND ");
            sql += ` WHERE ${whereClause}`;
            params = whereKeys.map(k => options.where[k]);
        }

        if (options.orderBy)
            sql += ` ORDER BY ${options.orderBy}`;
        if (options.limit)
            sql += ` LIMIT ${options.limit}`;

        query(sql, params, callback);
    }

    // Update with key-value pairs and where conditions
    function update(tableName, updatesObj, whereObj, callback) {
        let setKeys = Object.keys(updatesObj);
        let setClause = setKeys.map(k => `${k} = ?`).join(", ");
        let params = setKeys.map(k => updatesObj[k]);

        let whereKeys = Object.keys(whereObj || {});
        let whereClause = whereKeys.map(k => `${k} = ?`).join(" AND ");

        let sql = `UPDATE ${tableName} SET ${setClause} WHERE ${whereClause};`;
        params = params.concat(whereKeys.map(k => whereObj[k]));

        exec(sql, params, callback);
    }

    // Delete matching rows
    function deleteWhere(tableName, whereObj, callback) {
        let whereKeys = Object.keys(whereObj || {});
        let whereClause = whereKeys.map(k => `${k} = ?`).join(" AND ");
        let params = whereKeys.map(k => whereObj[k]);

        let sql = `DELETE FROM ${tableName} WHERE ${whereClause};`;
        exec(sql, params, callback);
    }

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
