pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick
import QtQuick.Layouts

CellPopup {

    property bool optimizeMemory: false

    property bool mouseLocked: true

    id: root

    w: 26
    h: 12

    onVisibleChanged: {
        mouseLocked: true
        emojis.result = []
    }

    ShortcutHandler {
        shortcuts: [
            {
                binds: "Up",
                action: () => {
                    root.advance(-5)
                    root.alignList()
                }
            },
            {
                binds: ["Left", "Shift+Tab"],
                action: () => {
                    root.advance(-1)
                    root.alignList()
                }
            },
            {
                binds: "Down",
                action: () => {
                    root.advance(5)
                    root.alignList()
                }
            },
            {
                binds: ["Right", "Tab"],
                action: () => {
                    root.advance(1)
                    root.alignList()
                }
            },
            {
                binds: "Return",
                action: () => {
                    root.select()
                    root.alignList()
                }
            },
        ]
    }

    function alignList() {
        if (Math.floor(emojis.selected/5) > Math.floor(list.offset/3) + 1) {
            list.offset = Math.floor(emojis.selected/5)*3
        }
        if (Math.floor(emojis.selected/5) < Math.floor(list.offset/3) + 1) {
            list.offset = Math.floor(emojis.selected/5)*3
        }
    }

    function advance(delta: int) {
        if (emojis.selected + delta > (emojis.result.length > 0 ? emojis.result.length-1 : EmojisInfo.recent.length-1)) { if (Math.abs(delta) == 1) emojis.selected = 0 }
        else if (emojis.selected + delta < 0) { if (Math.abs(delta) == 1) emojis.selected = (emojis.result.length > 0 ? emojis.result.length-1 : EmojisInfo.recent.length-1) }
        else emojis.selected += delta
    }

    signal select()

    component EmojiGrid: GridLayout {

        rowSpacing: 0
        columnSpacing: 0

        columns: 5

        property var model: emojis.result

        Repeater {

            model: parent.model

            delegate: Loader {

                id: emoji

                required property var modelData
                required property int index

                property int offset: Math.floor(index/5)*3 + 1

                active: offset >= list.offset - 2 && offset <= list.offset + 7

                asynchronous: index >= 10

                sourceComponent: Cells {

                    id: emoji_cell

                    property bool selected: emoji.index == emojis.selected

                    Component.onCompleted: {
                        root.select.connect(()=> {
                            if (emoji_cell?.selected) emojis.select(emoji.modelData)
                        })
                    }

                    w: 5
                    h: 3

                    color: "transparent"

                    CellBox {

                        w: parent.w
                        h: parent.h

                        border.color: parent.selected ? Colors.accentStrong : Colors.fgSubtle
                        border.type: parent.selected ? 3 : 4

                        CellText {

                            x: Cell.w(0.5)
                            text: emoji.modelData.label

                        }

                    }

                    MouseControl {

                        visible: !root.mouseLocked

                        anchors.fill: parent

                        onEntered: {
                            emojis.selected = emoji.index
                        }

                        onPressed: {
                            emojis.select(emoji.modelData)
                        }
                    }

                }

            } 

        }

    }

    CellBox {

        id: box

        w: root.w+2
        h: root.h+2

        ColumnLayout {

            id: layout

            spacing: 0

            Cells {

                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                w: 6
                h: 3

                color: "transparent"

                Text {

                    anchors.centerIn: parent

                    id: emoji_preview

                    text: ""

                    font {
                        family: "Apple Color Emoji"
                        pointSize: 50
                    }

                }
            }

            CellSeparator {
                w: box.contentW
                color: Colors.accentStrong
            }

            CellTextField {

                Layout.leftMargin: Cell.w(1)

                w: box.contentW-2

                id: textfield

                placeholder: "Search emojis"

                onTextInput: (input) => {
                    if (input.length > 0) emojis.result = EmojisInfo.search(input, 200) 
                    else {
                        emoji_preview.text = EmojisInfo.recent[emojis.selected]?.label ?? ""
                        emojis.result = []
                    }
                }

            }

            CellSeparator {
                w: box.contentW
                color: Colors.accentStrong
            }

            Item {

                id: emojis

                property var result: []

                onResultChanged: {
                    emoji_preview.text = result[selected]?.label ?? ""
                    root.mouseLocked = true
                    selected = 0
                }

                property int selected: 0

                function select(emoji: var) {
                    PopupManager.close("emoji")
                    EmojisInfo.select(emoji)
                }

            }

            CellScrollView {

                id: list

                w: box.contentW
                h: root.h-2

                onVisibleChanged: {
                    reset()
                }

                source: EmojiGrid {
                    model: emojis.result.length > 0 ? emojis.result : EmojisInfo.recent
                }

            }

        }


    }

    MouseControl {

        visible: root.mouseLocked

        anchors.fill: parent

        property var pos: [mouseX, mouseY]

        onMoved: (x, y) => {
            if (pos[0] != x || pos[1] != y) {
                root.mouseLocked = false
            }
            pos = [x, y]
        }

    }

}
