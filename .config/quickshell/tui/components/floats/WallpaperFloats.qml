pragma ComponentBehavior: Bound

import qs.config
import qs.services
import qs.modules

import QtQuick
import QtQuick.Layouts

CellFloats {
    id: root

    property bool optimizeMemory: SettingsInfo.optimizeMemory

    property bool minimal: SettingsInfo.minimal || (!advanced)

    property var monitor: HyprInfo.focusedMonitor

    property var desktop: false

    property var advanced: false

    onWorkspaceChanged: desktopCheck.restart()

    Timer {
        id: desktopCheck
        interval: 200
        onTriggered: root.checkDesktop()
    }

    function checkDesktop() {
        // console.log("bruh");
        const old = desktop;
        if (HyprInfo.clientCount() < 2) {
            desktop = true;
            // advanced = false;
        } else {
            desktop = false;
            // advanced = true;
        }
        if (desktop && !advanced) {
            HyprInfo.repositionClient((monitor.width - implicitWidth) / 2, monitor.height - implicitHeight - Cell.border_width, address);
        } else if (desktop != old)
            HyprInfo.repositionClient((monitor.width - implicitWidth) / 2, (monitor.height - implicitHeight) / 2, address);
    }

    function init() {
        // checkDesktop();
    }

    onVisibleChanged: {
        edit = false;
        reposition = false;
        textfield.set("");
        // checkDesktop();
    }

    function onSigOpen() {
        // console.log("first");
        if (reloading)
            return;
        if (HyprInfo.clientCount() < 1) {
            desktop = true;
            advanced = false;
        } else {
            desktop = false;
            advanced = true;
        }
    }

    // onAdvancedChanged: {
    //     console.log("advanced: " + advanced);
    // }

    // onReloadingChanged: {
    //     console.log(reloading);
    // }

    name: "wallpaper"

    w: 96
    h: (minimal ? 14 : 49) - !SettingsInfo.hints * 2

    shortcuts: [
        {
            binds: ["Left", "Backtab"],
            action: () => {
                selection.advance(-1);
            }
        },
        {
            binds: ["Right", "Tab"],
            action: () => {
                selection.advance(1);
            }
        },
        {
            binds: "Ctrl+R",
            action: () => {
                WallpaperInfo.rescan();
            }
        },
        {
            binds: "Ctrl+E",
            action: () => {
                root.advanced = !root.advanced;
            }
        },
        {
            binds: "Escape",
            action: () => {
                close();
            }
        }
    ]

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
            duration: Math.max(WallpaperInfo.getTransition(WallpaperInfo.current).duration * 1000 - 200, 0)
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
        WallpaperInfo.currentChanged.connect(() => {
            if (HyprInfo.clientCount() == 0)
                hide.restart();
            root.edit = false;
            root.reposition = false;
        });
    }

    onEditChanged: {
        if (edit) {
            pivotAnim.restart();
            reposition = false;
        } else {
            pivotAnimEnd.restart();
        }
    }

    onRepositionChanged: {
        if (reposition) {
            repoAnimStart.restart();
            edit = false;
        } else {
            repoAnimEnd.restart();
        }
    }

    property bool edit: false
    property bool reposition: false

    Cells {
        id: box

        w: root.w
        h: root.h

        property int contentW: w
        property int contentH: h

        color: "transparent"

        ColumnLayout {
            id: layout

            spacing: 0

            CellText {
                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                text: "WALLPAPERS"
                color: Colors.secondary
                font: Cell.fontBB
            }

            CellSeparator {
                w: box.w
                color: Colors.accentStrong
                bg: "transparent"
                connectStart: true
                connectEnd: true
            }

            Cells {
                id: preview
                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                visible: root.edit || root.reposition || (!root.minimal || root.advanced)

                w: box.w
                h: Math.floor(w / 16 * 9 / 2)

                color: "transparent"

                // --- ALIASES & CACHED PROPERTIES TO REMOVE REPETITION ---
                property string currentItem: selection.items[2] || ""

                // Cache the configuration objects so we aren't querying C++/JS backend repeatedly
                property var repoData: WallpaperInfo.getReposition(currentItem)
                property var transData: WallpaperInfo.getTransition(currentItem)
                property var configData: WallpaperInfo.config[currentItem]

                clip: true

                Item {

                    anchors.centerIn: parent

                    implicitWidth: preview.implicitHeight * (root.monitor.width / root.monitor.height)
                    implicitHeight: preview.implicitHeight

                    clip: true

                    Image {
                        id: wallpaper
                        anchors.centerIn: parent
                        width: sourceSize.width
                        height: sourceSize.height

                        property bool animation: true
                        scale: 1 * scalar

                        // Simplified math utilizing our cached backend data references
                        property real maxDeltaW: (Math.round(width * scalar) - Math.round(parent.width)) / 2
                        property real maxDeltaH: (Math.round(height * scalar) - Math.round(parent.height)) / 2

                        property double monitorScalar: Math.max(root.monitor.width / sourceSize.width, root.monitor.height / sourceSize.height) * (preview.repoData ? preview.repoData.scalar : 1)

                        anchors.verticalCenterOffset: maxDeltaH * (preview.repoData ? preview.repoData.verticalOffset : 0)
                        anchors.horizontalCenterOffset: maxDeltaW * (preview.repoData ? preview.repoData.horizontalOffset : 0)

                        Behavior on scale {
                            NumberAnimation {
                                duration: 200 * wallpaper.animation
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on anchors.verticalCenterOffset {
                            NumberAnimation {
                                duration: 200 * wallpaper.animation
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on anchors.horizontalCenterOffset {
                            NumberAnimation {
                                duration: 200 * wallpaper.animation
                                easing.type: Easing.OutCubic
                            }
                        }

                        property double scalar: Math.max(parent.width / sourceSize.width, parent.height / sourceSize.height) * (preview.repoData ? preview.repoData.scalar : 1)
                        source: preview.currentItem ? (SystemInfo.homedir + WallpaperInfo.cache_path + preview.currentItem + WallpaperInfo.cache_prefix) : ""
                    }

                    Timer {
                        id: wallpaperAnimationCooldown
                        interval: 200
                        onTriggered: wallpaper.animation = true
                    }

                    Rectangle {
                        implicitWidth: parent.width
                        implicitHeight: (Cell.h(1) / root.monitor.height) * parent.height
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
                    x: Cell.w(Math.round((preview.w - 1) * (preview.transData ? preview.transData.posX : 0)))
                    y: Cell.h(Math.round((preview.h - 1) * (preview.transData ? preview.transData.posY : 0)))
                    text: "✕"
                    font: Cell.fontBB
                }

                CellText {
                    id: pivot
                    opacity: 0
                    visible: root.edit
                    x: Math.max(Math.min(crosshair.x + Cell.w(-Math.round(w / 2) + 1), Cell.w(preview.w - w)), 0)
                    y: crosshair.y + (Cell.hCount(crosshair.y, "ceil") >= preview.h ? Cell.h(-1) : Cell.h(1))
                    text: (preview.transData ? preview.transData.posX.toFixed(2) : "0.00") + "✕" + (preview.transData ? preview.transData.posY.toFixed(2) : "0.00")
                    bg: Colors.bgSurface
                }

                // --- ANIMATIONS ---
                SequentialAnimation {
                    id: pivotAnim
                    ScriptAction {
                        script: {
                            pivot.visible = true;
                            pivot_bg.visible = true;
                            crosshair.visible = true;
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target: crosshair
                            property: "opacity"
                            duration: 200
                            to: 1
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: pivot
                            property: "opacity"
                            duration: 200
                            to: 1
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: pivot_bg
                            property: "opacity"
                            duration: 200
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
                    id: pivotAnimEnd
                    ParallelAnimation {
                        NumberAnimation {
                            target: pivot
                            property: "opacity"
                            duration: 200
                            to: 0
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: pivot_bg
                            property: "opacity"
                            duration: 200
                            to: 0
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target: crosshair
                            property: "opacity"
                            duration: 200
                            to: 0
                            easing.type: Easing.InCubic
                        }
                    }
                    ScriptAction {
                        script: {
                            pivot.visible = false;
                            pivot_bg.visible = false;
                            crosshair.visible = false;
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
                    // ScriptAction {
                    //     script: {
                    //         repo_bg.visible = true;
                    //         repo_hint.visible = true;
                    //     }
                    // }
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

                SequentialAnimation {
                    id: repoAnimEnd
                    ParallelAnimation {
                        NumberAnimation {
                            target: repo_bg
                            property: "opacity"
                            to: 0
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: repo_hint
                            property: "opacity"
                            to: 0
                            duration: 500
                            easing.type: Easing.OutCubic
                        }
                    }
                    // ScriptAction {
                    //     script: {
                    //         repo_bg.visible = false;
                    //         repo_hint.visible = false;
                    //     }
                    // }
                }

                Cells {
                    id: repo_bg
                    // visible: false
                    w: parent.w
                    h: parent.h
                    opacity: 0
                    color: "black"
                }

                CellText {
                    id: repo_hint

                    // visible: false
                    opacity: 0

                    x: Cell.centerWCell(implicitWidth, repo_bg.implicitWidth)
                    y: Cell.centerHCell(implicitHeight, repo_bg.implicitHeight)

                    text: ["                   ↑                  ", "                                      ", "                                      ", "                                      ", "                                      ", "                                      ", "                                      ", "                                      ", "                                      ", "←    Drag to Move & Wheel to Zoom    →", "                                      ", "                                      ", "                                      ", "                                      ", "                                      ", "                                      ", "                                      ", "                                      ", "                   ↓                  ",].join("\n")
                }

                // --- REFACTORED INPUT CONTROLS ---
                MouseControl {
                    visible: root.edit
                    anchors.fill: parent

                    function updateTransition(mx, my) {
                        let path = preview.configData?.transition ? "transition." : "";
                        if (path) {
                            WallpaperInfo.setConfig(preview.currentItem, path + "posX", Math.max(Math.min(mx / preview.implicitWidth, 1), 0));
                            WallpaperInfo.setConfig(preview.currentItem, path + "posY", Math.max(Math.min(my / preview.implicitHeight, 1), 0));
                        } else {
                            WallpaperInfo.transition.posX = Math.max(Math.min(mx / preview.implicitWidth, 1), 0);
                            WallpaperInfo.transition.posY = Math.max(Math.min(my / preview.implicitHeight, 1), 0);
                        }
                        pivotAnim.restart();
                    }

                    onPressed: button => {
                        if (button === "L")
                            updateTransition(mouseX, mouseY);
                    }
                    onMoved: {
                        if (buttonDown === "L")
                            updateTransition(mouseX, mouseY);
                    }
                }

                MouseControl {
                    visible: root.reposition
                    anchors.fill: parent

                    property real oldVert: 0
                    property real oldHori: 0
                    property int baseX: 0
                    property int baseY: 0

                    onWheel: delta => {
                        repoAnim.restart();
                        let newScalar = Math.max((preview.repoData ? preview.repoData.scalar : 1) + (delta / 10), 1);
                        WallpaperInfo.setConfig(preview.currentItem, "reposition.scalar", newScalar);

                        if (wallpaper.maxDeltaW === 0)
                            WallpaperInfo.setConfig(preview.currentItem, "reposition.horizontalOffset", 0);
                        if (wallpaper.maxDeltaH === 0)
                            WallpaperInfo.setConfig(preview.currentItem, "reposition.verticalOffset", 0);
                    }

                    onPressed: button => {
                        if (button === "L") {
                            repoAnim.restart();
                            baseX = mouseX;
                            baseY = mouseY;
                            oldVert = preview.repoData ? preview.repoData.verticalOffset : 0;
                            oldHori = preview.repoData ? preview.repoData.horizontalOffset : 0;
                        }
                    }

                    onMoved: (x, y) => {
                        if (buttonDown === "L") {
                            repoAnim.restart();

                            let deltaX = wallpaper.maxDeltaW === 0 ? 0 : (x - baseX) / wallpaper.maxDeltaW;
                            let deltaY = wallpaper.maxDeltaH === 0 ? 0 : (y - baseY) / wallpaper.maxDeltaH;

                            WallpaperInfo.setConfig(preview.currentItem, "reposition.horizontalOffset", wallpaper.maxDeltaW === 0 ? 0 : Math.max(Math.min(oldHori + deltaX, 1), -1));
                            WallpaperInfo.setConfig(preview.currentItem, "reposition.verticalOffset", wallpaper.maxDeltaH === 0 ? 0 : Math.max(Math.min(oldVert + deltaY, 1), -1));
                        }
                    }
                }
            }

            CellSeparator {
                visible: preview.visible
                w: box.contentW
                type: 2
                color: Colors.accentStrong
            }

            Cells {
                id: thumbnails

                w: box.contentW
                h: (!root.minimal ? 7 : 6)

                color: "transparent"

                clip: true

                RowLayout {

                    visible: WallpaperInfo.scanning

                    x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
                    y: Cell.centerHCell(implicitHeight, parent.implicitHeight)

                    spacing: 0

                    CellText {
                        text: "Rescanning wallpapers in " + "~" + WallpaperInfo.cache_path
                        color: Colors.fgDim
                    }

                    CellLoading {
                        style: 2
                    }
                }

                RowLayout {
                    id: selection

                    visible: !WallpaperInfo.scanning

                    x: Cell.centerWCell(implicitWidth, root.implicitWidth) - Cell.w(1)

                    spacing: Cell.w(5)

                    onVisibleChanged: {
                        wallpapers = WallpaperInfo.all;
                        selected = WallpaperInfo.getIndex(WallpaperInfo.current);
                    }

                    Component.onCompleted: {
                        WallpaperInfo.rescanned.connect(() => {
                            wallpapers = [];
                            wallpapers = WallpaperInfo.all;
                            selected = WallpaperInfo.getIndex(WallpaperInfo.current);
                        });
                    }

                    property int selected

                    property var wallpapers: WallpaperInfo.all

                    property var items: {
                        const length = wallpapers.length;
                        const offset = selected + length;
                        const available = wallpapers;

                        wallpaper.animation = false;
                        wallpaperAnimationCooldown.restart();

                        return [available[(offset - 2) % length], available[(offset - 1) % length], available[(offset) % length], available[(offset + 1) % length], available[(offset + 2) % length]];
                    }

                    function advance(step: int) {
                        if (autoAdvance.auto)
                            WallpaperInfo.add(items[2 + step]);
                        selected = (selected + selection.wallpapers.length + step) % selection.wallpapers.length;
                    }

                    function select() {
                        const current = items[2];
                        if (WallpaperInfo.inSet(current)) {
                            WallpaperInfo.remove(current);
                        } else {
                            WallpaperInfo.add(current);
                        }
                        repeater.refresh();
                    }

                    Repeater {
                        id: repeater

                        model: 5

                        function refresh() {
                            model = [];
                            model = Qt.binding(() => selection.items);
                        }

                        delegate: Loader {
                            id: thumbnail_loader

                            active: root.visible || !root.optimizeMemory

                            property string modelData: selection.items?.[index] ?? ""
                            required property int index

                            sourceComponent: CellBox {
                                id: thumbnail

                                property string modelData: thumbnail_loader.modelData.replace("undefined", "")
                                property int index: thumbnail_loader.index

                                property string value: modelData.split(".")[0]
                                property bool selected: WallpaperInfo.scanning ? false : (index == 2)

                                opacity: selected ? 1 : 0.5

                                Layout.topMargin: Cell.h(1)

                                w: h * 3
                                h: thumbnails.h

                                footer.text: " " + value + " "
                                footer.centered: true
                                footer.color: WallpaperInfo.inSet(modelData) ? Colors.secondary : Colors.fgBase
                                footer.font: WallpaperInfo.inSet(modelData) ? Cell.fontB : Cell.font

                                border.color: WallpaperInfo.inSet(modelData) ? Colors.secondary : "transparent"
                                border.type: WallpaperInfo.isLive(modelData) ? 3 : 1

                                Cells {

                                    w: thumbnail.w - 2
                                    h: thumbnail.h - 2

                                    color: "transparent"

                                    Image {

                                        anchors.centerIn: parent

                                        sourceSize.width: Cell.w(thumbnail.w - 2)
                                        sourceSize.height: Cell.h(thumbnail.h - 2)

                                        width: Cell.w(thumbnail.w - 2)
                                        height: Cell.h(thumbnail.h - 2)

                                        source: (thumbnail.modelData ? (SystemInfo.homedir + WallpaperInfo.cache_path + thumbnail.modelData + WallpaperInfo.cache_prefix) : "")

                                        fillMode: Image.PreserveAspectCrop
                                    }
                                }

                                MouseControl {

                                    visible: !WallpaperInfo.scanning

                                    anchors.fill: parent

                                    onReleased: button => {
                                        if (button == "L") {
                                            if (thumbnail.selected) {
                                                selection.select();
                                            } else {
                                                selection.advance(thumbnail.index - 2);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Cells {
                id: text_wrapper

                w: box.contentW
                h: 3

                color: "transparent"

                CellBox {
                    id: textbox

                    w: box.contentW
                    h: 3

                    border.color: textfield.text.trim().length > 0 ? Colors.secondary : Colors.accentStrong

                    CellTextField {
                        id: textfield

                        x: Cell.w(1)
                        y: 0

                        w: textbox.contentW - 2
                        h: 1

                        focusOnVisible: true

                        forceFocus: true

                        escapeToUnFocus: false

                        placeholder: "Search wallpaper"

                        moveable: false

                        onEntered: {
                            selection.select();
                        }

                        onTextInput: query => {
                            if (text == " ") {
                                selection.select();
                                set("");
                                return;
                            }
                            if (query == "") {
                                selection.wallpapers = WallpaperInfo.all;
                                selection.selected = WallpaperInfo.getIndex(WallpaperInfo.current);
                                return;
                            }

                            selection.wallpapers = WallpaperInfo.search(text);
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

                    onPressed: button => {
                        if (button == "L") {
                            WallpaperInfo.advance(-1);
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

                    onPressed: button => {
                        if (button == "L") {
                            WallpaperInfo.singlify(selection.wallpapers[selection.selected]);
                            WallpaperInfo.slideshowToggle();
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

                    onPressed: button => {
                        if (button == "L") {
                            WallpaperInfo.advance(1);
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

                        bindText: WallpaperInfo.slideshowInterval / 1000
                        disabled: !WallpaperInfo.slideshow

                        unit: "s"

                        autoApply: true

                        onEntered: text => {
                            if (/^\d+$/.test(text)) {
                                WallpaperInfo.slideshowInterval = text * 1000;
                                textfield.grabFocus();
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

                    onPressed: button => {
                        if (button == "L") {
                            WallpaperInfo.rescan();
                        }
                    }
                }

                CellText {
                    text: "  "
                }

                CellButton {
                    id: autoAdvance

                    property bool auto: yes && !WallpaperInfo.slideshow

                    property bool yes: SettingsInfo.wallpaperAutoAdvance

                    text: "Auto advance"

                    clickable: !WallpaperInfo.slideshow

                    color: yes && clickable ? Colors.accentStrong : Colors.bgOverlay
                    fg: clickable ? (yes ? Colors.onAccent : Colors.fgBase) : Colors.fgSubtle

                    onPressed: button => {
                        if (button == "L") {
                            SettingsInfo.toggle("wallpaperAutoAdvance");
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

                    onPressed: button => {
                        if (button == "L") {
                            if (notall) {
                                WallpaperInfo.wallpapers = WallpaperInfo.all;
                                return;
                            } else {
                                WallpaperInfo.singlify(selection.wallpapers[selection.selected]);
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

                    onPressed: button => {
                        if (button == "L") {
                            WallpaperInfo.live = !WallpaperInfo.live;
                        }
                    }
                }

                CellText {
                    text: "  "
                }

                CellButton {
                    id: more

                    text: "More"

                    color: clickable ? (root.advanced ? Colors.accentStrong : Colors.bgOverlay) : Colors.bgOverlay
                    fg: clickable ? (root.advanced ? Colors.onAccent : Colors.fgBase) : Colors.fgSubtle

                    onPressed: button => {
                        if (button == "L") {
                            root.advanced = !root.advanced;
                        }
                    }
                }
            }

            ColumnLayout {

                visible: root.advanced

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
                                            return i;
                                        }
                                    }
                                    return 0;
                                }
                                onActivated: index => {
                                    items[index]?.action();
                                }
                                items: [
                                    {
                                        label: "None",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "none");
                                            } else {
                                                WallpaperInfo.transition.type = "none";
                                            }
                                        }
                                    },
                                    {
                                        label: "Simple",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "simple");
                                            } else {
                                                WallpaperInfo.transition.type = "simple";
                                            }
                                        }
                                    },
                                    {
                                        label: "Wipe",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "wipe");
                                            } else {
                                                WallpaperInfo.transition.type = "wipe";
                                            }
                                        }
                                    },
                                    {
                                        label: "Grow",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "grow");
                                            } else {
                                                WallpaperInfo.transition.type = "grow";
                                            }
                                        }
                                    },
                                    {
                                        label: "Shrink",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "shrink");
                                            } else {
                                                WallpaperInfo.transition.type = "shrink";
                                            }
                                        }
                                    },
                                    {
                                        label: "Ripple",
                                        action: () => {
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.type", "ripple");
                                            } else {
                                                WallpaperInfo.transition.type = "ripple";
                                            }
                                        }
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
                                    h: 1

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).step

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: text => {
                                        if (/^\d+$/.test(text)) {
                                            text = Math.max(Math.min(text, 100), 1);
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.step", text);
                                            } else {
                                                WallpaperInfo.transition.step = text;
                                            }
                                            textfield.grabFocus();
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
                                    h: 1

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).duration

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: text => {
                                        if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(text)) {
                                            text = Math.max(text, 0);
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.duration", text);
                                            } else {
                                                WallpaperInfo.transition.duration = text;
                                            }
                                            textfield.grabFocus();
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
                                    h: 1

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).fps

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: text => {
                                        if (/^\d+$/.test(text)) {
                                            text = Math.max(text, 1);
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.fps", text);
                                            } else {
                                                WallpaperInfo.transition.fps = text;
                                            }
                                            textfield.grabFocus();
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {

                            visible: (WallpaperInfo.getTransition(selection.items[2]).type == "wipe" || WallpaperInfo.getTransition(selection.items[2]).type == "wave")

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
                                    h: 1

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).angle

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: text => {
                                        if (/^\d+$/.test(text)) {
                                            text = Math.max(Math.min(text, 360), 0);
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.angle", text);
                                            } else {
                                                WallpaperInfo.transition.angle = text;
                                            }
                                            textfield.grabFocus();
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {

                            visible: (WallpaperInfo.getTransition(selection.items[2]).type == "ripple" || WallpaperInfo.getTransition(selection.items[2]).type == "grow" || WallpaperInfo.getTransition(selection.items[2]).type == "shrink")

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
                                    h: 1

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).posX.toFixed(2)

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: text => {
                                        if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(text)) {
                                            text = Math.max(Math.min(parseFloat(text), 1), 0);
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.posX", text);
                                            } else {
                                                WallpaperInfo.transition.posX = text;
                                            }
                                            textfield.grabFocus();
                                        }
                                    }

                                    Keys.onPressed: event => {
                                        if (event.key == Qt.Key_Tab) {
                                            posX.unFocus();
                                            posY.grabFocus();
                                            event.accepted = true;
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
                                    h: 1

                                    bindText: WallpaperInfo.getTransition(selection.items[2]).posY.toFixed(2)

                                    autoApply: true
                                    unfocusOnEntered: true
                                    escapeToUnFocus: true

                                    onEntered: text => {
                                        if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(text)) {
                                            text = Math.max(Math.min(parseFloat(text), 1), 0);
                                            if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                                WallpaperInfo.setConfig(selection.items[2], "transition.posY", text);
                                            } else {
                                                WallpaperInfo.transition.posY = text;
                                            }
                                            textfield.grabFocus();
                                        }
                                    }

                                    onFocusChanged: {
                                        if (focus) {
                                            return;
                                        }
                                    }

                                    Keys.onPressed: event => {
                                        if (event.key == Qt.Key_Tab) {
                                            posY.unFocus();
                                            posX.grabFocus();
                                            event.accepted = true;
                                        }
                                    }
                                }
                            }

                            CellButton {

                                text: "Edit"

                                color: root.edit ? Colors.accentStrong : Colors.bgOverlay
                                fg: root.edit ? Colors.onAccent : Colors.fgBase

                                onReleased: button => {
                                    if (button == "L") {
                                        root.edit = !root.edit;
                                    }
                                }
                            }
                        }
                    }

                    CellButton {

                        text: "Bind"

                        color: WallpaperInfo.config[selection.items[2]]?.transition ? Colors.accentStrong : Colors.bgOverlay
                        fg: WallpaperInfo.config[selection.items[2]]?.transition ? Colors.onAccent : Colors.fgBase

                        onReleased: button => {
                            if (button == "L") {
                                if (WallpaperInfo.config[selection.items[2]]?.transition) {
                                    delete WallpaperInfo.config[selection.items[2]].transition;
                                    WallpaperInfo.configChanged();
                                } else {
                                    WallpaperInfo.setConfig(selection.items[2], "transition", WallpaperInfo.getTransition(""));
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
                        text: " "
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

                            onEntered: input => {
                                if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(input)) {
                                    input = Math.max(parseFloat(input), 1);
                                    WallpaperInfo.setConfig(selection.items[2], "reposition.scalar", input);

                                    textfield.grabFocus();
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

                            onEntered: input => {
                                if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(input)) {
                                    input = Math.max(Math.min(parseFloat(input), 1), -1);
                                    WallpaperInfo.setConfig(selection.items[2], "reposition.verticalOffset", input);
                                    textfield.grabFocus();
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

                            onEntered: input => {
                                if (/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(input)) {
                                    input = Math.max(Math.min(parseFloat(input), 1), -1);
                                    WallpaperInfo.setConfig(selection.items[2], "reposition.horizontalOffset", input);

                                    textfield.grabFocus();
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

                        onReleased: button => {
                            if (button == "L") {
                                root.reposition = !root.reposition;
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

                        onReleased: button => {
                            if (button == "L") {
                                scalar_textfield.unFocus();
                                vert_textfield.unFocus();
                                hori_textfield.unFocus();
                                if (WallpaperInfo.config[selection.items[2]]?.reposition) {
                                    WallpaperInfo.config[selection.items[2]].reposition.scalar = 1;
                                    WallpaperInfo.config[selection.items[2]].reposition.horizontalOffset = 0;
                                    WallpaperInfo.config[selection.items[2]].reposition.verticalOffset = 0;
                                } else {
                                    WallpaperInfo.config[selection.items[2]].reposition = {
                                        scalar: 1,
                                        verticalOffset: 0,
                                        horizontalOffset: 0
                                    };
                                }
                                WallpaperInfo.configChanged();
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

                    spacing: Cell.w(2)

                    CellText {
                        text: "Others:   "
                    }

                    CellButton {
                        text: "Recache"
                        color: [Colors.bgOverlay, Colors.fgBase]
                        fg: [Colors.fgBase, Colors.bgSurface]
                        onReleased: button => {
                            if (button == "L") {
                                WallpaperInfo.recache();
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
                bg: "transparent"
                connectStart: true
                connectEnd: true
            }

            RowLayout {

                visible: SettingsInfo.hints

                Layout.leftMargin: Cell.centerWCell(implicitWidth, parent.implicitWidth)

                spacing: Cell.w(2)

                CellKeyHint {
                    visible: textfield.text.length == 0
                    key: "←/S-Tab"
                    hint: "Back"
                }

                CellKeyHint {
                    visible: textfield.text.length == 0
                    key: "→/Tab"
                    hint: "Next"
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
                    key: "C-R"
                    hint: "Rescan"
                }

                CellKeyHint {
                    key: "C-E"
                    hint: "Advanced"
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
            }
        }
    }
}
