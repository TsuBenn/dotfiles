pragma ComponentBehavior: Bound

import qs.config
import qs.modules
import qs.services

import QtQuick.Layouts
import QtQuick

Cells {
    id: root

    optimizeMemory: SettingsInfo.optimizeMemory

    property int contentW: w - scrollbar.enabled

    // Total layout height in terminal text grid metrics
    property int contentH: itemH > 0 ? (itemH * (model ? model.length : 0)) : Cell.h(container.implicitHeight)

    property int itemH: 1

    property int padding: 0
    property int spacing: 0

    property bool snapToMax: false

    property bool reloadOnChanges: false

    property int offset: 0

    property bool atMax: false

    readonly property int maxOffset: itemH > 0 ? root.contentH - root.h : root.model.length - 1
    readonly property int itemsShown: Math.floor(root.h / itemH)

    color: "transparent"

    property var model: []
    property Component delegate

    component Type: Item {
        override property bool enabled: true
        property bool toScale: true
        property int thumbH: 0
        property int bg: 0
        property int fg: 0
        property color color: Colors.fgDim
        property color bg_color: Colors.bgOverlay
        property int arrow: 0
    }

    onMaxOffsetChanged: {
        normalize();
        if (atMax && snapToMax) {
            offset = maxOffset;
        }
        if (offset >= maxOffset) {
            atMax = true;
        } else {
            atMax = false;
        }
    }

    onOffsetChanged: {
        normalize();
        if (offset >= maxOffset) {
            atMax = true;
        } else {
            atMax = false;
        }
    }

    function reset() {
        offset = 0;
    }

    function scrollTo(index: int) {
        root.offset = index * (itemH > 0 ? itemH : 1);
    }

    function normalize() {
        root.offset = Math.max(Math.min(root.offset, maxOffset), 0);
    }

    function scrollToView(index: int) {
        if (itemH > 0)
            scrollTo(Math.floor(index / itemsShown) * itemsShown);
    }

    property Type scrollbar: Type {
        enabled: true
        toScale: root.itemH > 0 ? true : false
        thumbH: root.itemH > 0 ? 0 : 1
        bg: 1
        fg: 1
        arrow: 0
    }

    clip: true

    Loader {

        active: root.visible || !root.optimizeMemory

        // asynchronous: true

        sourceComponent: ColumnLayout {
            id: container
            spacing: 0

            // Exact horizontal dimension tracking matching your scroll width metrics
            width: Cell.w(root.contentW)

            // Sub-pixel terminal tracking alignment shifting raw offset remainders
            y: -Cell.h(Math.floor(root.offset % (root.itemH > 0 ? root.itemH : 1)))

            Repeater {
                // Allocate just enough view nodes to cover the visible grid matrix plus one buffer
                model: Math.floor(root.h / (root.itemH > 0 ? root.itemH : 1)) + 1

                delegate: Loader {
                    id: viewLoader

                    required property int index

                    // Track item alignment calculation parameters
                    readonly property int realIndex: Math.floor(root.offset / (root.itemH > 0 ? root.itemH : 1)) + index
                    readonly property var modelData: root.model[Math.min(realIndex, root.model.length - 1)]

                    visible: realIndex < root.model.length

                    sourceComponent: modelData || modelData == "" || modelData == 0 ? root.delegate : null

                    // asynchronous: true

                    // Native reactive hooks implementation
                    onLoaded: {
                        if (item) {
                            if (item.hasOwnProperty("modelData"))
                                item.modelData = Qt.binding(() => viewLoader.modelData ?? null);

                            // FIXED: Re-mapped index targets to pass true array positioning (realIndex)
                            if (item.hasOwnProperty("index"))
                                item.index = Qt.binding(() => viewLoader.realIndex ?? -1);
                        }
                    }

                    Connections {
                        target: root
                        function onModelChanged() {
                            if (!root.reloadOnChanges)
                                return;
                            viewLoader.sourceComponent = null;
                            viewLoader.sourceComponent = Qt.binding(() => viewLoader.modelData || viewLoader.modelData == "" || viewLoader.modelData == 0 ? root.delegate : null);
                        }
                    }
                }
            }
        }
    }

    Loader {
        active: root.visible || !root.optimizeMemory

        sourceComponent: CellScrollBar {
            z: 2
            visible: root.scrollbar.enabled
            x: Cell.alignRightWCell(implicitWidth, root.implicitWidth)

            onAdjusted: percent => {
                root.offset = Math.max(0, Math.min(Math.floor((root.maxOffset) * percent), root.maxOffset));
            }

            type {
                bg: root.scrollbar.bg
                fg: root.scrollbar.fg
                arrow: root.scrollbar.arrow
            }

            toScale: root.scrollbar.toScale
            thumbH: root.scrollbar.thumbH

            h: root.h
            progress: root.maxOffset > 0 ? root.offset / root.maxOffset : 0
            contentH: root.contentH

            bg: root.scrollbar.bg_color
            color: root.scrollbar.color
        }
    }

    MouseControl {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: false

        onWheel: delta => {
            root.offset = Math.max(Math.min(root.offset - delta, root.maxOffset), 0);
        }
    }
}
