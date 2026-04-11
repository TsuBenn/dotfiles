import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    w: 36 - (mode.length%2==1)
    h: 7

    property int count: 3

    property string mode: "Sleep"

    property bool active: false

    onModeChanged: {
        root.w = 36 - (mode.length%2==1)
    }

    onActiveChanged: {
        if (active) count = 3
    }

    CellBox {

        id: box

        w: root.w
        h: root.h

        ColumnLayout {
            
            spacing: 0

            x: Cell.centerWCell(implicitWidth, Cell.w(box.w))
            y: Cell.centerHCell(implicitHeight, Cell.h(box.h-1))

            RowLayout {

                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                spacing: 0
                CellText {
                    text: {
                        switch (root.mode) {
                            case "Shutdown": return "Shutting down" + " in " + root.count
                            case "Reboot": return "Rebooting" + " in " + root.count
                            case "Sleep": return "Sleeping" + " in " + root.count
                        }
                    }
                }
                CellLoading {
                    style: 2
                }
            }

            CellText {
                text: ""
            }

            RowLayout {

                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                spacing: Cell.w(4)
                
                CellButton {

                    text: root.mode + " now"
                    color: [Colors.accentStrong, Colors.bgOverlay]
                    fg: [Colors.onAccent, Colors.fgBase]

                    onReleased: (button) => {
                        if (button == "L") {
                            root.count = 0
                        }
                    }

                }

                CellButton {

                    text: "Cancel"
                    color: [Colors.accentStrong, Colors.bgOverlay]
                    fg: [Colors.onAccent, Colors.fgBase]

                    onReleased: (button) => {
                        if (button == "L") {
                            timer.stop()
                            root.active = false
                            PopupManager.close()
                        }
                    }

                }
            }

        }

    }

    Timer {
        id: timer

        interval: 1000
        running: root.active
        repeat: true
        onTriggered: {
            if (root.count > 0) {
                root.count--
            }
            if (root.count == 0 && root.active) {
                root.active = false
                PopupManager.close()
                switch (root.mode) {
                    case "Shutdown": SystemInfo.shutdown(); break;
                    case "Sleep": SystemInfo.sleep(); break;
                    case "Reboot": SystemInfo.reboot(); break;
                }
            }
        }

    }

}
