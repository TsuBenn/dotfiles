pragma ComponentBehavior: Bound

import qs.config
import qs.services
import qs.modules

import Quickshell
import QtQuick
import QtQuick.Window

// DISCLAIMER: It's best not to programmically change "w" or "h"

FloatingWindow {
    id: root

    visible: FloatsManager.isOpen(name)

    property bool isFloat: true

    property var workspace: toplevel?.workspace
    property var toplevel: HyprInfo.getClient(address)

    property bool isMaximized: toplevel?.wayland.maximized ?? false

    onIsMaximizedChanged: {
        if (!noMax && toplevel) {
            unMaximize();
        }
    }

    // Connections {
    //     target: SettingsInfo
    //     function onDebugSig() {
    //         root.toggleFullscreen();
    //     }
    // }

    function unMaximize() {
        HyprInfo.unMaximizeClient(address);
    }

    function setMaximize() {
        HyprInfo.maximizeClient(address);
    }

    function toggleMaximize() {
        HyprInfo.maximizeClient(address, true);
    }

    function setFullscreen() {
        HyprInfo.fullscreenClient(address);
    }

    function toggleFullscreen() {
        HyprInfo.fullscreenClient(address, true);
    }

    onClosed: {
        TextFieldManager.unFocusAll();
        root.close();
    }

    Connections {
        target: FloatsManager
        function onSigClose(name) {
            if (root.name == name) {
                root.close();
            }
        }
        function onSigOpen(name) {
            if (root.name == name && root.visible) {
                if (SettingsInfo.moveFloatOnFocus)
                    HyprInfo.moveClient(root.toplevel, HyprInfo.focusedWorkspace);
                else
                    HyprInfo.focusClient(root.toplevel);
            }
            root.onSigOpen();
        }
    }

    onVisibleChanged: {
        if (!visible) {} else {
            if (initW > 0 || initH > 0) {
                w = initW;
                h = initH;
                maximumSize = Qt.size(Cell.w(initW + 1), Cell.h(initH + 1));
                minimumSize = Qt.size(Cell.w(initW + 1), Cell.h(initH + 1));
            }
            init.restart();
        }
    }

    onHChanged: reload()
    onWChanged: reload()

    property bool reloading: false

    function reload() {
        if (visible && maximumSize == minimumSize) {
            reloading = true;
            FloatsManager.close(root.name);
            FloatsManager.open(root.name);
        }
    }

    function onSigOpen() {
    }

    function init() {
    }

    Timer {
        id: init
        interval: 200
        onTriggered: {
            root.maximumSize = Qt.binding(() => root._maximum);
            root.minimumSize = Qt.binding(() => root._minimum);
            root.init();
            root.reloading = false;
        }
    }

    function close() {
        onSigClose();
        forceClose();
    }

    function onSigClose() {
    }

    function forceClose() {
        FloatsManager.close(name);
    }

    function open() {
        FloatsManager.open(name);
    }

    property string name

    title: root.name.slice(0, 1).toUpperCase() + root.name.slice(1).toLowerCase() // Automatically set the title if not manually set

    property int initW: 0
    property int initH: 0

    property int w: 20
    property int h: 10

    implicitWidth: Cell.w(w + 1)
    implicitHeight: Cell.h(h + 1)

    property bool showSize: false

    signal sizeChanged

    property string address: "0x" + HyprInfo.matchClient("org.quickshell", root.title)?.address ?? "" // For quick access via Hyprland

    function setSize(w, h) {
        HyprInfo.resizeClient(Cell.w(w + 1), Cell.h(h + 1), address);
    }

    signal sizeSynced

    Timer {
        id: syncSize
        interval: 200
        onTriggered: {
            if (root.maxH > 0 || root.minH > 0) {
                root.h = Cell.hCount(root.height) - 1;
            }
            if (root.maxW > 0 || root.minW > 0) {
                root.w = Cell.wCount(root.width) - 1;
            }
            root.sizeSynced();
            // console.log(root.implicitWidth + " " + root.implicitHeight);
        }
    }

    onSizeChanged: {
        // root.setSize(root.w, root.h);
        if (showSize)
            show_size.restart();
        syncSize.restart();
    }

    onHeightChanged: sizeChanged()
    onWidthChanged: sizeChanged()
    // onImplicitHeightChanged: sizeChanged()
    // onImplicitWidthChanged: sizeChanged()

    property bool noMax: false
    property bool noMin: false

    property size _maximum: noMax ? Qt.size(16777215, 16777215) : (Qt.size(maxW > 0 ? Cell.w(maxW) : Cell.w(w + 1), maxH > 0 ? Cell.h(maxH) : Cell.h(h + 1)))
    property size _minimum: noMin ? Qt.size(0, 0) : (Qt.size(minW > 0 ? Cell.w(minW) : Cell.w(w + 1), minH > 0 ? Cell.h(minH) : Cell.h(h + 1)))

    maximumSize: _maximum
    minimumSize: _minimum

    // Setting custom max/min size would break the "w" and "h" bindings
    property int maxW: 0
    property int maxH: 0

    property int minW: 0
    property int minH: 0

    property var shortcuts: []

    // ShortcutHandler {
    //     shortcuts: root.shortcuts
    // }

    color: Colors.bgSurface

    default property alias content: cell.data

    property bool _faultySize: !((root.minW == 0 || root.w + 1 >= root.minW) && (root.maxW == 0 || root.w + 1 <= root.maxW) && (root.minH == 0 || root.h + 1 >= root.minH) && (root.maxH == 0 || root.h + 1 <= root.maxH))

    Cells {
        id: cell
        visible: root.visible && !root._faultySize

        w: root.w
        h: root.h

        x: Cell.w(0.5)
        y: Cell.h(0.5)

        color: root.color

        focus: !TextFieldManager.active && root.visible && Window.window.active

        Keys.priority: Keys.BeforeItem

        Keys.onPressed: event => {
            if (root.shortcuts.length > 0) {
                ShortcutInfo.handleShortcuts(event, root.shortcuts);
            }
        }
    }

    Cells {
        id: size

        SequentialAnimation {
            id: show_size
            NumberAnimation {
                target: size
                property: "prefered_opacity"
                duration: 100
                to: 1
                easing.type: Easing.OutCubic
            }
            PauseAnimation {
                duration: 400
            }
            NumberAnimation {
                target: size
                property: "prefered_opacity"
                duration: 200
                to: 0
                easing.type: Easing.OutCubic
            }
        }

        w: Cell.wCount(root.width)
        h: Cell.hCount(root.height)

        color: Colors.transparent(Colors.bgBase, 0.5)

        property real prefered_opacity: 0

        opacity: root._faultySize ? 1 : prefered_opacity

        CellText {
            x: Cell.centerWCell(implicitWidth, parent.implicitWidth)
            y: Cell.centerHCell(implicitHeight, parent.implicitHeight)
            text: root._faultySize ? ` Unavailable size ` : ` ${root.w + 1} x ${root.h + 1}`
            bg: Colors.bgSurface
            centered: true
        }
    }
}
