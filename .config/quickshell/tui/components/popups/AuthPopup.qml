pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {
    id: root

    property string prompt: PolkitInfo.prompt
    property string message: PolkitInfo.message
    property string description: PolkitInfo.description
    property string identity: PolkitInfo.selectedId

    w: 40
    h: Cell.hCount(layout.implicitHeight) + 2

    escapeToClose: true  // CellPopup binds Escape → PopupManager.sigClose → onSigClose()

    Connections {
        target: PolkitInfo
        function onRequest(prompt, message, description, identity) {
            PopupManager.open("auth", false);
        }
        function onFailedChanged() {
            if (PolkitInfo.failed) {
                root.setStatus("Authorization failed!", Colors.danger, Cell.fontB);
                console.log("Authorization failed!");
            }
        }
        function onSuccessfulChanged() {
            if (PolkitInfo.successful) {
                root.setStatus("Authorization successful!", Colors.success, Cell.fontB);
                console.log("Authorization successful!");
            }
        }
        function onCompletedChanged() {
            if (PolkitInfo.completed)
                console.log("Authorization completed!");
        }
    }

    function onSigClose() {
        pwd_field.set("");
        succeed_anim.stop();
        status_reset.stop();
        PolkitInfo.cancel();
        forceClose();
    }

    onMarginsPressed: {
        AuthInfo.cancel();
    }

    function setStatus(text, color, font, reset = true) {
        status.text = text;
        status.color = color;
        status.font = font || Cell.font;
        if (reset)
            status_reset.restart();
    }

    // ── Animations ──
    SequentialAnimation {
        id: succeed_anim
        PauseAnimation {
            duration: 500
        }
        ScriptAction {
            script: {
                root.close();
            }
        }
    }

    SequentialAnimation {
        id: status_reset
        PauseAnimation {
            duration: 2000
        }
        ScriptAction {
            script: {
                if (root.visible && !AuthInfo.checking) {
                    root.setStatus("Insert password for <b>" + SystemInfo.username + "</b>", Colors.info, Cell.font, false);
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

                CellText {
                    id: message

                    visible: text.length > 0

                    Layout.leftMargin: Cell.w(1)

                    text: root.message
                    color: Colors.fgDim
                    preferedW: box.contentW - 2
                    centered: true
                    wrap: true
                }

                CellText {
                    id: context

                    visible: text.length > 0

                    Layout.leftMargin: Cell.w(1)

                    text: root.description
                    color: PolkitInfo.error ? Colors.danger : Colors.fgSubtle
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

                            forceFocus: true

                            disabled: AuthInfo.checking || succeed_anim.running

                            hidden: true

                            placeholder: "Password"

                            onEntered: input => {
                                console.log(input);
                                PolkitInfo.submit(input);
                            }
                        }
                    }
                }

                // ── Status text ──
                CellText {
                    id: status

                    Layout.leftMargin: Cell.w(1)

                    text: "Insert password for <b>" + PolkitInfo.selectedId + "</b>"
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
                        fg: clickable ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

                        onReleased: button => {
                            if (button == "L") {
                                if (AuthInfo.checking)
                                    return;
                                pwd_field.enter();  // triggers onEntered → _submit
                            }
                        }
                    }

                    CellButton {

                        text: "Cancel"

                        // Always clickable — user can cancel even mid-verify
                        clickable: true

                        color: [Colors.bgOverlay, Colors.fgBase]
                        fg: [Colors.fgBase, Colors.bgSurface]

                        onReleased: button => {
                            if (button == "L") {
                                root.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
