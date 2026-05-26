pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

CellPopup {

    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    property bool minimal: SettingsInfo.minimal

    w: 100
    h: Cell.hCount(layout.implicitHeight)

    safeMargin: 2

    escapeToClose: false

    SequentialAnimation {
        id: hide
        NumberAnimation {
            target: root
            property: "opacity"
            duration: 0
            to: 1
        }
        PauseAnimation {
            duration: 200
        }
        NumberAnimation {
            target: root
            property: "opacity"
            duration: 300
            to: 0.0
            easing.type: Easing.OutCubic
        }
        PauseAnimation {
            duration: Math.max(WallpaperInfo.getTransition(WallpaperInfo.current).duration*1000 - 200,0)
        }
        NumberAnimation {
            target: root
            property: "opacity"
            duration: 300
            to: 1
            easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: {
        WallpaperInfo.currentChanged.connect(()=>{
            if (HyprInfo.windowCount(HyprInfo.focusedworkspace) == 0) hide.restart()
            root.edit = false
        })
    }

    onVisibleChanged: {
        edit = false
    }

    onEditChanged: {
        if (edit) {
            pivotAnim.restart()
        }
    }

    property bool edit: false

    MouseControl {
        anchors.fill: parent

        onPressed: {
            if (!textfield.focus) {
                textfield.focus = true
            }
        }

    }

    CellBox {

        id: box

        w: root.w
        h: root.h+2


        ColumnLayout {

            id: layout

            spacing: 0

            Cells {

                id: preview

                visible: root.edit || (HyprInfo.windowCount(HyprInfo.focusedworkspace) > 0 && !root.minimal)

                w: box.contentW
                h: Math.floor(root.w/16*9/2)

                color: "transparent"

                Loader {

                    active: root.visible || !root.optimizeMemory

                    sourceComponent: Item {

                        implicitWidth: preview.implicitWidth
                        implicitHeight: preview.implicitHeight

                        clip: true

                        Image {

                            anchors.centerIn: parent

                            id: wallpaper

                            anchors.verticalCenterOffset: ((height - parent.height)/2)*WallpaperInfo.getReposition(selection.items[2]).verticalOffset
                            anchors.horizontalCenterOffset: ((width - parent.width)/2)*WallpaperInfo.getReposition(selection.items[2]).horizontalOffset

                            width:  sourceSize.width  * scalar * WallpaperInfo.getReposition(selection.items[2]).scalar
                            height: sourceSize.height * scalar * WallpaperInfo.getReposition(selection.items[2]).scalar

                            property double scalar: Math.max(parent.width/sourceSize.width, parent.height/sourceSize.height)

                            source: (selection.items[2] ? SystemInfo.homedir + WallpaperInfo.cache_path + selection.items[2] + WallpaperInfo.cache_prefix : "")

                        }

                        Rectangle {

                            implicitWidth: parent.width
                            implicitHeight: (Cell.h(1)/root.monitor.height)*parent.height

                            color: Colors.bgSurface

                            opacity: 0.3

                        }

                    }

                }

                Cells {
                    id: pivot_bg
                    visible: root.edit
                    w: parent.w
                    h: parent.h
                    opacity: 0
                    color: "black"
                }

                CellText {
                    id: crosshair
                    visible: root.edit
                    x: Cell.w(Math.round((preview.w-1)*WallpaperInfo.transition.posX))
                    y: Cell.h(Math.round((preview.h-1)*WallpaperInfo.transition.posY))
                    text: "✕"
                    font: Cell.fontBB

                }

                CellText {
                    id: pivot
                    opacity: 0
                    x: Math.max(Math.min(crosshair.x + Cell.w(-Math.round(w/2)+1),Cell.w(preview.w-w)),0)
                    y: crosshair.y + (Cell.hCount(crosshair.y,"ceil") >= preview.h ? Cell.h(-1) : Cell.h(1))
                    text: WallpaperInfo.transition.posX.toFixed(2) + "✕" + WallpaperInfo.transition.posX.toFixed(2)
                    bg: Colors.bgSurface
                }

                SequentialAnimation {
                    id: pivotAnim
                    ParallelAnimation {
                        NumberAnimation {
                            target: pivot
                            property: "opacity"
                            duration: 100
                            to: 1
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: pivot_bg
                            property: "opacity"
                            duration: 100
                            to: 0.5
                            easing.type: Easing.OutCubic
                        }
                    }
                    PauseAnimation {
                        duration: 400
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: pivot
                            property: "opacity"
                            duration: 500
                            to: 0
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: pivot_bg
                            property: "opacity"
                            duration: 500
                            to: 0
                            easing.type: Easing.InCubic
                        }
                    }
                }

                MouseControl {
                    visible: root.edit
                    anchors.fill: parent

                    onPressed: (button) => {
                        if (button == "L") {
                            WallpaperInfo.transition.posX = Math.max(Math.min(mouseX/preview.implicitWidth,1),0)
                            WallpaperInfo.transition.posY = Math.max(Math.min(mouseY/preview.implicitHeight,1),0)
                            pivotAnim.restart()
                        }
                    }

                    onMoved: {
                        if (buttonDown == "L") {
                            WallpaperInfo.transition.posX = Math.max(Math.min(mouseX/preview.implicitWidth,1),0)
                            WallpaperInfo.transition.posY = Math.max(Math.min(mouseY/preview.implicitHeight,1),0)
                            pivotAnim.restart()
                        }
                    }

                }

            }

            CellSeparator {

                w: box.contentW
                type: 2
                title.text: preview.visible ? "" : "Wallpapers"
                color: Colors.accentStrong

            }

            Cells {

                id: thumbnails

                w: box.contentW
                h: HyprInfo.windowCount(HyprInfo.focusedworkspace) > 0 && !root.minimal ? 8 : 7

                color: "transparent"

                clip: true

                RowLayout {

                    x: Cell.centerWCell(implicitWidth, parent.implicitWidth) - Cell.w(1)

                    id: selection

                    spacing: Cell.w(5)

                    onVisibleChanged: {
                        wallpapers = WallpaperInfo.all
                        selected = WallpaperInfo.getIndex(WallpaperInfo.current)
                    }

                    Component.onCompleted: {
                        WallpaperInfo.rescanned.connect(()=> {
                            wallpapers = []
                            wallpapers = WallpaperInfo.all
                            selected = WallpaperInfo.getIndex(WallpaperInfo.current)
                        })
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

                    function select() {
                        const current = items[2]
                        if (WallpaperInfo.inSet(current)) {
                            WallpaperInfo.remove(current)
                        } else {
                            WallpaperInfo.add(current)
                        }
                        repeater.refresh()
                    }

                    Repeater {

                        id: repeater

                        model: selection.items

                        function refresh() {
                            model = []
                            model = Qt.binding(()=>selection.items)
                        }

                        delegate: Loader {

                            id: thumbnail_loader

                            active: root.visible || !root.optimizeMemory

                            required property string modelData
                            required property int index

                            sourceComponent: CellBox {

                                id: thumbnail

                                property string modelData : thumbnail_loader.modelData
                                property int index        : thumbnail_loader.index

                                property string value: modelData.split(".")[0]
                                property bool selected: {
                                    return index == 2
                                } 

                                opacity: selected ? 1 : 0.5

                                Layout.topMargin: Cell.h(1)

                                w: Math.round((h-1)/9*16*2)-1
                                h: thumbnails.h

                                footer.text: " " + value + " "
                                footer.offset: Math.floor(contentW/2-value.length/2) - 1
                                footer.color: WallpaperInfo.inSet(modelData) ? Colors.secondary : Colors.fgBase
                                footer.font: WallpaperInfo.inSet(modelData) ? Cell.fontB : Cell.font

                                border.color: WallpaperInfo.inSet(modelData) ? Colors.secondary : "transparent"
                                border.type: WallpaperInfo.isLive(modelData) ? 3 : 4

                                Cells {

                                    w: thumbnail.w-2
                                    h: thumbnail.h-2

                                    color: "transparent"

                                    Image {

                                        anchors.centerIn: parent

                                        sourceSize.width: Cell.w(thumbnail.w)
                                        sourceSize.height: Cell.h(thumbnail.h-1)

                                        width: Cell.w(thumbnail.w)
                                        height: Cell.h(thumbnail.h-1)

                                        source: (thumbnail.modelData ? SystemInfo.homedir + WallpaperInfo.cache_path + thumbnail.modelData + WallpaperInfo.cache_prefix : "")

                                        fillMode: Image.PreserveAspectCrop

                                    }

                                }

                                MouseControl {
                                    anchors.fill: parent

                                    onReleased: (button) => {
                                        if (button == "L") {
                                            if (thumbnail.selected) {
                                                selection.select()
                                            } else {
                                                selection.advance(thumbnail.index - 2)
                                            }
                                        }
                                    }
                                }

                            }

                        }

                    }

                }

                MouseControl {

                    anchors.fill: parent

                    acceptedButtons: Qt.NoButton

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

                id: text_wrapper

                CellBox {

                    id: textbox

                    w: box.contentW
                    h: 3

                    border.type: 4
                    border.color: textfield.text.trim().length > 0 ? Colors.secondary : Colors.accentStrong

                    CellTextField {

                        x: Cell.w(1)
                        y: 0

                        id: textfield

                        w: textbox.contentW - 2
                        h: 1

                        editable: false

                        placeholder: "Search wallpaper"

                        onTextInput: (query) => {
                            if (text == " ") {
                                selection.select()
                                set("")
                                return
                            }
                            selection.wallpapers = WallpaperInfo.search(text)
                        }

                        ShortcutHandler {
                            shortcuts: [
                                {
                                    binds: "Left",
                                    action: () => {
                                        selection.advance(-1)
                                    }
                                },
                                {
                                    binds: "Right",
                                    action: () => {
                                        selection.advance(1)
                                    }
                                },
                                {
                                    binds: "Tab",
                                    active: textfield.focus,
                                    action: () => {
                                        more.yes = !more.yes
                                    }
                                },
                                {
                                    binds: "Escape",
                                    action: () => {
                                        if (!textfield.focus) {
                                            textfield.focus = true
                                            return
                                        }
                                        PopupManager.close("wallpaper")
                                    }
                                },
                                {
                                    binds: "Return",
                                    active: textfield.focus,
                                    action: () => {
                                        selection.select()
                                    }
                                }
                            ]
                        }

                    }

                }

            }

            RowLayout {

                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                spacing: 0

                CellButton {

                    property bool on: WallpaperInfo.slideshow

                    text: "<"

                    color: on ? Colors.accentStrong : Colors.bgOverlay
                    fg: on ? Colors.onAccent : Colors.fgSubtle

                    onPressed: (button) => {
                        if (button == "L") {
                            WallpaperInfo.advance(-1)
                        }
                    }

                }

                CellText {
                    text: " "
                }

                CellButton {

                    property bool on: WallpaperInfo.slideshow

                    text: "Slideshow"

                    color: on ? Colors.accentStrong : Colors.bgOverlay
                    fg: on ? Colors.onAccent : Colors.fgBase

                    onPressed: (button) => {
                        if (button == "L") {
                            WallpaperInfo.singlify(selection.wallpapers[selection.selected])
                            WallpaperInfo.slideshowToggle()
                        }
                    }

                }

                CellText {
                    text: " "
                }

                CellButton {

                    property bool on: WallpaperInfo.slideshow

                    text: ">"

                    color: on ? Colors.accentStrong : Colors.bgOverlay
                    fg: on ? Colors.onAccent : Colors.fgSubtle

                    onPressed: (button) => {
                        if (button == "L") {
                            WallpaperInfo.advance(1)
                        }
                    }

                }

                CellText {
                    text: "  Interval "
                    color: WallpaperInfo.slideshow ? Colors.fgBase : Colors.fgSubtle
                }

                Cells {

                    w: 7
                    h: 1

                    color: Colors.bgOverlay

                    CellTextField {

                        focusOnVisible: false

                        w: parent.w
                        h: 1

                        bindText: WallpaperInfo.slideshowInterval/1000
                        disabled: !WallpaperInfo.slideshow

                        unit: "s"

                        autoApply: true

                        onEntered: (text) => {
                            if (/^\d+$/.test(text)) {
                                WallpaperInfo.slideshowInterval = text*1000
                                textfield.focus = true
                            }
                        }

                        Keys.onPressed: (event) => {
                            if (event.key == Qt.Key_Escape) {
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
                        if (button == "L") {
                            WallpaperInfo.rescan()
                        }
                    }

                }

                CellText {
                    text: "  "
                }

                CellButton {

                    id: autoAdvance

                    property bool auto: yes && !WallpaperInfo.slideshow

                    property bool yes: true

                    text: "Auto advance"

                    clickable: !WallpaperInfo.slideshow

                    color: yes && clickable ? Colors.accentStrong : Colors.bgOverlay
                    fg: clickable ? (yes ? Colors.onAccent : Colors.fgBase) : Colors.fgSubtle

                    onPressed: (button) => {
                        if (button == "L") {
                            yes = !yes
                        }
                    }

                }

                CellText {
                    text: "  "
                }

                CellButton {

                    text: "Toggle all"

                    property bool notall: WallpaperInfo.wallpapers.length < WallpaperInfo.all.length

                    clickable: WallpaperInfo.slideshow

                    color: WallpaperInfo.slideshow ? [Colors.accentStrong, Colors.bgOverlay] : Colors.bgOverlay
                    fg: WallpaperInfo.slideshow ? [Colors.onAccent, Colors.fgBase] : Colors.fgSubtle

                    onPressed: (button) => {
                        if (button == "L") {
                            if (notall) {
                                WallpaperInfo.wallpapers = WallpaperInfo.all
                                return
                            } else {
                                WallpaperInfo.singlify(selection.wallpapers[selection.selected])
                            }
                        }
                    }

                }

                CellText {
                    text: "  "
                }

                CellButton {

                    text: "Live"

                    clickable: WallpaperInfo.isLive(selection.wallpapers[selection.selected])

                    color: clickable && WallpaperInfo.live ? Colors.accentStrong : Colors.bgOverlay
                    fg: clickable ? (WallpaperInfo.live ? Colors.onAccent : Colors.fgBase) : Colors.fgSubtle

                    onPressed: (button) => {
                        if (button == "L") {
                            WallpaperInfo.live = !WallpaperInfo.live
                        }
                    }

                }

                CellText {
                    text: "  "
                }

                CellButton {

                    id: more

                    text: "More"

                    onVisibleChanged: {
                        yes = false
                    }

                    onYesChanged: {
                        root.edit = false
                    }

                    property bool yes: false

                    color: yes ? Colors.accentStrong : Colors.bgOverlay
                    fg: yes ? Colors.onAccent : Colors.fgBase

                    onPressed: (button) => {
                        if (button == "L") {
                            yes = !yes
                        }
                    }

                }

            }

            ColumnLayout {

                visible: more.yes

                spacing: 0

                CellSeparator {
                    w: box.contentW
                    padding: 1
                    color: Colors.bgOverlay
                }

                RowLayout {

                    Layout.leftMargin: Cell.w(2)

                    spacing: Cell.w(1)

                    CellText {

                        Layout.alignment: Qt.AlignTop

                        text: "Transition:"

                    }

                    GridLayout {

                        rowSpacing: Cell.h(1)
                        columnSpacing: Cell.w(2)
                        columns: 6

                        uniformCellHeights: false
                        uniformCellWidths: false

                        RowLayout {

                            spacing: 0

                            CellText {
                                text: "Type "
                            }

                            CellDropdown {
                                w: 10
                                text: ""
                                reversed: true
                                scroll: true
                                selected: {
                                    for (const i in items) {
                                        if (items[i].label.toLowerCase() == WallpaperInfo.transition.type) {
                                            return i
                                        }
                                    }
                                    return 0
                                }
                                items: [
                                    {
                                        label: "None",
                                        action: () => {
                                            WallpaperInfo.transition.type = "none"
                                        },
                                    },
                                    {
                                        label: "Simple",
                                        action: () => {
                                            WallpaperInfo.transition.type = "simple"
                                        },
                                    },
                                    {
                                        label: "Wipe",
                                        action: () => {
                                            WallpaperInfo.transition.type = "wipe"
                                        },
                                    },
                                    {
                                        label: "Grow",
                                        action: () => {
                                            WallpaperInfo.transition.type = "grow"
                                        },
                                    },
                                    {
                                        label: "Shrink",
                                        action: () => {
                                            WallpaperInfo.transition.type = "shrink"
                                        },
                                    },
                                    {
                                        label: "Ripple",
                                        action: () => {
                                            WallpaperInfo.transition.type = "ripple"
                                        },
                                    },
                                ]
                            }

                        }

                        RowLayout {

                            spacing: Cell.w(1)

                            CellText {
                                text: "Step"
                            }

                            Cells {

                                w: 5
                                h: 1

                                color: Colors.bgOverlay

                                CellTextField {

                                    focusOnVisible: false

                                    w: parent.w
                                    h:1

                                    bindText: WallpaperInfo.transition.step

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^\d+$/.test(text)) {
                                            WallpaperInfo.transition.step = Math.max(text,1)
                                            textfield.focus = true
                                        }
                                    }

                                    onFocusChanged: {
                                        if (focus) {
                                            return
                                        }
                                    }

                                }
                            }

                        }

                        RowLayout {

                            visible: WallpaperInfo.transition.type != "none"

                            spacing: Cell.w(1)

                            CellText {
                                text: "Duration"
                            }

                            Cells {

                                w: 4
                                h: 1

                                color: Colors.bgOverlay

                                CellTextField {

                                    focusOnVisible: false

                                    w: parent.w
                                    h:1

                                    bindText: WallpaperInfo.transition.duration

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(text)) {
                                            WallpaperInfo.transition.duration = Math.max(text,0)
                                            textfield.focus = true
                                        }
                                    }

                                    onFocusChanged: {
                                        if (focus) {
                                            return
                                        }
                                    }

                                }
                            }

                        }

                        RowLayout {

                            spacing: Cell.w(1)

                            CellText {
                                text: "FPS"
                            }

                            Cells {

                                w: 4
                                h: 1

                                color: Colors.bgOverlay

                                CellTextField {

                                    focusOnVisible: false

                                    w: parent.w
                                    h:1

                                    bindText: WallpaperInfo.transition.fps

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^\d+$/.test(text)) {
                                            WallpaperInfo.transition.fps = Math.max(text,1)
                                            textfield.focus = true
                                        }
                                    }

                                    onFocusChanged: {
                                        if (focus) {
                                            return
                                        }
                                    }

                                }
                            }

                        }

                        RowLayout {

                            visible: (
                                WallpaperInfo.transition.type == "wipe" ||
                                WallpaperInfo.transition.type == "wave"
                            )

                            spacing: Cell.w(1)

                            CellText {
                                text: "Angle"
                            }

                            Cells {

                                w: 4
                                h: 1

                                color: Colors.bgOverlay

                                CellTextField {

                                    focusOnVisible: false

                                    w: parent.w
                                    h:1

                                    bindText: WallpaperInfo.transition.angle

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^\d+$/.test(text)) {
                                            WallpaperInfo.transition.angle = Math.max(Math.min(text,360),0)
                                            textfield.focus = true
                                        }
                                    }

                                    onFocusChanged: {
                                        if (focus) {
                                            return
                                        }
                                    }

                                }
                            }

                        }

                        RowLayout {

                            visible: (
                                WallpaperInfo.transition.type == "ripple" ||
                                WallpaperInfo.transition.type == "grow" ||
                                WallpaperInfo.transition.type == "shrink"
                            )

                            spacing: Cell.w(1)

                            CellText {
                                text: "Pos"
                            }

                            Cells {

                                w: 5
                                h: 1

                                color: Colors.bgOverlay

                                CellTextField {

                                    id: posX

                                    focusOnVisible: false

                                    w: parent.w
                                    h:1

                                    bindText: WallpaperInfo.transition.posX.toFixed(2)

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(text)) {
                                            WallpaperInfo.transition.posX = parseFloat(text)
                                            textfield.focus = true
                                        }
                                    }

                                    onFocusChanged: {
                                        if (focus) {
                                            return
                                        }
                                    }

                                    Keys.onPressed: (event) => {
                                        if (event.key == Qt.Key_Tab) {
                                            posX.unFocus()
                                            posY.grabFocus()
                                        }
                                    }

                                }
                            }

                            Cells {

                                w: 5
                                h: 1

                                color: Colors.bgOverlay

                                CellTextField {

                                    id: posY

                                    focusOnVisible: false

                                    w: parent.w
                                    h:1

                                    bindText: WallpaperInfo.transition.posY.toFixed(2)

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(text)) {
                                            WallpaperInfo.transition.posY = parseFloat(text)
                                            textfield.focus = true
                                        }
                                    }

                                    onFocusChanged: {
                                        if (focus) {
                                            return
                                        }
                                    }

                                    Keys.onPressed: (event) => {
                                        if (event.key == Qt.Key_Tab) {
                                            posY.unFocus()
                                            posX.grabFocus()
                                        }
                                    }

                                }
                            }

                            CellButton {

                                text: "Edit"

                                color: root.edit ? Colors.accentStrong : Colors.bgOverlay
                                fg: root.edit ? Colors.onAccent : Colors.fgBase

                                onReleased: (button) => {
                                    if (button == "L") {
                                        root.edit = !root.edit
                                    }
                                }

                            }

                        }

                    }
                }

                CellSeparator {
                    w: box.contentW
                    padding: 1
                    color: Colors.bgOverlay
                }

                RowLayout {

                    Layout.leftMargin: Cell.w(2)

                    spacing: Cell.w(1)

                    CellText {

                        Layout.alignment: Qt.AlignTop

                        text: "Reposition:"

                    }

                }

            }

            CellSeparator {

                visible: SettingsInfo.hints

                w: box.contentW
                type: 0
                color: Colors.accentStrong
            }

            RowLayout {

                visible: SettingsInfo.hints

                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                spacing: Cell.w(2)

                CellKeyHint {
                    visible: textfield.text.length == 0
                    key: "← →"
                    hint: "Navigate"
                }

                CellKeyHint {
                    visible: !autoAdvance.auto && !WallpaperInfo.slideshow && textfield.text.length == 0
                    key: "Space"
                    hint: "Select"
                }

                CellKeyHint {
                    visible: WallpaperInfo.slideshow && textfield.text.length == 0
                    key: "Space"
                    hint: "Toggle"
                }

                CellKeyHint {
                    visible: !autoAdvance.auto && !WallpaperInfo.slideshow && textfield.text.length > 0
                    key: "Enter"
                    hint: "Select"
                }

                CellKeyHint {
                    visible: WallpaperInfo.slideshow && textfield.text.length > 0
                    key: "Enter"
                    hint: "Toggle"
                }

                CellKeyHint {
                    key: "Tab"
                    hint: "More"
                }

            }

        }

    }

}
