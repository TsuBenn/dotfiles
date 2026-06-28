pragma ComponentBehavior: Bound

import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    visible: ContextMenuManager.visible

    w: ContextMenuManager.w
    h: box.h

    cellX: ContextMenuManager.x
    cellY: ContextMenuManager.y

    safeMargin: 0

    property var items: ContextMenuManager.items
    property string header: ContextMenuManager.header

    CellBox {

        id: box

        w: root.w
        h: Cell.hCount(layout.implicitHeight) + 2

        header {
            text: root.header ? ` ${root.header} ` : ""
        }

        ColumnLayout {

            id: layout

            spacing: 0

            Repeater {

                model: root.items


                delegate: Item {

                    id: button

                    implicitWidth: Cell.w(root.w)
                    implicitHeight: Cell.h(1)

                    required property var modelData

                    property bool disabled: modelData.disabled ?? false

                    CellSeparator {

                        visible: parent.modelData.label.startsWith("---")

                        w: root.w - 2

                        padding: 1

                        CellText {

                            x: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                            text: button.modelData.label.replace("---","") != "" ? ` ${button.modelData.label.replace("---","")} ` : ""
                            color: Colors.fgSubtle
                            bg: Colors.bgSurface

                        }

                    }

                    CellButton {

                        visible: !parent.modelData.label.startsWith("---")

                        text: parent.modelData.label

                        w: root.w
                        centered: false

                        clickable: !button.disabled

                        color: ["transparent", Colors.bgOverlay, Colors.fgBase]
                        fg: clickable ? [Colors.fgBase, Colors.bgSurface] : Colors.fgSubtle

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
