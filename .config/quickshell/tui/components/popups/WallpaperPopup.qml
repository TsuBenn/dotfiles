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
            root.reposition = false
        })
    }

    onVisibleChanged: {
        edit = false
        reposition = false
    }

    onEditChanged: {
        if (edit) {
            pivotAnim.restart()
            reposition = false
        }
    }

    onRepositionChanged: {
        if (reposition) {
            edit = false
        }
    }

    property bool edit: false
    property bool reposition: false

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

                visible: root.edit || root.reposition || (HyprInfo.windowCount(HyprInfo.focusedworkspace) > 0 && !root.minimal)

                w: box.contentW
                h: Math.floor(root.w/16*9/2)

                color: "transparent"

                Item {

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
                    x: Cell.w(Math.round((preview.w-1)*WallpaperInfo.getTransition(selection.items[2]).posX))
                    y: Cell.h(Math.round((preview.h-1)*WallpaperInfo.getTransition(selection.items[2]).posY))
                    text: "✕"
                    font: Cell.fontBB

                }

                CellText {
                    id: pivot
                    opacity: 0
                    visible: root.edit
                    x: Math.max(Math.min(crosshair.x + Cell.w(-Math.round(w/2)+1),Cell.w(preview.w-w)),0)
                    y: crosshair.y + (Cell.hCount(crosshair.y,"ceil") >= preview.h ? Cell.h(-1) : Cell.h(1))
                    text: WallpaperInfo.getTransition(selection.items[2]).posX.toFixed(2) + "✕" + WallpaperInfo.getTransition(selection.items[2]).posY.toFixed(2)
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

                SequentialAnimation {
                    id: repoAnim
                    ParallelAnimation {
                        NumberAnimation {
                            target: repo_bg
                            property: "opacity"
                            to: 0
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: repo_hint
                            property: "opacity"
                            to: 0
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                    PauseAnimation {
                        duration: 200
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: repo_bg
                            property: "opacity"
                            to: 0.5
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: repo_hint
                            property: "opacity"
                            to: 1
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                SequentialAnimation {
                    id: repoAnimStart
                    ParallelAnimation {
                        NumberAnimation {
                            target: repo_bg
                            property: "opacity"
                            from: 0
                            to: 0.5
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: repo_hint
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Cells {
                    id: repo_bg
                    visible: root.reposition
                    onVisibleChanged: {
                        repoAnimStart.restart()
                    }
                    w: parent.w
                    h: parent.h
                    opacity: 0.5
                    color: "black"

                }

                CellText {

                    id: repo_hint

                    visible: root.reposition

                    x: Cell.centerWCell(implicitWidth, repo_bg.implicitWidth)
                    y: Cell.centerHCell(implicitHeight, repo_bg.implicitHeight)

                    text: [
                        "                   ↑                  ",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "←    Drag to Move & Wheel to Zoom    →",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "                                      ",
                        "                   ↓                  ",
                    ].join("\n")
                }

                MouseControl {
                    visible: root.edit
                    anchors.fill: parent

                    onPressed: (button) => {
                        if (button == "L") {
                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                WallpaperInfo.setConfig(selection.items[2], "transition.posX", Math.max(Math.min(mouseX/preview.implicitWidth,1),0))
                                WallpaperInfo.setConfig(selection.items[2], "transition.posY", Math.max(Math.min(mouseY/preview.implicitHeight,1),0))
                            } else {
                                WallpaperInfo.transition.posX = Math.max(Math.min(mouseX/preview.implicitWidth,1),0)
                                WallpaperInfo.transition.posY = Math.max(Math.min(mouseY/preview.implicitHeight,1),0)
                            }
                            pivotAnim.restart()
                        }
                    }

                    onMoved: {
                        if (buttonDown == "L") {
                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                WallpaperInfo.setConfig(selection.items[2], "transition.posX", Math.max(Math.min(mouseX/preview.implicitWidth,1),0))
                                WallpaperInfo.setConfig(selection.items[2], "transition.posY", Math.max(Math.min(mouseY/preview.implicitHeight,1),0))
                            } else {
                                WallpaperInfo.transition.posX = Math.max(Math.min(mouseX/preview.implicitWidth,1),0)
                                WallpaperInfo.transition.posY = Math.max(Math.min(mouseY/preview.implicitHeight,1),0)
                            }
                            pivotAnim.restart()
                        }
                    }

                }

                MouseControl {

                    visible: root.reposition
                    anchors.fill: parent

                    property real oldVert: 0
                    property real oldHori: 0

                    property int baseX: 0
                    property int baseY: 0
                    property real deltaX: 0
                    property real deltaY: 0

                    onWheel: (delta) => {
                        repoAnim.restart()
                        WallpaperInfo.setConfig(selection.items[2],"reposition.scalar", Math.max(WallpaperInfo.getReposition(selection.items[2]).scalar+(delta/10),1))
                        wallpaper.width - preview.width == 0 ? WallpaperInfo.setConfig(selection.items[2],"reposition.horizontalOffset", 0) : 0
                        wallpaper.height - preview.height == 0 ? WallpaperInfo.setConfig(selection.items[2],"reposition.verticalOffset", 0) : 0
                    }

                    onPressed: (button) => {
                        if (button == "L") {
                            repoAnim.restart()
                            baseX = mouseX
                            baseY = mouseY

                            oldVert = WallpaperInfo.getReposition(selection.items[2]).verticalOffset
                            oldHori = WallpaperInfo.getReposition(selection.items[2]).horizontalOffset
                        }
                    }

                    onMoved: (x, y) => {
                        if (buttonDown == "L") {

                            repoAnim.restart()

                            deltaX = wallpaper.width - preview.width == 0 ? 0 : (x - baseX)/((wallpaper.width - preview.width)/2)
                            deltaY = wallpaper.height - preview.height == 0 ? 0 : (y - baseY)/((wallpaper.height - preview.height)/2)

                            WallpaperInfo.setConfig(selection.items[2],"reposition.horizontalOffset", wallpaper.width - preview.width == 0 ? 0 : Math.max(Math.min(oldHori + deltaX,1),-1))
                            WallpaperInfo.setConfig(selection.items[2],"reposition.verticalOffset", wallpaper.height - preview.height == 0 ? 0 : Math.max(Math.min(oldVert + deltaY,1),-1))

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
                        TextFieldManager.unFocusAll()
                        textfield.grabFocus()
                        if (autoAdvance.auto) WallpaperInfo.add(items[2+step])
                        selected = (selected + selection.wallpapers.length + step)%selection.wallpapers.length
                    }

                    function select() {
                        TextFieldManager.unFocusAll()
                        textfield.grabFocus()
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

                    Layout.leftMargin: Cell.w(1)

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
                                        if (items[i].label.toLowerCase() == WallpaperInfo.getTransition(selection.items[2]).type) {
                                            return i
                                        }
                                    }
                                    return 0
                                }
                                items: [
                                    {
                                        label: "None",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "none")
                                            } else {
                                                WallpaperInfo.transition.type = "none"
                                            }
                                        },
                                    },
                                    {
                                        label: "Simple",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "simple")
                                            } else {
                                                WallpaperInfo.transition.type = "simple"
                                            }
                                        },
                                    },
                                    {
                                        label: "Wipe",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "wipe")
                                            } else {
                                                WallpaperInfo.transition.type = "wipe"
                                            }
                                        },
                                    },
                                    {
                                        label: "Grow",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "grow")
                                            } else {
                                                WallpaperInfo.transition.type = "grow"
                                            }
                                        },
                                    },
                                    {
                                        label: "Shrink",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "shrink")
                                            } else {
                                                WallpaperInfo.transition.type = "shrink"
                                            }
                                        },
                                    },
                                    {
                                        label: "Ripple",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "ripple")
                                            } else {
                                                WallpaperInfo.transition.type = "ripple"
                                            }
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

                                w: 4
                                h: 1

                                color: Colors.bgOverlay

                                CellTextField {

                                    focusOnVisible: false

                                    w: parent.w
                                    h:1

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).step

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^\d+$/.test(text)) {
                                            text = Math.max(Math.min(text,100),1)
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.step", text)
                                            } else {
                                                WallpaperInfo.transition.step = text
                                            }
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

                            visible: WallpaperInfo.getTransition(selection.items[2]).type != "none"

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

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).duration

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(text)) {
                                            text = Math.max(text,0)
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.duration", text)
                                            } else {
                                                WallpaperInfo.transition.duration = text
                                            }
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

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).fps

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^\d+$/.test(text)) {
                                            text = Math.max(text,1)
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.fps", text)
                                            } else {
                                                WallpaperInfo.transition.fps = text
                                            }
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
                                WallpaperInfo.getTransition(selection.items[2]).type == "wipe" ||
                                WallpaperInfo.getTransition(selection.items[2]).type == "wave"
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

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).angle

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^\d+$/.test(text)) {
                                            text = Math.max(Math.min(text,360),0)
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.angle", text)
                                            } else {
                                                WallpaperInfo.transition.angle = text
                                            }
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
                                WallpaperInfo.getTransition(selection.items[2]).type == "ripple" ||
                                WallpaperInfo.getTransition(selection.items[2]).type == "grow" ||
                                WallpaperInfo.getTransition(selection.items[2]).type == "shrink"
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

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).posX.toFixed(2)

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(text)) {
                                            text = Math.max(Math.min(parseFloat(text),1),0)
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.posX", text)
                                            } else {
                                                WallpaperInfo.transition.posX = text
                                            }
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

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).posY.toFixed(2)

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: (text) => {
                                        if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(text)) {
                                            text = Math.max(Math.min(parseFloat(text),1),0)
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.posY", text)
                                            } else {
                                                WallpaperInfo.transition.posY = text
                                            }
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

                    CellButton {

                        text: "Bind"

                        color: WallpaperInfo.config[selection.items[2]]?.transition ? Colors.accentStrong : Colors.bgOverlay
                        fg: WallpaperInfo.config[selection.items[2]]?.transition ? Colors.onAccent : Colors.fgBase

                        onReleased: (button) => {
                            if (button == "L") {
                                if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                    delete WallpaperInfo.config[selection.items[2]].transition
                                    WallpaperInfo.configChanged()
                                } else {
                                    WallpaperInfo.setConfig(selection.items[2], "transition", WallpaperInfo.getTransition(""))
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

                    Layout.leftMargin: Cell.w(1)

                    spacing: 0

                    CellText {

                        Layout.alignment: Qt.AlignTop

                        text: "Reposition:"

                    }

                    CellText {
                        text: "  "
                    }

                    CellText {
                        text: "Scale "
                    }

                    Cells {

                        w: 5
                        h: 1

                        color: Colors.bgOverlay

                        CellTextField {

                            id: scalar_textfield

                            w: parent.w
                            h: parent.h

                            focusOnVisible: false
                            autoApply: true
                            escapeToUnFocus: true
                            unfocusOnEntered: true

                            bindText: WallpaperInfo.getReposition(selection.items[2]).scalar.toFixed(2)

                            onEntered: (input) => {
                                if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(input)) {
                                    input = Math.max(parseFloat(input),1)
                                    WallpaperInfo.setConfig(selection.items[2],"reposition.scalar", input)

                                    textfield.focus = true
                                }
                            }

                        }
                    }

                    CellText {
                        text: "  "
                    }

                    CellText {
                        text: "Vertical offset "
                    }

                    Cells {

                        w: 6
                        h: 1

                        color: Colors.bgOverlay

                        CellTextField {

                            id: vert_textfield

                            w: parent.w
                            h: parent.h

                            focusOnVisible: false
                            autoApply: true
                            escapeToUnFocus: true
                            unfocusOnEntered: true

                            bindText: WallpaperInfo.getReposition(selection.items[2]).verticalOffset.toFixed(2)

                            onEntered: (input) => {
                                if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(input)) {
                                    input = Math.max(Math.min(parseFloat(input),1),0)
                                    WallpaperInfo.setConfig(selection.items[2],"reposition.verticalOffset",input)
                                    textfield.focus = true
                                }
                            }

                        }
                    }

                    CellText {
                        text: "  "
                    }

                    CellText {
                        text: "Horizontal offset "
                    }

                    Cells {

                        w: 6
                        h: 1

                        color: Colors.bgOverlay

                        CellTextField {

                            id: hori_textfield

                            w: parent.w
                            h: parent.h

                            focusOnVisible: false
                            autoApply: true
                            escapeToUnFocus: true
                            unfocusOnEntered: true

                            bindText: WallpaperInfo.getReposition(selection.items[2]).horizontalOffset.toFixed(2)

                            onEntered: (input) => {
                                if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(input)) {
                                    input = Math.max(Math.min(parseFloat(input),1),0)
                                    WallpaperInfo.setConfig(selection.items[2],"reposition.horizontalOffset",input)

                                    textfield.focus = true
                                }
                            }

                        }
                    }

                    CellText {
                        text: "  "
                    }

                    CellButton {

                        text: "Edit"

                        color: root.reposition ? Colors.accentStrong : Colors.bgOverlay
                        fg: root.reposition ? Colors.onAccent : Colors.fgBase

                        onReleased: (button) => {
                            if (button == "L") {
                                root.reposition = !root.reposition
                            }
                        }

                    }

                    CellText {
                        text: "  "
                    }

                    CellButton {

                        text: "Re-center"

                        color: [Colors.accentStrong, Colors.bgOverlay]
                        fg: [Colors.onAccent, Colors.fgBase]

                        onReleased: (button) => {
                            if (button == "L") {
                                scalar_textfield.unFocus()
                                vert_textfield.unFocus()
                                hori_textfield.unFocus()
                                if (WallpaperInfo.config[selection.items[2]]?.reposition) {
                                    WallpaperInfo.config[selection.items[2]].reposition.scalar = 1
                                    WallpaperInfo.config[selection.items[2]].reposition.horizontalOffset = 0
                                    WallpaperInfo.config[selection.items[2]].reposition.verticalOffset = 0
                                } else {
                                    WallpaperInfo.config[selection.items[2]].reposition = {
                                        scalar: 1,
                                        verticalOffset: 0,
                                        horizontalOffset: 0,
                                    }
                                }
                                WallpaperInfo.configChanged()
                            }
                        }

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
