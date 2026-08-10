pragma ComponentBehavior: Bound

import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

CellPopup {
    id: root

    visible: DropdownManager.visible && (Window.window.isFloat ?? false) == DropdownManager.isFloat

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
    property var callback: DropdownManager.callback

    Cells {
        id: menu

        w: root.w
        h: root.scrollbar ? root.h : root.items.length

        CellScrollList {
            id: list

            w: root.w
            h: root.scrollbar ? root.h : root.items.length

            scrollbar.enabled: root.scrollbar

            scrollbar.bg_color: Colors.fgSubtle

            itemH: 1

            color: root.color

            model: root.items

            delegate: Cells {
                id: button

                property int index
                property var modelData

                property bool active: root.selected == index

                w: list.contentW
                h: 1

                color: active ? root.active : (!mouse.hovered ? root.color : Qt.lighter(root.color, 1.5))

                CellText {
                    id: button_text
                    text: " ".repeat(root.padding) + button.modelData.label
                    preferedW: root.w - root.padding
                    color: button.active ? root.active_invert : root.fg
                    font: button.active ? Cell.fontB : Cell.font
                }

                MouseControl {
                    id: mouse
                    anchors.fill: parent

                    onReleased: btn => {
                        if (btn == "L" && hovered) {
                            let selection = button.index;
                            DropdownManager.hide();
                            if (root.selected != parent.index) {
                                // console.log(selection);
                                root.callback(selection);
                            }
                        }
                    }
                }
            }
        }
    }
}
