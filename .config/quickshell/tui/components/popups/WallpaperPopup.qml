pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    w: 100
    h: Cell.hCount(layout.implicitHeight)

    CellBox {

        id: box

        w: root.w
        h: root.h+2

        ColumnLayout {

            id: layout

            spacing: 0

            Cells {

                id: preview

                visible: HyprInfo.windowCount(HyprInfo.focusedworkspace) > 0

                w: box.contentW
                h: Math.floor(root.w/16*9/2.2)

                color: "transparent"

                Image {

                    width: Cell.w(box.contentW)
                    height: Cell.h(preview.h)

                    source: (selection.items[2] ? SystemInfo.homedir + WallpaperInfo.path : "") + selection.items[2]

                    fillMode: Image.PreserveAspectCrop

                }

            }

            CellSeparator {

                w: box.contentW
                type: 2
                title.text: "Wallpapers"
                color: Colors.bgOverlay

            }

            Cells {

                id: thumbnails

                w: box.contentW
                h: preview.visible ? 8 : 6

                color: "transparent"

                RowLayout {

                    x: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                    id: selection

                    spacing: Cell.w(5)

                    onVisibleChanged: {
                        wallpapers = WallpaperInfo.all
                        selected = WallpaperInfo.getIndex(WallpaperInfo.current)
                    }

                    property int selected

                    property var wallpapers: WallpaperInfo.all

                    property var items: {
                        const length = wallpapers.length
                        const offset = selected + length
                        const available = wallpapers

                        return [available[(offset - 2)%length],available[(offset - 1)%length],available[(offset)%length],available[(offset+1)%length],available[(offset+2)%length]]
                    }

                    function advance(step: int) {
                        if (autoAdvance.auto) WallpaperInfo.add(items[2+step])
                        selected = (selected + selection.wallpapers.length + step)%selection.wallpapers.length
                    }

                    Repeater {

                        id: repeater

                        model: selection.items

                        function refresh() {
                            model = []
                            model = Qt.binding(()=>selection.items)
                        }

                        delegate: CellBox {

                            id: thumbnail

                            required property string modelData
                            required property int index

                            property string value: modelData.split(".")[0]
                            property bool selected: {
                                if (selection.wallpapers.length > 1) {
                                    return modelData == selection.wallpapers[selection.selected]
                                }
                                return index == 2
                            } 

                            opacity: selected ? 1 : 0.5

                            Layout.topMargin: Cell.h(1)

                            w: Math.round((h-1)/9*16*2.2)-1
                            h: thumbnails.h

                            footer.text: " " + value + " "
                            footer.offset: Math.floor(contentW/2-value.length/2) - 1
                            footer.color: WallpaperInfo.inSet(modelData) ? Colors.secondary : Colors.fgBase
                            footer.font: WallpaperInfo.inSet(modelData) ? Cell.fontB : Cell.font

                            border.color: WallpaperInfo.inSet(modelData) ? Colors.secondary : "transparent"

                            Cells {

                                w: thumbnail.w-2
                                h: thumbnail.h-2

                                color: "transparent"

                                Image {

                                    anchors.centerIn: parent

                                    width: Cell.w(thumbnail.w)
                                    height: Cell.h(thumbnail.h-1)

                                    source: (thumbnail.modelData ? SystemInfo.homedir + "/Wallpapers/" : "") + thumbnail.modelData

                                    fillMode: Image.PreserveAspectCrop

                                }

                            }

                            MouseControl {
                                anchors.fill: parent

                                onReleased: (button) => {
                                    if (button == "L") {
                                        if (thumbnail.selected) {
                                            const current = selection.wallpapers[selection.selected]
                                            if (WallpaperInfo.inSet(current)) {
                                                WallpaperInfo.remove(current)
                                            } else {
                                                WallpaperInfo.add(current)
                                            }
                                            repeater.refresh()
                                        } else {
                                            selection.advance(thumbnail.index - 2)
                                        }
                                    }
                                }
                            }

                        }

                    }

                }

                MouseControl {

                    anchors.fill: parent

                    hoverEnabled: false

                    onWheel: (delta) => {
                        selection.advance(delta)
                    }

                }

            }

            Cells {

                w: box.contentW
                h: 3

                color: "transparent"

                CellBox {

                    id: textbox

                    w: box.contentW
                    h: 3

                    border.type: 4
                    border.color: textfield.text.trim().length > 0 ? Colors.secondary : Colors.fgBase

                    CellTextField {

                        x: Cell.w(1)

                        id: textfield

                        w: textbox.contentW - 2

                        editable: false

                        placeholder: "Search wallpaper"

                        onTextInput: (query) => {
                            selection.wallpapers = WallpaperInfo.search(text)
                        }

                        Keys.onPressed: (event) => {
                            if (event.key == Qt.Key_Left) {
                                selection.advance(-1)
                            } else if (event.key == Qt.Key_Right || event.key == Qt.Key_Tab) {
                                selection.advance(1)
                            } else if (event.key == Qt.Key_Return) {
                                const current = selection.wallpapers[selection.selected]
                                if (WallpaperInfo.inSet(current)) {
                                    WallpaperInfo.remove(current)
                                } else {
                                    WallpaperInfo.add(current)
                                }
                                repeater.refresh()
                            }
                        }

                    }

                }

            }

            CellSeparator {

                w: box.contentW
                type: 2
                color: Colors.bgOverlay

            }

            RowLayout {

                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                spacing: 0

                CellButton {

                    property bool on: WallpaperInfo.slideshow

                    text: "Slideshow"

                    color: on ? Colors.accentStrong : Colors.bgOverlay
                    fg: on ? Colors.onAccent : Colors.fgBase

                    onPressed: (button) => {
                        WallpaperInfo.slideshowToggle()
                    }

                }

                CellText {
                    text: "  Slideshow Interval "
                    color: WallpaperInfo.slideshow ? Colors.fgBase : Colors.fgSubtle
                }

                Cells {

                    w: 10
                    h: 1

                    color: Colors.bgOverlay

                    CellTextField {

                        focusOnVisible: false

                        w: parent.w
                        h:1

                        bindText: WallpaperInfo.slideshowInterval
                        disabled: !WallpaperInfo.slideshow

                        autoApply: true

                        onEntered: (text) => {
                            WallpaperInfo.slideshowInterval = text
                            textfield.focus = true
                        }

                        Keys.onPressed: (event) => {
                            if (event.key == Qt.Key_Escape) {
                                PopupManager.preventClosing = true
                                focus = false
                            }
                        }

                    }
                }

                CellText {
                    text: "  "
                }

                CellButton {

                    property bool on: WallpaperInfo.slideshow

                    text: "Rescan"

                    color: [Colors.accentStrong, Colors.bgOverlay]
                    fg: [Colors.onAccent, Colors.fgBase]

                    onPressed: (button) => {
                        WallpaperInfo.rescan()
                    }

                }

                CellText {
                    text: "  "
                }

                CellButton {

                    id: autoAdvance

                    property bool auto: true && !WallpaperInfo.slideshow

                    text: "Auto advance"

                    clickable: auto

                    color: auto ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                    fg: auto ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

                    onPressed: (button) => {
                        auto = !auto
                    }

                }

            }

        }

    }

}
