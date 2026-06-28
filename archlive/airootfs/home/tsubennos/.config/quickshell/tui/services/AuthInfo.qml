pragma Singleton

import qs.services

import Quickshell
import Quickshell.Io
import QtQuick

// ─────────────────────────────────────────────────────────────────
// AuthInfo — centralized PAM verification service.
//
// Owns the entire auth flow:
//   1. Caller calls AuthInfo.verify(prompt, description, callback)
//   2. AuthInfo opens AuthPopup (via the prompted signal)
//   3. User enters password in AuthPopup, which calls AuthInfo._check(password)
//   4. AuthInfo writes the password to the PAM process
//   5. PAM responds → AuthInfo._dispatch(success)
//      - On success: fires the callback with (true, password) and closes AuthPopup
//      - On failure: tells AuthPopup to show error + retry (flow continues)
//      - On cancel (user closes AuthPopup, or AuthInfo.cancel()):
//        fires the callback with (false, "") and closes AuthPopup
//
// API:
//   AuthInfo.verify(prompt, description, callback) → bool
//     prompt:      title shown in AuthPopup (e.g., "Install firefox")
//     description: subtext shown under the title (e.g., "Your password
//                  will be used to run pacman as root.")
//     callback:    (success: bool, password: string) => void
//                  Called exactly once when the auth flow completes
//                  (success or cancel).
//                  On success: success=true, password=the verified password
//                  On cancel: success=false, password=""
//     Returns true if the flow started, false if another auth is in progress.
//
//   AuthInfo.cancel()
//     Aborts the current auth flow. Fires the pending callback with
//     (false, "") and closes AuthPopup.
//
// State properties:
//   AuthInfo.authenticating
//     True for the ENTIRE auth session — from verify() until the callback
//     fires. Used by external callers to know "an auth flow is ongoing,
//     don't start another one."
//
//   AuthInfo.checking
//     True only while PAM is verifying a password — from _check() until
//     PAM responds. Used by AuthPopup to disable the password field +
//     Verify button while the check is in flight. Resets to false on
//     PAM response (success or failure), allowing the user to retry
//     immediately on failure without the field staying disabled.
//
// Concurrency: ONE auth flow at a time. verify() returns false if
// another is in progress.
//
// PAM process: long-lived `password_checker` binary. Reads passwords
// line-by-line from stdin, writes "1" (success) or "0" (failure) to
// stdout per verification. Auto-restarts on crash.
//
// Timeout: 5 seconds per PAM verification. If PAM doesn't respond,
// `checking` resets to false and the user sees an error + can retry.
// The auth flow itself is NOT aborted (user can still try again or cancel).
// ─────────────────────────────────────────────────────────────────

Singleton {

    id: root

    // True for the entire auth session — from verify() until the callback
    // fires. External callers use this to avoid starting a second auth
    // flow while one is in progress.
    property bool authenticating: false

    // True only while PAM is verifying a password. AuthPopup binds the
    // password field's `disabled` to this so the user can't submit a
    // second password while the first is still being checked. Resets to
    // false on PAM response (success or failure), so the user can retry
    // immediately on failure.
    property bool checking: false

    // ── Internal state ──
    property var _callback: null
    property string _pendingPassword: ""
    property string _pendingPrompt: ""
    property string _pendingDescription: ""

    readonly property int _pamTimeoutMs: 5000

    // ── Signals (for AuthPopup to listen to) ──

    // Fired when a new auth flow starts. AuthPopup opens and shows
    // the prompt + description.
    signal prompted(string prompt, string description)

    // Fired when the current PAM verification succeeded. AuthPopup
    // shows "success" briefly, then AuthInfo closes it via `closed()`.
    signal verifySucceeded()

    // Fired when the current PAM verification failed (wrong password
    // or timeout). AuthPopup shows the error and lets the user retry.
    // The auth flow is NOT over — the user can try again or cancel.
    signal verifyFailed(string reason)

    // Fired when the auth flow is over (success or cancel).
    // AuthPopup closes itself.
    signal closed()

    Timer {
        id: _pam_timeout
        interval: root._pamTimeoutMs
        onTriggered: {
            if (root.checking) {
                console.warn("AuthInfo: PAM response timeout")
                root.checking = false
                root._pendingPassword = ""
                root.verifyFailed("PAM timeout — please try again")
            }
        }
    }

    // The PAM checker is a long-lived process: it reads passwords
    // line-by-line from stdin and writes "1" (success) or "0" (failure)
    // to stdout, one line per verification.
    Process {

        id: check_pwd

        onRunningChanged: {
            if (!running) running = true  // auto-restart on crash
        }

        running: true
        command: [SystemInfo.configdir + "/scripts/password_checker"]

        stdout: SplitParser {
            onRead: (text) => {
                if (text == "1") {
                    root._dispatch(true)
                } else if (text == "0") {
                    root._dispatch(false)
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text) console.log("AuthInfo (check_pwd stderr): " + text)
            }
        }

    }

    // ── Public API ──

    // verify(prompt, description, callback) → bool
    //
    // Starts an auth flow. AuthPopup opens, user enters password,
    // PAM verifies, callback fires with the result.
    //
    // Returns true if the flow started, false if another is in progress.
    function verify(prompt: string, description: string, callback: var): bool {
        if (root.authenticating) {
            console.warn("AuthInfo: verify() called while another auth is in progress, rejecting")
            return false
        }

        root._callback = callback
        root._pendingPrompt = prompt
        root._pendingDescription = description
        root._pendingPassword = ""
        root.authenticating = true
        root.checking = false  // not checking yet — user hasn't entered password

        // Tell AuthPopup to open with this prompt + description.
        root.prompted(prompt, description)

        return true
    }

    // Cancel the current auth flow. Fires the pending callback with
    // (false, "") and closes AuthPopup.
    function cancel() {
        if (!root.authenticating) return
        console.log("AuthInfo: cancelling auth flow")
        root._finish(false, "")
        root.closed()
    }

    // ── Called by AuthPopup when the user submits a password ──
    // This is the bridge from AuthPopup's UI to the PAM process.
    // Not for external callers — AuthPopup calls this when the user
    // presses Enter or clicks Verify.
    function _check(password: string) {
        if (!root.authenticating) {
            console.warn("AuthInfo._check called but no auth flow in progress")
            return
        }
        if (root.checking) {
            console.warn("AuthInfo._check called while already checking, ignoring")
            return
        }
        if (!check_pwd.running) {
            console.warn("AuthInfo: check_pwd process not running")
            root.verifyFailed("Auth backend unavailable")
            return
        }

        root._pendingPassword = password
        root.checking = true
        _pam_timeout.restart()
        check_pwd.write(password + "\n")
    }

    // ── Internal: handle PAM response ──
    function _dispatch(success: bool) {
        if (!root.checking) return  // already handled (e.g., timeout or cancel)

        root.checking = false
        _pam_timeout.stop()

        if (success) {
            // PAM verified — flow is over, fire the callback with the password.
            root.verifySucceeded()  // tell AuthPopup to show success
            root._finish(true, root._pendingPassword)
        } else {
            // PAM rejected — let the user retry. Flow continues.
            root.verifyFailed("Wrong password")
            root._pendingPassword = ""
        }
    }

    // ── Internal: finish the auth flow ──
    // Fires the callback, clears state, closes AuthPopup.
    function _finish(success: bool, password: string) {
        if (!root._callback) return  // already finished

        const cb = root._callback
        root._callback = null
        root._pendingPassword = ""
        root._pendingPrompt = ""
        root._pendingDescription = ""
        root.authenticating = false
        root.checking = false
        _pam_timeout.stop()

        // Fire the callback
        try {
            cb(success, password)
        } catch (e) {
            console.warn("AuthInfo: callback threw:", e)
        }
    }

}

