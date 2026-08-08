import qs.config
import qs.modules
import qs.services

import QtQuick
import Quickshell.Services.Pam
import QtQuick.Layouts

CellFloats {
    id: root

    w: 50
    h: Cell.hCount(layout.implicitHeight)

    name: "ws_auth"

    title: "Workspace Authenticator"

    property bool processing: false

    property bool unlock: false

    centered: true

    hideCursor: true

    noMax: true
    noMin: true

    // CellFloats {
    //     visible: root.visible
    //     name: root.name
    //     title: "Workspace Locker Background"
    //     color: Colors.transparent(Colors.bgSurface, 0.5)
    //     noMax: true
    //     noMin: true
    //     forceMoveClient: true
    // }

    forceMoveClient: true

    function setStatus(text, color, font, reset = true) {
        status.text = text;
        status.color = color;
        status.font = font || Cell.font;
        if (reset)
            status_reset.restart();
    }

    onVisibleChanged: {
        pwd_field.set("");
        succeed_anim.stop();
        status_reset.stop();
        root.setStatus("Insert password for <b>" + SystemInfo.username + "</b>", Colors.info, Cell.font, false);
        processing = false;
        unlock = false;
    }

    SequentialAnimation {
        id: status_reset
        PauseAnimation {
            duration: 2000
        }
        ScriptAction {
            script: {
                if (root.visible && !root.processing) {
                    root.setStatus("Insert password for <b>" + SystemInfo.username + "</b>", Colors.info, Cell.font, false);
                }
            }
        }
    }

    ColumnLayout {
        id: layout

        x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
        y: Cell.centerHCell(implicitHeight, parent.implicitHeight)

        spacing: 0

        // CellText {
        //     text: "WORKSPACE lOCKED"
        //     color: Colors.secondary
        //     font: Cell.fontB
        //     preferedW: root.w
        //     centered: true
        // }

        CellText {
            Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
            cellIsolated: true
            text: ANSI.render(`WORKSPACE ${HyprInfo.focusedWorkspace.id} LOCKED`, 2)
            color: Colors.secondary
        }

        CellSeparator {
            w: root.w
            bg: "transparent"
            connectStart: true
            connectEnd: true
            color: Colors.accentDim
        }

        CellText {
            Layout.leftMargin: Cell.w(1)
            text: "Enter password to <i>temporary</i> unlock"
            preferedW: root.w - 2
            font: Cell.fontB
            centered: true
        }

        CellText {
            Layout.leftMargin: Cell.w(1)
            text: "<i>Shift+Enter</i> to unlock for good"
            color: Colors.fgSubtle
            preferedW: root.w - 2
            font: Cell.fontB
            centered: true
        }

        Cells {
            w: root.w
            h: 3
            color: "transparent"
            CellBox {
                w: parent.w
                h: parent.h

                border.color: pwd_field.text.length > 0 ? Colors.secondary : Colors.accentStrong

                header.text: " Password "

                CellTextField {
                    id: pwd_field
                    x: Cell.w(1)
                    w: root.w - 4
                    h: 1
                    placeholder: "Password"
                    forceFocus: true
                    disabled: root.processing
                    hidden: true

                    onEntered: (input, mod) => {
                        root.processing = true;
                        if (mod.includes("s")) {
                            root.unlock = true;
                        }
                        pam.respond(input);
                    }
                }
            }
        }

        CellText {
            id: status

            Layout.leftMargin: Cell.w(1)

            text: "Insert password for <b>" + SystemInfo.username + "</b>"
            color: Colors.info
            preferedW: root.w - 2
            wrap: true
            centered: true
        }
    }

    SequentialAnimation {
        id: succeed_anim
        ScriptAction {
            script: {
                root.setStatus("Authentication Succeed!", Colors.success, Cell.fontB);
            }
        }
        PauseAnimation {
            duration: 200
        }
        ScriptAction {
            script: {
                root.close();
            }
        }
    }

    PamContext {
        id: pam

        active: true
        onCompleted: result => {
            root.processing = false;
            pam.active = true;
            if (result == PamResult.Success) {
                if (root.unlock) {
                    root.unlock = false;
                    WorkspaceInfo.unlock(HyprInfo.focusedWorkspace);
                } else {
                    WorkspaceInfo.tempUnlock(HyprInfo.focusedWorkspace);
                }
                succeed_anim.restart();
            } else if (result == PamResult.Failed) {
                root.setStatus("Authentication failed!", Colors.danger, Cell.fontB);
                pwd_field.set("");
            } else if (result == PamResult.MaxTries) {
                root.setStatus("No more tries, try again later!", Colors.danger, Cell.fontB);
                pwd_field.set("");
            } else {
                root.setStatus("Unexpected error, try again!", Colors.danger, Cell.fontB);
                pwd_field.set("");
            }
        }
    }
}
