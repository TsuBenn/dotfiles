pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

// ─────────────────────────────────────────────────────────────────
// AuthPopup — modal password dialog, driven by AuthInfo.
//
// AuthPopup is a passive UI component. It doesn't expose a public API
// for callers — instead, it listens to signals from AuthInfo:
//
//   AuthInfo.prompted(prompt, description) → opens + shows prompt/desc
//   AuthInfo.verifySucceeded()             → shows "success" briefly, closes
//   AuthInfo.verifyFailed(reason)          → shows error, lets user retry
//   AuthInfo.closed()                      → closes itself
//
// When the user submits a password, AuthPopup calls AuthInfo._check(password).
// When the user cancels (Escape / Cancel button / click outside),
// AuthPopup calls AuthInfo.cancel().
//
// Callers never touch AuthPopup directly. They call:
//   AuthInfo.verify(prompt, description, callback)
// and AuthInfo handles the rest.
// ─────────────────────────────────────────────────────────────────

CellPopup {

    id: root

    // ── State driven by AuthInfo signals ──
    property string prompt: "Authenticate"
    property string description: ""

    // No public API — driven entirely by AuthInfo signals.
    // The popup opens when AuthInfo.prompted fires, closes when
    // AuthInfo.closed fires.

    w: 40
    h: Cell.hCount(layout.implicitHeight) + 2

    escapeToClose: true  // CellPopup binds Escape → PopupManager.sigClose → onSigClose()

    // ── Cancel paths ──
    // Three ways the user can cancel from inside the popup:
    //   1. Press Escape (CellPopup's built-in escapeToClose → sigClose → onSigClose)
    //   2. Click the Cancel button
    //   3. Click outside the popup (marginsPressed from CellPopup)
    // All three call AuthInfo.cancel(), which fires the pending
    // callback with (false, "") and emits closed() to close this popup.

    // Override CellPopup's onSigClose function. Called when Escape is
    // pressed (via PopupManager.sigClose). We cancel the auth flow
    // instead of just closing — AuthInfo.cancel() will emit closed()
    // which triggers our onClosed handler to do the actual close.
    function onSigClose() {
        pwd_field.set("")
        succeed_anim.stop()
        status_reset.stop()
        AuthInfo.cancel()
    }

    onMarginsPressed: {
        AuthInfo.cancel()
    }

    // ── Listen to AuthInfo signals ──
    Connections {
        target: AuthInfo

        function onPrompted(p: string, d: string) {
            root.prompt = p
            root.description = d
            pwd_field.set("")
            root._setStatus("Insert password for <b>" + SystemInfo.username + "</b>",
            Colors.info, Cell.font)
            PopupManager.open(root.name, false)
            // Focus after the popup is visible
            Qt.callLater(() => { pwd_field.forceActiveFocus() })
        }

        function onVerifySucceeded() {
            root._setStatus("Authentication succeed!", Colors.success, Cell.fontB)
            succeed_anim.restart()
        }

        function onVerifyFailed(reason: string) {
            root._setStatus(reason || "Authentication failed!", Colors.danger, Cell.fontB)
            pwd_field.set("")
            Qt.callLater(() => { pwd_field.forceActiveFocus() })
        }

        function onClosed() {
            root.close()
        }

    }

    function _setStatus(text, color, font) {
        status.text = text
        status.color = color
        status.font = font || Cell.font
        status_reset.restart()
    }

    // ── Submit handler ──
    function _submit(password) {
        if (password.length === 0) {
            _setStatus("Password field cannot be left empty!", Colors.warning)
            return
        }
        if (AuthInfo.checking) {
            // PAM check already in flight — wait for it
            return
        }

        _setStatus("Processing password...", Colors.info, Cell.font)
        AuthInfo._check(password)
    }

    // ── Animations ──
    SequentialAnimation {
        id: succeed_anim
        PauseAnimation { duration: 500 }
        ScriptAction {
            script: {
                root.close()
            }
        }
    }

    SequentialAnimation {
        id: status_reset
        PauseAnimation { duration: 2000 }
        ScriptAction {
            script: {
                if (root.visible && !AuthInfo.checking) {
                    root._setStatus("Insert password for <b>" + SystemInfo.username + "</b>",
                    Colors.info, Cell.font)
                }
            }
        }
    }

    Cells {

        w: root.w
        h: root.h

        CellBox {

            id: box

            w: root.w
            h: root.h

            ColumnLayout {

                id: layout

                spacing: 0

                // ── Title ──
                CellText {

                    id: title

                    Layout.leftMargin: Cell.w(1)

                    text: root.prompt
                    preferedW: box.contentW - 2
                    centered: true
                    color: Colors.secondary

                }

                CellSeparator {
                    w: root.w - 2
                    color: Colors.accentStrong
                }

                // ── Description (optional) ──
                CellText {

                    id: context

                    visible: text.length > 0

                    Layout.leftMargin: Cell.w(1)

                    text: root.description
                    color: Colors.fgDim
                    preferedW: box.contentW - 2
                    centered: true
                    wrap: true

                }

                // ── Password field ──
                Cells {

                    w: box.contentW
                    h: 3
                    color: "transparent"

                    CellBox {

                        w: parent.w
                        h: parent.h

                        border.color: pwd_field.text.length > 0 ? Colors.secondary : Colors.accentStrong

                        CellTextField {

                            id: pwd_field

                            x: Cell.w(1)

                            w: box.contentW - 4
                            h: 1

                            // Disable only while PAM is actively checking a
                            // password. NOT disabled during the rest of the auth
                            // session (user can retype to retry on failure).
                            disabled: AuthInfo.checking || succeed_anim.running

                            hidden: true

                            placeholder: "Password"

                            onEntered: (input) => {
                                root._submit(input)
                            }

                        }

                    }

                }

                // ── Status text ──
                CellText {

                    Layout.leftMargin: Cell.w(1)

                    id: status

                    text: "Insert password for <b>" + SystemInfo.username + "</b>"
                    color: Colors.info
                    preferedW: box.contentW - 2
                    wrap: true
                    centered: true

                }

                CellSeparator {
                    w: box.contentW
                    color: Colors.bgOverlay
                }

                // ── Buttons ──
                RowLayout {

                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                    spacing: Cell.w(2)

                    CellButton {

                        text: "Verify"

                        clickable: pwd_field.text.length > 0 && !AuthInfo.checking && !succeed_anim.running

                        color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                        fg:    clickable ? [Colors.onAccent, Colors.fgBase]        : Colors.fgSubtle

                        onReleased: (button) => {
                            if (button == "L") {
                                if (AuthInfo.checking) return
                                pwd_field.enter()  // triggers onEntered → _submit
                            }
                        }

                    }

                    CellButton {

                        text: "Cancel"

                        // Always clickable — user can cancel even mid-verify
                        clickable: true

                        color: [Colors.bgOverlay, Colors.fgBase]
                        fg:    [Colors.fgBase, Colors.bgSurface]

                        onReleased: (button) => {
                            if (button == "L") {
                                root.close()
                            }
                        }

                    }

                }

            }

        }

    }

}

