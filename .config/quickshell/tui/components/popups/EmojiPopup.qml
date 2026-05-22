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

    w: 41
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
                    if (emojis.selected - 8 < 0) return
                    else emojis.selected -= 8
                }
            },
            {
                binds: ["Left", "Shift+Tab"],
                action: () => {
                    if (emojis.selected - 1 < 0) return
                    else emojis.selected -= 1
                }
            },
            {
                binds: "Down",
                action: () => {
                    if (emojis.selected + 8 > (emojis.result.length > 0 ? emojis.result.length-1 : EmojisInfo.recent.length)) return
                    else emojis.selected += 8
                }
            },
            {
                binds: ["Right", "Tab"],
                action: () => {
                    if (emojis.selected + 1 > (emojis.result.length > 0 ? emojis.result.length-1 : EmojisInfo.recent.length-1)) return
                    else emojis.selected += 1
                }
            },
            {
                binds: "Return",
                action: () => {
                    root.select()
                }
            },
        ]
    }

    signal select()

    component EmojiGrid: GridLayout {

        rowSpacing: 0
        columnSpacing: 0

        columns: 8

        property var model: emojis.result

        Repeater {

            model: parent.model

            delegate: Loader {

                id: emoji

                required property var modelData
                required property int index

                property int offset: Math.floor(index/8)*3 + 1

                active: offset >= list.offset - 2 && offset <= list.offset + 10

                asynchronous: index > 16

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

            CellTextField {

                Layout.leftMargin: Cell.w(1)

                w: box.contentW-2

                id: textfield

                placeholder: "Search emojis"

                onTextInput: (input) => {
                    if (input.length > 0) emojis.result = EmojisInfo.search(input, 200) 
                    else emojis.result = []
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

                source: ColumnLayout {

                    spacing: 0

                    CellText {

                        Layout.leftMargin: Cell.w(1)
                        text: emojis.result.length > 0 ? "Results" : "Recents"
                        color: Colors.fgSubtle

                    }

                    EmojiGrid {
                        model: emojis.result.length > 0 ? emojis.result : EmojisInfo.recent
                    }

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
