#!/usr/bin/env python3
import sys
import sqlite3
import json
import os
import argparse

DEFAULT_DB_PATH = os.path.expanduser("~/.config/quickshell/tui/scripts/system_data.db")

def parse_args():
    parser = argparse.ArgumentParser(description="Persistent SQLite IPC Worker")
    parser.add_argument("--db", type=str, default=DEFAULT_DB_PATH)
    return parser.parse_args()

def init_db(db_path):
    resolved_path = os.path.expanduser(db_path)
    os.makedirs(os.path.dirname(resolved_path), exist_ok=True)

    conn = sqlite3.connect(resolved_path)

    # Enable Foreign Keys
    conn.execute("PRAGMA foreign_keys = ON;")

    # Attach RAM database for uptime process ticks
    conn.execute("ATTACH DATABASE '/tmp/process_uptime.db' AS uptime;")

    # Configure Pragmas for both main (SSD) and uptime (RAM)
    conn.execute("PRAGMA main.journal_mode=WAL;")
    conn.execute("PRAGMA uptime.journal_mode=WAL;")

    conn.execute("PRAGMA main.synchronous=NORMAL;")
    conn.execute("PRAGMA uptime.synchronous=OFF;")  # Zero disk-sync wait for RAM ticks

    conn.row_factory = sqlite3.Row
    return conn

def main():
    args = parse_args()
    conn = init_db(args.db)
    cursor = conn.cursor()

    print("init", file=sys.stderr)

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        req_id = None
        try:
            parts = line.split("|", 3)
            req_id = int(parts[0])
            action = parts[1]
            sql = parts[2]
            params = json.loads(parts[3]) if len(parts) > 3 and parts[3] else []

            # Ensure params is a list/tuple for sqlite3 driver
            if not isinstance(params, (list, tuple)):
                params = [params]

            if action == "exec":
                cursor.execute(sql, params)
                conn.commit()
                response = {"id": req_id, "status": "ok", "data": cursor.lastrowid}

            elif action == "exec_many":
                statements = json.loads(sql)
                last_id = None
                try:
                    for stmt in statements:
                        # Unpack statement SQL and parameters safely
                        if isinstance(stmt, list):
                            stmt_sql = stmt[0]
                            stmt_params = stmt[1] if len(stmt) > 1 else []
                        else:
                            stmt_sql = stmt
                            stmt_params = []

                        # Ensure params is passed as a tuple/list to sqlite3
                        if not isinstance(stmt_params, (list, tuple)):
                            stmt_params = [stmt_params]

                        cursor.execute(stmt_sql, stmt_params)
                        last_id = cursor.lastrowid

                    conn.commit()
                    response = {"id": req_id, "status": "ok", "data": last_id}
                except Exception:
                    conn.rollback()
                    raise

            elif action == "query":
                cursor.execute(sql, params)
                rows = [dict(row) for row in cursor.fetchall()]
                response = {"id": req_id, "status": "ok", "data": rows}

            else:
                response = {"id": req_id, "status": "error", "message": f"Unknown action: {action}"}

        except Exception as e:
            response = {"id": req_id, "status": "error", "message": str(e)}

        print(json.dumps(response))
        sys.stdout.flush()

    conn.close()

if __name__ == "__main__":
    main()
