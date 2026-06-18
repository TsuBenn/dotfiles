pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

// ─────────────────────────────────────────────────────────────────
// AuthInfo — centralized PAM verification service.
//
// Owns a single long-lived `password_checker` process (the same C
// binary that LockSession.qml uses inline). Other components ask
// AuthInfo to verify a password and listen for the verified/failed
// signals, instead of each spawning their own PAM process.
//
// API:
//   AuthInfo.verify(password)   // non-blocking; emits verified() or failed()
//   AuthInfo.authenticating     // true while a verification is in flight
//
// Signals:
//   verified()                  // PAM returned success
//   failed()                    // PAM returned failure (wrong password)
//
// Concurrency: only one verification can be in flight at a time.
// If verify() is called while authenticating, the call is dropped and
// a warning is logged. This is fine for our usage — auth flows are
// modal and block user input by design.
// ─────────────────────────────────────────────────────────────────

Singleton {

    id: root

    // True between verify() call and the resulting verified/failed signal.
    // UI uses this to disable the submit button + show a spinner.
    property bool authenticating: false

    property int authenticate_id: 0

    signal verified(id: int)
    signal failed()
    
    // signal unmatch_id()

    signal prompted(prompt: string, description: string, return_password: bool, id: int)

    function ask(prompt = "Authenticate", description = "", return_password = false) {
        root.prompted(prompt, description, return_password, root.authenticate_id)
    }

    // The PAM checker is a long-lived process: it reads passwords
    // line-by-line from stdin and writes "1" (success) or "0" (failure)
    // to stdout, one line per verification. See scripts/password_checker.c
    // for the implementation. We keep it alive for the entire shell
    // lifetime so verifications are instant (no process spawn latency).
    Process {

        id: check_pwd

        property int id: 0

        onRunningChanged: {
            // Auto-restart on crash — the PAM process should always be
            // available. If it dies (e.g. OOM kill), bring it back so
            // the next verify() works instead of silently failing.
            if (!running) {
                running = true
            }
        }

        running: true
        command: [SystemInfo.configdir + "/scripts/password_checker"]

        stdout: SplitParser {
            onRead: (text) => {
                if (text == "1") {
                    if (check_pwd.id == root.authenticate_id) {
                        root.authenticating = false
                        root.verified(root.authenticate_id++)
                    } else {
                        //root.unmatch_id()
                        console.log("AuthInfo (check_pwd): Unmatched authentication id")
                    }
                } else if (text == "0") {
                    root.authenticating = false
                    root.failed()
                }
                // Any other output (debug prints, etc.) is ignored.
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) {
                    console.log("AuthInfo (check_pwd stderr): " + text)
                }
            }
        }

    }

    // Verify a password against the local PAM stack.
    // Non-blocking: emits verified() or failed() shortly after.
    // The password string is written to stdin and immediately goes out
    // of scope on the caller side — see AuthPopup.qml for the wipe pattern.
    function verify(password: string, id: int) {
        if (!check_pwd.running) {
            console.warn("AuthInfo: check_pwd process not running, cannot verify")
            root.failed()
            return
        }
        if (root.authenticating) {
            console.warn("AuthInfo: verify() called while already authenticating, dropping")
            return
        }
        root.authenticating = true
        check_pwd.id = id
        check_pwd.write(password + "\n")
    }

}
