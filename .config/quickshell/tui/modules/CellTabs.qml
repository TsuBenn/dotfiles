pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Item {
    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    property bool centered: true
    property bool distributed: true

    property int padding: 1

    property int spacing: 2

    property int offset: 0

    property int type: 0

    property var items: []

    // [2, 0] Disables item 0 and 2
    property var disabled: []

    property int selected: 0

    onDisabledChanged: {
        if (disabled.length == items.length) {
            console.warn("CellTabs: Cannot disable all tabs, at least 1 tab must be available!");
            disabled = [];
            return;
        }
        while (disabled.includes(selected)) {
            selected -= 1;
            if (selected == 0) {
                selected = items.length - 1;
            }
        }
    }

    property bool connect: false

    component Color: Item {
        property color bg: Colors.bgSurface
        property color fg: Colors.bgOverlay

        property color base: Colors.fgBase

        property color disabled: Colors.bgOverlay
        property color inactive: Colors.fgSubtle
        property color active: Colors.accentStrong
        property color onActive: Colors.onAccent
    }

    property Color color: Color {}

    property int w: 20

    implicitWidth: Cell.w(w)
    implicitHeight: {
        if (type == 1) {
            return Cell.h(3);
        }
        return Cell.h(2);
    }

    function advance(step: int) {
        selected = (selected + items.length + step) % items.length;
    }

    function itemLength(): int {
        let count = 0;
        for (const item of items) {
            count += item.length;
            count += 2;
        }
        count = Cell.w(Math.round((w - count) / (items.length + 1)));
        return count;
    }

    Cells {

        anchors.fill: parent

        color: root.color.bg
    }

    CellSeparator {

        w: root.w
        y: Cell.h(1)
        padding: root.padding
        // type: 1
        color: root.color.fg
        bg: root.color.bg
        connectStart: root.connect
        connectEnd: root.connect
    }

    Loader {

        active: root.type == 0 && (root.visible || !root.optimizeMemory)

        sourceComponent: RowLayout {

            visible: root.type == 0

            x: root.centered ? Cell.centerWCell(implicitWidth, Cell.w(root.w)) : Cell.w(1) * root.offset

            spacing: root.distributed && root.centered ? root.itemLength() : Cell.w(root.spacing)

            Repeater {

                model: root.items

                delegate: Cells {
                    id: tab

                    required property int index
                    required property string modelData

                    property string label: modelData
                    property bool active: root.selected == index
                    property bool disabled: root.disabled.includes(index)

                    w: label_text.w + 2
                    h: 2

                    color: "transparent"

                    ColumnLayout {

                        spacing: 0

                        CellText {
                            id: label_text
                            Layout.leftMargin: Cell.w(1)
                            text: tab.label
                            font: tab.active ? Cell.fontB : Cell.font
                            color: tab.disabled ? Colors.bgOverlay : (tab.active ? root.color.base : root.color.inactive)
                        }

                        Cells {

                            w: tab.active ? label_text.w + 2 : 0
                            h: 1

                            color: tab.active ? root.color.bg : "transparent"

                            clip: true

                            CellSeparator {
                                padding: 1
                                w: label_text.w + 2
                                color: root.color.active
                                bg: "transparent"
                            }
                        }
                    }

                    MouseControl {

                        visible: !tab.disabled

                        anchors.fill: parent

                        onPressed: button => {
                            if (button == "L") {
                                root.selected = tab.index;
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {

        active: root.type == 1 && (root.visible || !root.optimizeMemory)

        sourceComponent: CellBox {
            id: box

            visible: root.type == 1

            w: root.w
            h: 3

            color: root.color.bg
            border.color: root.color.fg

            RowLayout {

                x: root.centered ? Cell.centerWCell(implicitWidth, Cell.w(box.contentW)) : 0

                spacing: root.distributed && root.centered ? root.itemLength() : Cell.w(root.spacing)

                Repeater {

                    model: root.items

                    delegate: CellButton {

                        required property int index
                        required property string modelData

                        property string label: modelData
                        property bool active: root.selected == index

                        padding: 1

                        text: label
                        font: active ? Cell.fontB : Cell.font
                        color: active ? root.color.active : "transparent"
                        fg: active ? root.color.onActive : root.color.inactive

                        onPressed: button => {
                            if (button == "L") {
                                root.selected = index;
                            }
                        }
                    }
                }
            }
        }
    }
}
