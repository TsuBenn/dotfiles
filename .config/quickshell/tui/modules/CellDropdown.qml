pragma ComponentBehavior: Bound

import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

Item {
    id: root

    property int w
    property int h: 0

    property int padding: 1

    property string text: "Dropdown"

    property bool reversed: false
    property bool scroll: false

    component Type: Item {
        property int padding: root.padding
        property color color: Colors.bgOverlay
        property color fg: Colors.fgBase
        property color active: Colors.accentStrong
        property color active_invert: Colors.onAccent
    }

    property Type button: Type {
        color: Colors.bgOverlay
        fg: Colors.fgBase
        active: Colors.bgOverlay
        active_invert: Colors.fgBase
    }

    property Type menu: Type {}

    property bool active: false

    property int selected: 0

    signal activated(index: int, label: string)

    property var items: [
        {
            label: "Button 1",
            action: () => console.log("Button 1 of the dropdown has been pressed")
        },
        {
            label: "Button 2",
            action: () => console.log("Button 2 of the dropdown has been pressed")
        }
    ]

    function advance(delta: int) {
        items[(selected + items.length + delta) % items.length].action();
    }

    implicitWidth: Cell.w(w)
    implicitHeight: Cell.h(1)

    Component.onCompleted: {
        DropdownManager.closed.connect(() => {
            if (!root)
                return;
            if (root.active) {
                root.active = false;
            }
        });
    }

    Cells {

        w: parent.w
        h: 1

        color: root.active ? root.button.active : root.button.color

        RowLayout {

            spacing: 0

            CellText {
                text: " ".repeat(root.padding) + (root.text == "" ? root.items[root.selected]?.label : root.text)
                preferedW: root.w - root.padding - 2
                color: root.active ? root.button.active_invert : root.button.fg
                font: root.active ? Cell.fontB : Cell.font
            }

            CellText {
                text: (!root.active ? " ⏷" : " ⏶") + " ".repeat(root.padding)
                color: root.active ? root.button.active_invert : root.button.fg
            }
        }
    }

    MouseControl {
        anchors.fill: parent

        onWheel: delta => {
            root.advance(-delta);
        }

        onPressed: button => {
            if (button == "L") {
                root.active = true;

                let selectBridge = function (index) {
                    root.activated(index, root.items[index]?.label ?? "");
                };

                const global = mapToGlobal(x, y);
                DropdownManager.show(root.items, global.x, global.y - root.reversed * Cell.h(root.items.length + 1), root.w, root.h, root.selected, root.menu.padding, root.menu.color, root.menu.fg, root.menu.active, root.menu.active_invert, selectBridge);
            }
        }
    }
}
