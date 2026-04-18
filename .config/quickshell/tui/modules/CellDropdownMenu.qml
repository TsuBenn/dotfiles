pragma ComponentBehavior: Bound

import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    visible: DropdownManager.visible

    w: DropdownManager.w
    h: DropdownManager.h > 0 ? DropdownManager.h : menu.h

    property bool scrollbar: DropdownManager.h > 0

    cellX: DropdownManager.x
    cellY: DropdownManager.y

    safeMargin: 0

    property var items: DropdownManager.items
    property int selected: DropdownManager.selected
    property int padding: DropdownManager.padding
    property color color: DropdownManager.color
    property color fg: DropdownManager.fg
    property color active: DropdownManager.active
    property color active_invert: DropdownManager.active_invert

    Cells {

        id: menu

        w: root.w
        h: root.scrollbar ? root.h : Cell.hCount(layout.implicitHeight)

        CellScrollView {

            id: list

            w: root.w
            h: root.scrollbar ? root.h : Cell.hCount(layout.implicitHeight)

            scrollbar.enabled: root.scrollbar

            color: root.color

            ColumnLayout {

                id: layout

                spacing: 0

                Repeater {

                    model: root.items

                    delegate: Cells {

                        id: button

                        required property int index
                        required property var modelData

                        property bool active: root.selected == index

                        w: list.contentW
                        h: 1

                        color: active ? root.active : root.color

                        CellText {
                            text: " ".repeat(root.padding) + button.modelData.label
                            preferedW: root.w - root.padding
                            color: button.active ? root.active_invert : root.fg
                            font: button.active ? Cell.fontB : Cell.font
                        }

                        MouseControl {
                            anchors.fill: parent

                            onPressed: (button) => {
                                if (button == "L") {
                                    DropdownManager.hide()
                                    if (root.selected != parent.index) {
                                        parent.modelData.action()
                                    }
                                }
                            }
                        }

                    }

                }

            }

        }

    }

}
