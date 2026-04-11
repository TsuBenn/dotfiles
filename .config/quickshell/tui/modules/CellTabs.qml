pragma ComponentBehavior: Bound

import qs.config
import qs.modules

import QtQuick.Layouts
import QtQuick

Item {

    id: root

    property bool centered: true
    property bool distributed: true

    property int padding: 1

    property int spacing: 2

    property int type: 0

    property var items: []

    property int selected: 0

    component Color: Item {
        property color bg: Colors.bgSurface
        property color fg: Colors.bgOverlay

        property color base: Colors.fgBase

        property color inactive: Colors.fgSubtle
        property color active: Colors.accentStrong
    }

    property Color color: Color {}

    property int w: 20

    implicitWidth: Cell.w(w)
    implicitHeight: {
        if (type == 1) {
            return Cell.h(3)
        }
        return Cell.h(2)
    }

    function itemLength(): int {
        let count = 0
        for (const item of items) {
            count += item.length
            count += 2
        }
        count = Cell.w(Math.round((w - count)/(items.length+1)))
        console.log(count)
        return count
    }

    Cells {

        anchors.fill: parent

        color: root.color.bg

    }

    CellSeparator {

        w: root.w
        y: Cell.h(1)
        padding: root.padding
        type: 1
        color: root.color.fg

    }

    RowLayout {

        visible: root.type == 0

        x: Cell.centerWCell(implicitWidth, Cell.w(root.w))

        spacing: root.distributed && root.centered ? root.itemLength() : Cell.w(root.spacing)

        Repeater {

            model: root.items

            delegate: Cells {

                id: tab

                required property int index
                required property string modelData

                property string label: modelData
                property bool active: root.selected == index

                w: label.length + 2
                h: 2

                color: "transparent"

                ColumnLayout {

                    spacing: 0

                    CellText {
                        text: ` ${tab.label} `
                        font: tab.active ? Cell.fontB : Cell.font
                        color: tab.active ? root.color.base : root.color.inactive
                    }

                    CellText {
                        text: ` ${tab.active ? "━".repeat(tab.label.length) : " ".repeat(tab.label.length)} `
                        color: root.color.active
                        bg: tab.active ? root.color.bg : "transparent"
                    }

                }

                MouseControl {

                    anchors.fill: parent

                    onPressed: (button) => {
                        if (button == "L") {
                            root.selected = tab.index
                        }
                    }

                }

            }

        }

    }

    CellBox {

        id: box

        visible: root.type == 1

        w: root.w
        h: 3

        color: root.color.bg
        border.color: root.color.fg

        RowLayout {

            x: Cell.centerWCell(implicitWidth, Cell.w(box.contentW))

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
                    fg: active ? root.color.base : root.color.inactive

                    onPressed: (button) => {
                        if (button == "L") {
                            root.selected = index
                        }
                    }

                }

            }

        }

    }

}
