pragma ComponentBehavior: Bound

import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    property var monitor

    visible: ContextMenuManager.visible

    w: ContextMenuManager.w
    h: box.h

    cellX: ContextMenuManager.x
    cellY: ContextMenuManager.y - 1

    CellBox {

        id: box

        w: root.w
        h: Cell.hCount(layout.implicitHeight) + 2

        header {
            text: ` ${ContextMenuManager.header} `
        }

        ColumnLayout {

            id: layout

            spacing: 0

            Repeater {

                model: ContextMenuManager.items


                delegate: Item {

                    implicitWidth: Cell.w(root.w)
                    implicitHeight: Cell.h(1)

                    required property var modelData

                    CellSeparator {

                        visible: parent.modelData.label == "---"

                        padding: 1

                    }

                    CellButton {

                        visible: parent.modelData.label != "---"

                        text: parent.modelData.label

                        w: root.w
                        centered: false

                        color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                        fg: [Colors.fgBase, Colors.bgSurface]

                        onReleased: (button) => {
                            if (button == "L") {
                                parent.modelData.action()
                                ContextMenuManager.hide()
                            }
                        }

                    }

                }

            }

        }

    }

}
