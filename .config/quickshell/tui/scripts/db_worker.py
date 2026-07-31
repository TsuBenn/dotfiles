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
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA synchronous=NORMAL;")
    conn.row_factory = sqlite3.Row
    return conn

def main():
    args = parse_args()
    conn = init_db(args.db)
    cursor = conn.cursor()

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

            if action == "exec":
                cursor.execute(sql, params)
                conn.commit()
                response = {"id": req_id, "status": "ok", "data": cursor.lastrowid}

            elif action == "exec_many":
                statements = json.loads(sql)
                last_id = None
                try:
                    for stmt_sql, stmt_params in statements:
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
