pragma ComponentBehavior: Bound

import qs.config
import qs.services
import qs.modules

import QtQuick
import QtQuick.Layouts

CellPopup {

    id: root

    w: Cell.wCount(layout.implicitWidth)
    h: Cell.hCount(layout.implicitHeight)

    onVisibleChanged: {
        ClipboardInfo.reload()
        clipboard.selected = 0
        list.reset()
    }

    ShortcutHandler {
        shortcuts: [
            {
                binds: ["Tab", "Down"],
                action: () => {
                    root.advance(1)
                }
            },
            {
                binds: ["Shift+Tab", "Up"],
                action: () => {
                    root.advance(-1)
                }
            },
            {
                binds: "Return",
                action: () => {
                    root.decode()
                    root.close()
                    //SystemInfo.type(ClipboardInfo.preview)
                }
            },
        ]
    }

    signal decode()

    function advance(delta: int) {
        clipboard.selected = Math.max(Math.min(clipboard.selected+delta,Math.min(199,ClipboardInfo.clipboard.length-1)),0)

        if (clipboard.selected - list.offset >= 6) {
            list.offset += 6
        }
        if (clipboard.selected - list.offset < 0) {
            list.offset -= 6
        }
    }

    ColumnLayout {

        id: layout

        spacing: Cell.h(2)

        Item {

            id: clipboard

            property int selected: 0

        }

        function dedent(text) {
            const lines = text.split('\n');

            // 1. Find the indentation length of all lines that aren't blank
            const indents = lines
            .filter(line => line.trim() !== '')
            .map(line => line.match(/^\s*/)[0].length);

            // Security check: if the string is empty or has no lines, return it as-is
            if (indents.length === 0) return text;

            // 2. Find the smallest common indentation block
            const minIndent = Math.min(...indents);

            // 3. Slice exactly that many spaces off the front of every single line
            return lines
            .map(line => line.slice(minIndent))
            .join('\n');
        }

        CellBox {

            id: preview

            w: 80
            h: 20

            header {
                text: " Preview "
                offset: Math.round((preview.contentW-header.text.length)/2)
            }

            CellScrollView {

                id: preview_list

                visible: !image_preview.visible

                w: parent.contentW
                h: parent.contentH

                source: CellText {
                    text: layout.dedent(ClipboardInfo.preview)
                    preferedW: preview_list.contentW
                    debug: true
                }

            }

            Item {

                id: image_wrapper

                anchors.fill: parent

                clip: true

                Image {

                    id: image_preview

                    anchors.centerIn: parent

                    anchors.verticalCenterOffset: vertOff
                    anchors.horizontalCenterOffset: horiOff

                    visible: ClipboardInfo.preview.startsWith("{image_header_23042005}")

                    onStatusChanged: {
                        scalar = Qt.binding(()=>minScale)
                        vertOff = 0
                        horiOff = 0
                    }

                    Component.onCompleted: {
                        ClipboardInfo.image.connect(()=>{
                            source = ClipboardInfo.path
                        })
                        clipboard.selectedChanged.connect(()=>{
                            source = ""
                        })
                    }

                    scale: scalar

                    property real scalar: minScale
                    property int vertOff: 0
                    property int horiOff: 0

                    property real minScale: Math.min(preview.width/sourceSize.width,preview.height/sourceSize.height)

                    source: ClipboardInfo.path

                    cache: false

                    width: sourceSize.width
                    height: sourceSize.height

                }

                MouseControl {
                    anchors.fill: parent

                    property real oldVert: 0
                    property real oldHori: 0
                    property int baseX: 0
                    property int baseY: 0

                    property int deltaX: mouseX - baseX
                    property int deltaY: mouseY - baseY

                    onWheel: (delta) => {
                        image_preview.scalar = Math.max(image_preview.scalar + delta*0.1,image_preview.minScale)
                    }

                    onPressed: (button) => {
                        if (button === "L") {
                            baseX = mouseX;
                            baseY = mouseY;
                            oldVert = image_preview.vertOff;
                            oldHori = image_preview.horiOff;
                        }
                    }

                    onMoved: (x, y) => {
                        if (buttonDown === "L") {
                            image_preview.vertOff = oldVert + deltaY
                            image_preview.horiOff = oldHori + deltaX
                        }
                    }
                }

            }
        }

        CellBox {

            w: 80
            h: 8

            CellScrollView {

                id: list

                w: parent.contentW
                h: parent.contentH

                source: ColumnLayout {

                    spacing: 0

                    Repeater {

                        model: ClipboardInfo.clipboard.slice(0,Math.min(200,ClipboardInfo.clipboard.length))

                        delegate: Loader {

                            id: clip_loader

                            required property var modelData
                            required property int index

                            sourceComponent: Cells {

                                id: clip

                                property int index: clip_loader.index
                                property var modelData: clip_loader.modelData

                                property bool selected: index == clipboard.selected

                                Component.onCompleted: {
                                    root.decode.connect(()=> {
                                        if (!clip) return
                                        if (selected) {
                                            ClipboardInfo.decode(clip.index)
                                        }
                                    })
                                }

                                onSelectedChanged: {
                                    if (selected) {
                                        ClipboardInfo.load(modelData, index)
                                    }
                                }

                                w: list.contentW
                                h: 1

                                color: selected ? Colors.accentStrong : "transparent"

                                CellText {
                                    text: (clip.index + 1).toString().padStart(3, " ") + ". " + clip.modelData.label
                                    color: parent.selected ? Colors.onAccent : Colors.fgBase
                                    preferedW: list.contentW - 1
                                }

                                MouseControl {
                                    anchors.fill: parent
                                    onPressed: {
                                        if (clip.selected) {
                                            ClipboardInfo.decode(clip.index)
                                            root.close()
                                            return
                                        }
                                        clipboard.selected = clip.index
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
