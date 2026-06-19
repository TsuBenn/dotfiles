import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    property int id: 0
    property string prompt: ""
    property string description: ""
    property bool return_password: false

    w: 40
    h: Cell.hCount(layout.implicitHeight) + 2

    signal success(password: string)
    signal failed()
    signal canceled()

    Connections {
        target: AuthInfo
        function onPrompted(prompt: string, description: string, return_password: bool, id: int) {
            root.id = id
            root.prompt = prompt
            root.description = description
            PopupManager.open(root.name, false)
        }
        function onVerified(id) {
            if (root.id == id) {
                root.sendStatus("Authentication succeed!", Colors.success, Cell.fontB)
                root.success(root.return_password ? pwd_field.text : "")
                succeed.start()
            } else {
                root.sendStatus("Unmatched id signal received!", Colors.danger, Cell.fontB)
                pwd_field.set("")
                root.failed()
            }
        }
        function onFailed() {
            root.sendStatus("Authentication failed!", Colors.danger, Cell.fontB)
            root.failed()
        }
    }

    function sendStatus(text: string, color = Colors.info,font = Cell.font) {
        status.text = text
        status.color = color
        status.font = font
        status_reset.restart()
    }

    SequentialAnimation {
        id: succeed
        PauseAnimation {
            duration: 1000
        }
        ScriptAction {
            script: {
                root.close()
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
                status.text = Qt.binding(()=>(AuthInfo.authenticating ? "Processing password..." : "Insert password for <b>" + SystemInfo.username + "</b>"))
                status.color = Colors.info
                status.font = Cell.font
            }
        }
    }

    function onSigClose() {
        AuthInfo.cancel()
        root.canceled()
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

                    id: context

                    visible: text.length > 0

                    Layout.leftMargin: Cell.w(1)

                    text: root.description
                    color: Colors.fgDim
                    preferedW: box.contentW - 2
                    wrap: true

                }

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

                            disabled: AuthInfo.authenticating || succeed.running

                            hidden: true

                            placeholder: "Password"

                            onEntered: (input) => {
                                if (input.length == 0) {
                                    root.sendStatus("Password field cannot be left empty!", Colors.warning)
                                    return
                                }
                                AuthInfo.verify(input, root.id)
                            }

                        }

                    }

                }

                CellText {

                    id: status

                    Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                    text: (AuthInfo.authenticating ? "Processing password..." : "Insert password for <b>" + SystemInfo.username + "</b>")
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

                        clickable: pwd_field.text.length > 0 && !AuthInfo.authenticating

                        color: clickable ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                        fg:    clickable ? [Colors.onAccent, Colors.fgBase]        : Colors.fgSubtle

                        onReleased: (button) => {
                            if (button == "L") {
                                if (AuthInfo.authenticating) return
                                pwd_field.enter()
                            }
                        }

                    }

                    CellButton {

                        text: "Cancel"

                        clickable: !AuthInfo.authenticating

                        color: clickable ? [Colors.bgOverlay, Colors.fgBase] : Colors.bgOverlay
                        fg:    clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

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
