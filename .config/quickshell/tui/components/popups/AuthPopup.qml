pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {
    id: root

    w: 40
    h: Cell.hCount(layout.implicitHeight) + 2

    escapeToClose: true // CellPopup binds Escape → PopupManager.sigClose → onSigClose()

    property bool succeed: false

    Connections {
        target: PolkitInfo
        function onRequest() {
            root.open(false);
        }
        function onSucceed() {
            root.succeed = true;
            root.close();
        }
        function onFailed() {
            root.setStatus("Authentication failed!", Colors.danger, Cell.font);
        }
    }

    function onSigClose() {
        pwd_field.set("");
        succeed_anim.stop();
        status_reset.stop();
        forceClose();
        if (!succeed)
            cancel();
        succeed = false;
    }

    function cancel() {
        PolkitInfo.cancel();
    }

    onMarginsPressed: {
        root.close();
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
                if (root.visible && !PolkitInfo.checking) {
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

                    text: "Polkit authentication" + (PolkitInfo.flows.length > 1 ? " (" + PolkitInfo.flows.length + " left)" : "")
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

                    text: PolkitInfo.message
                    color: Colors.fgDim
                    preferedW: box.contentW - 2
                    centered: true
                    wrap: true
                }

                CellText {
                    id: context

                    visible: text.length > 0

                    Layout.leftMargin: Cell.w(1)

                    text: PolkitInfo.extra
                    color: PolkitInfo.error ? Colors.danger : Colors.fgSubtle
                    preferedW: box.contentW - 2
                    centered: true
                    wrap: true
                }

                CellSeparator {
                    w: box.contentW
                    color: Colors.bgOverlay
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

                        header.text: PolkitInfo.cleanPrompt != "" ? " " + PolkitInfo.cleanPrompt + " " : ""
                        header.offset: Math.round((contentW - header.text.length) / 2)

                        CellTextField {
                            id: pwd_field

                            x: Cell.w(1)

                            w: box.contentW - 4
                            h: 1

                            forceFocus: true

                            disabled: PolkitInfo.checking || succeed_anim.running

                            hidden: true

                            placeholder: PolkitInfo.cleanPrompt

                            onEntered: input => {
                                PolkitInfo.submit(input);
                            }
                        }
                    }
                }

                // ── Status text ──
                CellText {
                    id: status

                    Layout.leftMargin: Cell.w(1)

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

                RowLayout {

                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                    spacing: Cell.w(2)

                    CellButton {

                        text: "Verify"

                        clickable: pwd_field.text.length > 0 && !PolkitInfo.checking && !succeed_anim.running

                        color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                        fg: clickable ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

                        onReleased: button => {
                            if (button == "L") {
                                if (PolkitInfo.checking)
                                    return;
                                pwd_field.enter();
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
